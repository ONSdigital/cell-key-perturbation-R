
#' Create a perturbed frequency table in BigQuery and return it as a data frame
#'
#' This function runs the perturbation method fully in BigQuery (via SQL) and
#' only downloads the result, which allows handling large datasets efficiently.
#'
#' @details
#' Function workflow:
#'   1) Generate BigQuery SQL query to run perturbation on BigQuery
#'   2) If return_query = TRUE, return the query text and exit:
#'      otherwise, execute the rest
#'   3) Validate inputs using BigQuery
#'   4) Run perturbation using BigQuery
#'   5) Convert perturbed table to data.table and sort
#'
#' The query build by this function does the following when executed:
#'  * Computes counts and cell keys for each unique combination of geographic
#' and tabulation variables.
#'  * Includes zero-count cells by generating the full cartesian product of
#' variable combinations.
#'  * Calculates pcv by ensuring the rows of ptable 501-750 are reused for
#' cell values above 750.
#'  * Applies perturbation values from a perturbation table based on cell keys
#' and pseudo cell values (pcv).
#'  * Suppresses cells below a specified threshold by setting their perturbed
#' count to NULL.
#'
#' @param con --`DBIConnection`.
#'   An active BigQuery connection created with `DBI::dbConnect()`
#' @param data --`character`.
#'   BigQuery table name for microdata in full format:
#'   `"<PROJECT>.<DATASET>.<TABLE>"`.
#'   One row per statistical unit (person, household, business, etc.),
#'   and one column per variable (e.g. age, sex, health status)
#' @param ptable --`character`.
#'   BigQuery table name for the p-table in full format:
#'   `"<PROJECT>.<DATASET>.<TABLE>"`.
#' @param geog --`character vector`.
#'   Column name containing the desired geography level for the frequency table.
#'   e.g., `c("Region")` or `c("LocalAuthority")`.
#'   Use `c()` if no geography breakdown required.
#' @param tab_vars --`character vector`.
#'   Column names to tabulate, e.g., `c("Age", "Health", "Occupation")`.
#' @param record_key --`character`.
#'   Column name with record keys required for perturbation,
#'   e.g., `"Record_Key"`.
#' @param threshold --`integer`.
#'   Suppression threshold; perturbed counts below this value are suppressed.
#'   Default 10.
#' @param return_query --`logical`.
#'   If `TRUE`, returns the generated SQL query without executing it.
#'   Default `FALSE`.
#'
#' @return
#' - When `return_query = FALSE`: a `data.table` containing the perturbed
#'   frequency table, sorted by `geog` and `tab_vars`.
#' - When `return_query = TRUE`: a character string containing the query.
#'
#' @import data.table
#'
#' @export
#'
#' @examples
#' # --- Return query text without executing it ---
#' query <- create_perturbed_table_bigquery(
#'   con        = NULL,
#'   data       = "my-gcp-project.survey.microdata",
#'   ptable     = "my-gcp-project.sdc.ptable",
#'   geog       = c("Region"),
#'   tab_vars   = c("AgeGroup", "HealthStatus", "Occupation"),
#'   record_key = "Record_Key",
#'   threshold  = 10,
#'   return_query = TRUE
#' )
#' cat(query)
#'
#' # --- Requires active DBI connection: ---
#' \dontrun{
#' library(DBI)
#' library(bigrquery)
#'
#' project_id <- system("gcloud config get project", intern = TRUE)
#' con <- DBI::dbConnect(
#'   bigrquery::bigquery(),
#'   project = project_id,
#'   bigint = "integer64"
#' )
#' perturbed_table <- create_perturbed_table_bigquery(
#'   con        = con,
#'   data       = "my-gcp-project.survey.microdata",
#'   ptable     = "my-gcp-project.sdc.ptable",
#'   geog       = c("Region"),
#'   tab_vars   = c("AgeGroup", "HealthStatus", "Occupation"),
#'   record_key = "Record_Key",
#'   threshold  = 10
#' )
#' }
create_perturbed_table_bigquery <- function(
    con,
    data,
    ptable,
    geog,
    tab_vars,
    record_key,
    threshold = 10,
    return_query = FALSE)
{
  query <- build_perturbation_bigquery(
    data       = data,
    ptable     = ptable,
    geog       = geog,
    tab_vars   = tab_vars,
    record_key = record_key,
    threshold  = threshold
  )

  if (return_query) {
    return(query)
  }

  if (!requireNamespace("DBI", quietly = TRUE)) {
    stop(
      'Package "DBI" must be installed to validate inputs and execute query.',
      call. = FALSE
    )
  }
  if (!inherits(con, "DBIConnection")) {
    stop(
      "`con` must be a DBIConnection when `return_sql = FALSE`.",
      call. = FALSE)
  }

  validate_inputs_bigquery(
    con        = con,
    data       = data,
    ptable     = ptable,
    geog       = geog,
    tab_vars   = tab_vars,
    record_key = record_key,
    threshold  = threshold
  )

  perturbed_table <- DBI::dbGetQuery(con, query)

  perturbed_table <- as.data.table(perturbed_table)

  sort_cols <- c(geog, tab_vars)
  setorderv(perturbed_table, sort_cols)

  return(perturbed_table)
}


##==============================================================================
build_perturbation_bigquery <- function(
    data,
    ptable,
    geog,
    tab_vars,
    record_key,
    threshold)
{
  all_vars <- c(geog, tab_vars)

  # Build common strings
  all_vars_str   <- paste(all_vars, collapse = ", ")
  dim_ctes       <- paste0("dim_", all_vars, " AS (SELECT DISTINCT ",
                           all_vars, " FROM distinct_vars)")
  dim_ctes_str   <- paste(dim_ctes, collapse = ",\n\t")
  cross_join     <- paste(paste0("dim_", all_vars),
                          collapse = "\n\tCROSS JOIN ")
  join_conditions <- paste(paste0("g.", all_vars, " = b.", all_vars),
                           collapse = " AND ")
  select_columns  <- paste(paste0("g.", all_vars), collapse = ", ")

  # Compose query
  query <- paste0("
-- Step 1: Create dimension tables
    WITH
        distinct_vars AS (
            SELECT DISTINCT ", all_vars_str, "
            FROM `", data, "`
        ),
        ", dim_ctes_str, ",

-- Step 2: Create full grid of all combinations
    full_grid AS (
        SELECT *
        FROM ", cross_join, "
    ),

-- Step 3: Aggregate actual counts
    base_counts AS (
        SELECT
            ", all_vars_str, ",
            COUNT(*) AS pre_sdc_count,
            SUM(CAST(", record_key, " AS INT64)) AS sum_rkey
        FROM `", data, "`
        GROUP BY ", all_vars_str, "
    ),

-- Step 4: Join full grid with actual counts
    full_counts AS (
        SELECT
            ", select_columns, ",
            COALESCE(b.pre_sdc_count, 0) AS pre_sdc_count,
            COALESCE(b.sum_rkey, 0) AS sum_rkey
        FROM full_grid g
        LEFT JOIN base_counts b
            ON ", join_conditions, "
    ),

-- Step 5: Compute cell key modulo
    ckey_mod AS (
        SELECT *,
            MOD(sum_rkey, (SELECT MAX(ckey) + 1 FROM `", ptable, "`)) AS ckey
        FROM full_counts
    ),

-- Step 6: Calculate pcv
    pcv_calc AS (
        SELECT *,
            CASE
                WHEN pre_sdc_count <= 750 THEN pre_sdc_count
                ELSE MOD((pre_sdc_count - 1), 250) + 501
            END AS pcv
        FROM ckey_mod
    ),

-- Step 7: Join with perturbation table
    joined AS (
        SELECT
            ", all_vars_str, ",
            a.pre_sdc_count,
            a.ckey,
            a.pcv,
            COALESCE(b.pvalue, 0) AS pvalue
        FROM pcv_calc a
        LEFT JOIN `", ptable, "` b
            ON a.pcv = b.pcv AND a.ckey = b.ckey
    ),

-- Step 8: Apply perturbation and suppression
    final_table AS (
        SELECT *,
            pre_sdc_count + pvalue AS raw_count,
            CASE
                WHEN pre_sdc_count + pvalue < ", threshold, " THEN NULL
                ELSE pre_sdc_count + pvalue
            END AS count
        FROM joined
    )

-- Final output
    SELECT
        ", all_vars_str, ",
        pre_sdc_count,
        ckey,
        pcv,
        pvalue,
        count
    FROM final_table;"
  )
  return(query)
}
