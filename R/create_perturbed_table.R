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

  # Rename record_key in case 'record_key' is a column name in the data
  record_key_arg <- record_key

  # Input checks ===============================================================
  # 1. Type validation on input data & ptable
  # 2. Check that at least one variable specified for geog or tab_vars
  # 3. Check variable is specified for record_key
  # 4. Check geog, tab_vars & record_key specified are columns in data
  # 5. Check ptable contains required columns
  # 6. Check threshold is an integer
  # ----------------------------------------------------------------------------
  if (!is.data.table(data)) {
    stop("Specified value for data must be a data.table.")
  }
  if (!is.data.table(ptable)) {
    stop("Specified value for ptable must be a data.table.")
  }
  if (!is.character(record_key_arg) | length(record_key_arg)>1) {
    stop("Specified value for record_key must be a string.")
  }
  if (length(geog)==0 & length(tab_vars)==0)  {
    stop("No variables for tabulation. Specify value for geog or tab_vars.")
  }
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
    stop("Specified value for record_key must be a column name in data.")
  }
  msg <- "Supplied ptable must contain columns named 'pcv','ckey' and 'pvalue'."
  if (!all(c("pcv","ckey","pvalue") %in% colnames(ptable))){
    stop(msg)
  }
  if ((!is.numeric(threshold) | !(round(threshold)==threshold))){
    stop("Specified value for threshold must be an integer")
  }
  if (threshold <0){
    warning("Specified value for threshold is negative, meaning no threshold will be applied.")
  }
  # ----------------------------------------------------------------------------
  # Check data has sufficient % records with record keys to apply perturbation
  rkey_na_count <- sum(is.na(data[,get(record_key_arg)]))
  rkey_percent <- 100*(1 - rkey_na_count/nrow(data))

  if (rkey_percent < 50){
    message_string <- "Less than 50% of records have a record key.
    Cell key perturbation will be much less effective with fewer record keys,
    so this code requires at least 50% of records to have a record key."
    stop(message_string)
  }
  else if (rkey_percent < 100){
    if (rkey_percent < 99.94){
      warning_string1 <- paste("Only",round(rkey_percent,1),
                              "% of records have a record key.")
    }
    if (rkey_na_count == 1){
      warning_string2 <- "There is 1 record with a missing record key."
    }
    else {
      warning_string2 <- paste("There are",rkey_na_count,
                                "records with missing record keys.")
    }
    warning(cat(warning_string1,warning_string2))
  }
  # ----------------------------------------------------------------------------
  #Check range of ckeys used in the ptable matches range in the data
  max_ckey<-max(ptable$ckey)
  max_rkey<-max(data[,get(record_key_arg)], na.rm = TRUE)
  msg <- paste(
    "The maximum record key is",max_rkey,", whereas the maximum cell key is ",
    max_ckey,"Please check you are using the appropriate ptable for this data.")
  if (max_ckey != max_rkey){
    warning(msg)
  }
  # ============================================================================


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
