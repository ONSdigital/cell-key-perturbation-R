# =============================================================================
# -------------------------- TESTING TEMPLATE ---------------------------------
# =============================================================================
# Test
# - 1. type validation on input data & ptable
# - 2. variables have been supplied for tabulation
# - 3. record_key_arg has been specified
# - 4. geog, tab_vars & record_key_arg specified are contained within data
# - 5. ptable has correct format
# - 6. perturbed table content matches expected output for specific example
# - 7. function works when only 1 grouping variable is specified
#
# TEST DATA:
# perturbed_table_var1_var5_var8.rds - expected output for perturbation on
#                                      micro data using ptable_10_5,
#                                      geog=var1 & tab_vars=var5,var8
# =============================================================================

# -----------------------------------------------------------------------------
# TESTS:1. Check type validation on input data & ptable
# -----------------------------------------------------------------------------

test_that("error raised if input data NOT a data.table", {
  expect_error(create_perturbed_table(data = "not_a_data_table",
                                      geog = c("var1"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5),
        "Specified value for data must be a data.table", fixed = TRUE)
})

test_that("error raised if ptable supplied NOT a data.table", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("var1"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = "record_key",
                                      ptable = "not_a_data_table"),
        "Specified value for ptable must be a data.table", fixed = TRUE)
})

# -----------------------------------------------------------------------------
# TESTS:2. Check error raised if geog & tab_vars are both NULL or empty vectors
# -----------------------------------------------------------------------------

test_that("error raised if geog & tab_vars are both NULL.", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = NULL,
                                      tab_vars = NULL,
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5),
  "No variables for tabulation. Specify value for geog or tab_vars.",
  fixed = TRUE)
})

test_that("error raised if both geog & tab_vars are empty.", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c(),
                                      tab_vars = c(),
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5),
  "No variables for tabulation. Specify value for geog or tab_vars.",
  fixed = TRUE)
})

# -----------------------------------------------------------------------------
# TESTS:3 Check Check error raised if record_key_arg not specified
# -----------------------------------------------------------------------------

test_that("error raised if record_key_arg not specified", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("var1"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = NULL,
                                      ptable = ptable_10_5),
               "Please specify a value for record_key_arg.",
               fixed = TRUE)
})

# -----------------------------------------------------------------------------
# TESTS:4 Check errors raised if geog, tab_vars & record_key_arg not within data
# -----------------------------------------------------------------------------

test_that("error raised if geog not a column within data", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("not_col_in_data"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5),
        "Specified value for geog must be a column name in data.",
        fixed = TRUE)
})

test_that("error raised if tab_vars not columns within data", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("var1"),
                                      tab_vars = c("not_col_in_data","var8"),
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5),
        "Specified values for tab_vars must be column names in data.",
        fixed = TRUE)
})

test_that("error raised if record_key_arg not a column within data", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("var1"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = "not_record_key",
                                      ptable = ptable_10_5),
          "Specified value for record_key_arg must be a column name in data.",
          fixed = TRUE)
})

# -----------------------------------------------------------------------------
# TESTS: 5. Check errors raised if ptable has incorrect format
# -----------------------------------------------------------------------------

dodgy_ptable <- data.table(
  pcv = 1:5,
  ckey = 6:10,
  zvalue = 11:15
)

test_that("error raised if ptable does not contain required column names", {
  expect_error(create_perturbed_table(data = micro,
                                      geog = c("var1"),
                                      tab_vars = c("var5","var8"),
                                      record_key_arg = "record_key",
                                      ptable = dodgy_ptable),
        "Supplied ptable must contain columns named 'pcv','ckey' and 'pvalue'",
        fixed = TRUE)
})

# -----------------------------------------------------------------------------
# TESTS: 6. Check warning given if max record key in data and max cell key
#           in ptable are different
# -----------------------------------------------------------------------------

# Create dataset with record_key up to 254 (ptable_10_5 has max value of
# cell key as 255)
dodgy_data <- data.table(
  record_key = 0:254,
  var1 = 1:255,
  var2 = 11:265
)

test_that("warning if max record key and max cell key are different", {
  expect_warning(create_perturbed_table(data = dodgy_data,
                                      geog = c("var1"),
                                      tab_vars = c("var2"),
                                      record_key_arg = "record_key",
                                      ptable = ptable_10_5))
})


# -----------------------------------------------------------------------------
# TESTS: 6. Check perturbed table content matches expected output
# -----------------------------------------------------------------------------

# Create perturbed table for micro data using geog=var1 & tab_vars=var5,var8
# which includes zero count combinations but should return a table with all
# combinations i.e. 200 rows
test_that("Perturbed table includes zero count combinations", {

  result <- create_perturbed_table(data = micro,
                                   geog = c("var1"),
                                   tab_vars = c("var5","var8"),
                                   record_key_arg = "record_key",
                                   ptable = ptable_10_5)

  expect_equal(nrow(result),200)
})


# Create perturbed table for micro data with geog=var1 & tab_vars=var5,var8
# and check columns, including counts, match those from python
# implementation of ckp
test_that("Perturbed table has expected counts", {

  result <- create_perturbed_table(data = micro,
                                   geog = c("var1"),
                                   tab_vars = c("var5","var8"),
                                   record_key_arg = "record_key",
                                   ptable = ptable_10_5)


  # Load expected_result from rda file, and sort data for comparison
  load(file = "perturbed_table_var1_var5_var8.rda")
  grouping_cols <- c("var1","var5","var8")
  expected_result[,(grouping_cols):=lapply(.SD,as.character),
                  .SDcols=grouping_cols]
  setorderv(expected_result,grouping_cols)
  setorderv(result,grouping_cols)

  # Compare calculated columns, including counts
  expect_identical(result$ckey,expected_result$ckey)
  expect_identical(result$pcv,expected_result$pcv)
  expect_identical(result$pre_sdc_count,expected_result$pre_sdc_count)
  expect_identical(result$pvalue,expected_result$pvalue)
  expect_identical(result$count,expected_result$count)

})

# -----------------------------------------------------------------------------
# TESTS: 7. Check function works when only 1 grouping variable specified
# -----------------------------------------------------------------------------

test_that("create_perturbed_table works when only 1 grouping variable", {

  result <- create_perturbed_table(data = micro,
                                   geog = NULL,
                                   tab_vars = c("var5"),
                                   record_key_arg = "record_key",
                                   ptable = ptable_10_5)
  expect_equal(nrow(result),10) # var5 values 1-10


  result <- create_perturbed_table(data = micro,
                                   geog = c("var1"),
                                   tab_vars = NULL,
                                   record_key_arg = "record_key",
                                   ptable = ptable_10_5)
  expect_equal(nrow(result),5) # var1 values 1-5

})

