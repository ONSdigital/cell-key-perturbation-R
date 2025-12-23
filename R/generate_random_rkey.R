
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
#' @return A data.table with a new integer column `record_key` (values in 0-255)
#'
#' @export
#'
#' @examples
#' data <- data.table(id = 1:1000)
#' generate_random_rkey(data)
generate_random_rkey <- function(data, rkey_range = 255) {
  dt <- copy(data)

  set.seed(2025)

  dt[, record_key := sample(0:rkey_range, .N, replace = TRUE)]

  return(dt)
}
