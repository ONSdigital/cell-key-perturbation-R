#' Generate Record Key from ONS ID
#'
#' This function creates a new record key column by taking the modulo 4096 of
#' the `ons_id` column. It converts `ons_id` to numeric, preserving `NA` for
#' non-numeric values, and assigns the result as an integer.
#'
#' @param data A `data.table` containing the `ons_id` column.
#' @param record_key_col A character string specifying the name of the new
#'   record key column to create.
#'
#' @return A `data.table` with the new record key column added.
#'
#' @details
#' - The function checks that `data` is a `data.table`.
#' - Non-numeric values in `ons_id` are converted to `NA`.
#' - The record key is computed as `ons_id %% 4096` and stored as integer.
#'
#' @import data.table
#'
generate_record_key_from_ons_id <- function(data, record_key_col) {

  if (!data.table::is.data.table(data)) {
    stop("data must be a data.table")
  }

  df <- data.table::copy(data)

  df[, (record_key_col) := as.integer(as.numeric(get("ons_id")) %% 4096L)]

  return(df)
}


#' Generate and attach random record keys to microdata
#'
#' @description
#' `generate_random_key()` attaches randomly generated record keys to microdata
#'  tables for testing purposes.
#'
#' @import data.table
#'
#' @param data A data.table or data.frame containing the microdata
#' @param rkey_range The max range for record keys. Default is 255.
#'
#' @return A data.table with a new integer column `record_key`
#'
#' @export
#'
#' @examples
#' library(data.table)
#' data <- data.table(id = 1:1000)
#' generate_random_rkey(data)
generate_random_rkey <- function(data, rkey_range = 255) {
  dt <- copy(data)

  set.seed(2025)

  dt[, ("record_key") := sample(0:rkey_range, .N, replace = TRUE)]

  return(dt)
}
