#' Create a frequency table with cell key perturbation applied
#'
#' 'create_perturbed_table()' creates a frequency table which has had
#'  cell key perturbation applied to the counts.
#'  A p-table file needs to be supplied which determines which cells are
#'  perturbed.
#'  The data needs to contain a 'record key' variable which along with the
#'  ptable allows the process to be repeatable and consistent.
#'
#' @param data A data.table containing the data to be tabulated and
#' perturbed
#' @param geog A string vector giving the column name in 'data' that
#' contains the desired geography level for the frequency table. This can be
#' the empty vector, c(), if no geography level is required.
#' @param tab_vars A string vector giving the column names in 'data' of
#' the variables to be tabulated.
#' @param record_key_arg A String containing the column name in 'data'
#' giving the record keys required for perturbation.
#' @param ptable A data.table containing the 'ptable' file which determines
#' when perturbation is applied.
#'
#' @return Returns a data.table giving a frequency table which has had cell key
#' perturbation applied according to the ptable supplied.
#'
#' @import data.table
#'
#' @examples
#' geog <- c("var1")
#' tab_vars <- c("var5","var8")
#' record_key <-"record_key"
#'
#' perturbed_table <-
#'  create_perturbed_table(micro, geog, tab_vars, record_key, ptable_10_5)
#'
#' perturbed_table <-create_perturbed_table(data = micro,
#'                                          record_key_arg = "record_key",
#'                                          geog = c(),
#'                                          tab_vars = c("var1","var5","var8"),
#'                                          ptable = ptable_10_5)
#'
#' @export
create_perturbed_table <- function(data,geog,tab_vars,record_key_arg,ptable)
{

  # Type validation on input data & ptable
  if (!is.data.table(data)) {
    stop("Specified value for data must be a data.table.")
  }
  if (!is.data.table(ptable)) {
    stop("Specified value for ptable must be a data.table.")
  }

  # Check that at least one variable specified for geog or tab_vars
  if (length(geog)==0 & length(tab_vars)==0)  {
    stop("No variables for tabulation. Specify value for geog or tab_vars.")
  }

  # Check that variable specified for record_key_arg
  if (length(record_key_arg)==0)  {
    stop("Please specify a value for record_key_arg.")
  }

  # Check geog, tab_vars & record_key_arg specified are contained within data
  if (length(geog)>0){
    if (!(geog %in% colnames(data))){
      stop("Specified value for geog must be a column name in data.")
    }
  }
  if (length(tab_vars)>0){
    if (!all(tab_vars %in% colnames(data))){
      stop("Specified values for tab_vars must be column names in data.")
    }
  }
  if (!(record_key_arg %in% colnames(data))){
    stop("Specified value for record_key_arg must be a column name in data.")
  }

  # Check ptable has correct format
  msg <- "Supplied ptable must contain columns named 'pcv','ckey' and 'pvalue'"
  if (!all(c("pcv","ckey","pvalue") %in% colnames(ptable))){
    stop(msg)
  }

  # Bind variables locally to function to prevent
  # 'No visible binding for global variable' during build check
  pre_sdc_count <- pcv <- count <- pvalue <- ckey <- NULL

  #drop unnecessary columns
  data <- data[,c(geog,tab_vars,record_key_arg),with=FALSE]

  #convert every column to factor, except record_key
  cols <- colnames(data)[!(colnames(data) %in% record_key_arg)]
  data[,(cols):=lapply(.SD,as.factor),.SDcols=cols]

  #tabulate - using 'table' function to get zero cells
  aggregated_table <- as.data.table(table(data[,c(geog,tab_vars),
                                               with=FALSE]))
  colnames(aggregated_table)[colnames(aggregated_table) == "N"] <-
    "pre_sdc_count"

  # Fix: If only 1 variable specified, column is named V1.
  # Rename to original column name to prevent later merge failing.
  if (length(cols) == 1) {
    colnames(aggregated_table)[colnames(aggregated_table) == "V1"] <- cols
  }

  #adjust for using cellkeys of 256 or other (e.g. 4095)
  max_ckey<-max(ptable$ckey)
  #checking range of ckeys used in the ptable matches range in the data
  max_rkey<-max(data[,get(record_key_arg)])
  msg <- paste0(
    "The .", '\n',
    "The maximum record key is ", max_rkey,
    ", whereas the maximum cell key is ", max_ckey, '\n',
    "Please check you are using the appropriate ptable for this data.")
  if(max_ckey!=max_rkey){
    warning(msg)
  }

  #calculate cell keys
  cellkeys<-setDT(data)[,list(ckey = sum(get(record_key_arg))%%(max_ckey+1)),
                        keyby = c(geog,tab_vars)]
  aggregated_table<-merge(aggregated_table,cellkeys,by=c(geog,tab_vars),
                          all.x=TRUE)

  #calculate pcv
  aggregated_table$pcv <-
    as.integer(((aggregated_table$pre_sdc_count-1)%%250)+501)
  setDT(aggregated_table)[pre_sdc_count<=750, pcv:=pre_sdc_count,]

  #merge on ptable
  aggregated_table<-merge(aggregated_table,ptable,by=c("ckey","pcv"),
                          sort=FALSE,all.x=TRUE)
  setDT(aggregated_table)[,count:=pre_sdc_count+pvalue,]

  #replacing NAs in cellkey for zero cells
  aggregated_table[pre_sdc_count==0,ckey:=0]

  #setting pvalue to be zero for zero cells
  aggregated_table[pre_sdc_count==0,pvalue:=0]

  #setting count to be zero for zero cells
  aggregated_table[pre_sdc_count==0,count:=0]

  return(aggregated_table)
}



