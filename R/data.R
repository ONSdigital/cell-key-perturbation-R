#' Perturbation table
#'
#'  A data set containing the rules to apply cell key perturbation with a
#'  threshold of 10, and rounding to base 5. In other words, counts less than
#'  10 will be removed, and all others will be rounded to the nearest 5.
#'
#' \itemize{
#'   \item pcv. perturbation cell value (1-750)
#'   \item ckey. cell key value (0-255)
#'   \item pvalue. perturbation value to be applied
#' }
#'
#' @docType data
#' @keywords datasets
#' @name ptable_10_5
#' @usage data(ptable_10_5)
#' @format A data.table containing 192000 observations of 3 variables
"ptable_10_5"


#' Example data (micro)
#'
#'  A data set containing randomly generated data to showcase the cell key
#'  perturbation method.
#'
#' \itemize{
#'   \item record_key. record key value (0-255)
#'   \item var1. example variable 1 (1-5)
#'   \item var2. example variable 2 (1,2)
#'   \item var3. example variable 3 (1-4)
#'   \item var4. example variable 4 (1-4)
#'   \item var5. example variable 5 (1-10)
#'   \item var6. example variable 6 (1-5)
#'   \item var7. example variable 7 (1-5)
#'   \item var8. example variable 8 (A-D)
#'   \item var9. example variable 9 (A-H)
#'   \item var10. example variable 10 (1-49)
#' }
#'
#' @docType data
#' @keywords datasets
#' @name micro
#' @usage data(micro)
#' @format A data.table containing 1000 observations of 11 variables
"micro"
