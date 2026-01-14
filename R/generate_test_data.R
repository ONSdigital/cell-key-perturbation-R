#' Generate sample microdata
#'
#' @description
#' `generate_test_data()` creates a sample microdata containing randomly
#'  generated microdata columns and record keys for testing purposes.
#'
#' Note: A seed is set for random value generator to obtain same output in
#'  different runs. However, the sample microdata included in the package will
#'  be different than this one, as it was generated from the corresponding
#'  python package for consistency in test output.
#'
#' @import data.table
#'
#' @param size Number of rows in the sample microdata. Default is 1000.
#' @param rkey_range The max range for record keys. Default is 255.
#'
#' @return A data.table containing randomly generated microdata and record keys
#' @export
#'
#' @examples
#' data <- generate_test_data(size = 1000)
#' data <- generate_test_data(size = 1000, rkey_range = 255)
generate_test_data <- function(size = 1000, rkey_range = 255) {
  set.seed(111)

  record_key_sample <- sample(0:rkey_range, size, replace = TRUE)

  var1 <- sample(
    x = 1:5,
    size = size,
    replace = TRUE,
    prob = c(0.25, 0.35, 0.20, 0.10, 0.10)
  )

  var2 <- sample(
    x = 1:2,
    size = size,
    replace = TRUE,
    prob = c(0.5, 0.5)
  )

  var3 <- sample(
    x = 1:4,
    size = size,
    replace = TRUE,
    prob = c(0.25, 0.35, 0.20, 0.20)
  )

  var4 <- sample(
    x = 1:4,
    size = size,
    replace = TRUE,
    prob = c(0.25, 0.35, 0.20, 0.20)
  )

  var5 <- sample(
    x = 1:10,
    size = size,
    replace = TRUE,
    prob = c(0.20, 0.15, 0.08, 0.15, 0.02, 0.025, 0.075, 0.10, 0.10, 0.10)
  )

  var6 <- sample(
    x = 1:5,
    size = size,
    replace = TRUE,
    prob = c(0.25, 0.35, 0.20, 0.10, 0.10)
  )

  var7 <- sample(
    x = 1:5,
    size = size,
    replace = TRUE,
    prob = c(0.25, 0.35, 0.20, 0.10, 0.10)
  )

  categories_ABCD <- c("A", "B", "C", "D")
  var8 <- sample(categories_ABCD, size = size, replace = TRUE)

  categories_ABCDEFGH <- c("A", "B", "C", "D", "E", "F", "G", "H")
  var9 <- sample(categories_ABCDEFGH, size = size, replace = TRUE)

  var10 <- sample(1:49, size, replace = TRUE)

  DT <- data.table(
    record_key = record_key_sample,
    var1 = var1,
    var2 = var2,
    var3 = var3,
    var4 = var4,
    var5 = var5,
    var6 = var6,
    var7 = var7,
    var8 = var8,
    var9 = var9,
    var10 = var10
  )

  return(DT)
}

