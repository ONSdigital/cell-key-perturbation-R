#' Check perturbed table for missingness in tabulation variables
#'
#' @param DT -- `data.table`
#'  Perturbed frequency table
#' @param cols -- `character vector`
#'  Tabulation variables
#'
#' @returns Warning message if any tabulation variable contain missing values
#'
#' @import data.table
#'
check_for_na <- function(DT, cols) {
  na_cols <- DT[, names(.SD)[sapply(.SD, function(x) any(is.na(x)))],
                .SDcols = cols]

  if (length(na_cols) > 0) {
    warning(sprintf("Missing values detected in the following variable(s): %s
      Consider removing frequencies for missing values from the output table.",
      paste(na_cols, collapse = ", ")),
      call. = FALSE)
  }
}
