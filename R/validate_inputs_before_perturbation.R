
#' Validate Inputs Before Perturbation
#'
#' @description
#' Validates inputs for a perturbation process.
#'
#' * Validate type of input data & ptable
#' * Validate other input arguments
#'   * Check that at least one variable specified for geog or tab_vars
#'   * Check variable is specified for record_key as a string
#'   * Check threshold is an integer and non-negative
#' * Validate microdata and ptable contain required columns
#'   * Check data contain the specified geog, tab_vars & record_key
#'   * Check ptable contains required columns
#' * Validate the range of record keys and cell keys
#' * Validate data has sufficient % records with record keys to apply perturbation
#'
#' @import data.table
#'
#' @inheritParams create_perturbed_table
#'
#' @return Stop or Warning messages if any validation fails.
#' @export
#'
#' @examples
#' validate_inputs(data = micro,
#'                 ptable = ptable_10_5,
#'                 record_key = "record_key",
#'                 geog = c("var1"),
#'                 tab_vars = c("var5","var8"),
#'                 threshold = 10)
validate_inputs <- function(
    data,
    ptable,
    geog,
    tab_vars,
    record_key,
    threshold)
{
  record_key_arg <- record_key

  check_input_data_types(data, ptable)

  check_input_arguments(geog, tab_vars, record_key_arg, threshold)

  check_data_contain_columns(data, geog, tab_vars, record_key_arg)
  check_ptable_contain_columns(ptable)

  # Check if the range of record keys and cell keys match
  min_ckey <- min(ptable$ckey)
  max_ckey <- max(ptable$ckey)
  min_rkey <- min(data[[record_key_arg]], na.rm = TRUE)
  max_rkey <- max(data[[record_key_arg]], na.rm = TRUE)

  check_key_range(min_ckey, max_ckey, min_rkey, max_rkey)

  # Check data has sufficient % records with record keys to apply perturbation
  rkey_na_count <- sum(is.na(data[,get(record_key_arg)]))
  rkey_percent <- 100*(1 - rkey_na_count/nrow(data))

  check_missing_record_key(rkey_na_count, rkey_percent)
}



## Helper functions

check_input_data_types <- function(data, ptable)
{
  if (!is.data.table(data)) {
    stop("Specified value for data must be a data.table.")
  }
  if (!is.data.table(ptable)) {
    stop("Specified value for ptable must be a data.table.")
  }
}


check_input_arguments <- function(geog, tab_vars, record_key_arg, threshold)
{
  if (length(geog)==0 & length(tab_vars)==0)  {
    stop("No variables for tabulation. Specify value for geog or tab_vars.")
  }
  if (length(record_key_arg)==0)  {
    stop("Please specify a value for record_key.")
  }
  if (!is.character(record_key_arg) | length(record_key_arg)>1) {
    stop("Specified value for record_key must be a string.")
  }
  if ((!is.numeric(threshold) | !(round(threshold)==threshold))){
    stop("Specified value for threshold must be an integer")
  }
  if (threshold <0){
    warning("Specified value for threshold is negative,
            meaning no threshold will be applied.")
  }
}


check_data_contain_columns <- function(data, geog, tab_vars, record_key_arg)
{
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
}


check_ptable_contain_columns <- function(ptable)
{
  msg <- "Supplied ptable must contain columns named 'pcv','ckey' and 'pvalue'."
  if (!all(c("pcv","ckey","pvalue") %in% colnames(ptable))){
    stop(msg)
  }
}


check_key_range <- function(min_ckey, max_ckey, min_rkey, max_rkey)
{
  if (max_ckey != max_rkey){
    warning(paste("Record key and cell key ranges are different.",
                  "The maximum record key is",max_rkey,
                  ", whereas the maximum cell key is",max_ckey,
                  ". Please check you are using the appropriate ptable for this
                  data."))
  }
  if (min_ckey < 0){
    warning("Negative cell key found in ptable!")
  }
  if (min_rkey < 0){
    warning("Negative record key found in data!")
  }
}


check_missing_record_key <- function(rkey_na_count, rkey_percent)
{
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
}




