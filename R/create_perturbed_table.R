#' Create a frequency table with cell key perturbation applied
#'
#' 'create_perturbed_table()' creates a frequency table which has had
#'  cell key perturbation applied to the counts.
#'  A p-table file needs to be supplied which determines which cells are
#'  perturbed.
#'  The data needs to contain a 'record key' variable which along with the
#'  ptable allows the process to be repeatable and consistent.
#'
#' @param data A data.table containing the data to be tabulated and perturbed
#' @param geog A string vector giving the column name in 'data' that contains
#' the desired geography level for the frequency table. This can be the empty
#' vector, c(), if no geography level is required.
#' @param tab_vars A string vector giving the column names in 'data' of the
#' variables to be tabulated. This can be the empty vector, c(), provided
#' a geography level is supplied.
#' @param record_key A String containing the column name in 'data' giving
#' the record keys required for perturbation.
#' @param ptable A data.table containing the 'ptable' file which determines
#' when perturbation is applied.
#' @param threshold An integer specifying the value below which counts are
#' suppressed, with a default value of 10.
#'
#' @return Returns a data.table giving a frequency table which has had
#' cell key perturbation applied according to the ptable supplied.
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
#'                                          record_key = "record_key",
#'                                          geog = c(),
#'                                          tab_vars = c("var1","var5","var8"),
#'                                          ptable = ptable_10_5,
#'                                          threshold = 10)
#'
#' @export
create_perturbed_table <- function(
    data,
    geog,
    tab_vars,
    record_key,
    ptable,
    threshold = 10)
{
  # Step 0: Validate Inputs
  validate_inputs(data, ptable, geog, tab_vars, record_key, threshold)

  # ============================================================================
  # Rename record_key in case 'record_key' is a column name in the data
  record_key_arg <- record_key

  # Bind variables locally to function to prevent
  # 'No visible binding for global variable' during build check
  pre_sdc_count <- pcv <- count <- pvalue <- ckey <- NULL

  #drop unnecessary columns
  data <- data[,c(geog,tab_vars,record_key_arg),with=FALSE]

  #convert every column to factor, except record_key
  cols <- colnames(data)[!(colnames(data) %in% record_key_arg)]
  data[,(cols):=lapply(.SD,as.factor),.SDcols=cols]

  #tabulate - using 'table' function to get zero cells
  aggregated_table <- as.data.table(table(data[,c(geog,tab_vars), with=FALSE]))
  colnames(aggregated_table)[colnames(aggregated_table) == "N"] <-
    "pre_sdc_count"

  # Fix implemented: If only 1 variable specified, column is named V1.
  # Rename to original column name to prevent later merge failing.
  if (length(cols) == 1) {
    colnames(aggregated_table)[colnames(aggregated_table) == "V1"] <- cols
  }

  #calculate cell keys
  max_ckey <- max(ptable$ckey)
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

  #setting count to be missing if less than threshold
  aggregated_table[count<threshold,count:=NaN]

  return(aggregated_table)
}
