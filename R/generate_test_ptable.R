#' Generate ptable (10-5 rule)
#'
#' `generate_ptable_10_5_rule()` generates a sample p-table based on 10-5 rule,
#'  which means a suppression threshold of 10 and rounding to the nearest 5.
#'
#' @param max_pcv  Max value for pcv. Default is 750.
#' @param ckey_range The max range for cell keys. Default is 255.
#'
#' @return A data.table assigning a pvalue to each ckey and pcv combination
#'
#' @examples
#' ptable <- generate_ptable_10_5_rule()
#'
#' @import data.table
#'
#' @export
generate_ptable_10_5_rule <- function(max_pcv = 750, ckey_range = 255) {
  DT <- CJ(pcv = 1:max_pcv, ckey = 0:ckey_range, unique = TRUE)

  pval <- as.integer(calculate_pvalue(DT[["pcv"]]))
  set(DT, j = "pvalue", value = pval)

  setkeyv(DT, c("pcv", "ckey"))
  return(DT)
}

#' Calculate pvalue for each pcv based on 10-5 rule
#'
#' @param pcv Perturbation cell value
#'
#' @return Perturbation value, i.e. noise added to cells
#'
#' @noRd
#'
calculate_pvalue <- function(pcv) {
  ifelse(
    pcv < 10,
    -pcv,
    c(`0` = 0, `1` = -1, `2` = -2, `3` = 2, `4` = 1)[as.character(pcv %% 5)]
  )
}
