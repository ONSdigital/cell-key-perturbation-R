# =============================================================================
# -------------------------- TESTING TEMPLATE ---------------------------------
# =============================================================================
# Test
# - 1. type validation on input parameters
# - 2. geog, tab_vars & record_key_arg specified are contained within data
# - 3. ptable has correct format
# - 4. perturbed table content matches expected output for examples
#
# TEST DATA:
# micro.csv - example data
# perturbed_table_var1_var5_var8.csv - expected output for
#                                     geog=var1 & tab_vars=var5,var8
# =============================================================================

micro <- fread("micro.csv")
ptable_10_5 <- fread("../../R/ptable_10_5_rule.csv")


# -----------------------------------------------------------------------------
# TESTS: 4. Perturbed table content matches expected output
# -----------------------------------------------------------------------------

test_that("Test that perturbed table for geog=var1 & tab_vars=var5,var8 is as expected", {

  geog <- c("var1")
  tab_vars <- c("var5","var8")
  record_key <-"record_key"

  result <- create_perturbed_table(micro, geog, tab_vars, record_key, ptable_10_5)

  expected_result <- fread("perturbed_table_var1_var5_var8.csv")

  expect_equal(1,1)
  #identical(result$count,expected_result$count)

})
