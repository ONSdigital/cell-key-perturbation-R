
# cellkeyperturbation 3.0.0

## Major Changes

* Functionality to create perturbed table using BigQuery including validation process
to be able to work with large datasets in a Google Cloud Platform environment.

* Generate record keys from ons_id as default where ons_id exists, with an option to turn it off.


## Minor improvements and bug fixes

* Created functions to generate sample microdata, ptable_10_5, and random record 
keys for testing purposes, with alternative parameters allowed. 
The sample microdata included in the package is identical with the one in python version. 
Even if you create a new sample microdata with the same parameters, that would not be identical.

* Validation moved to a separate module with improved and additional validation checks.

* **Tabulation with missing values:** Missing values will be included in the frequency table, 
treating missingess as a category. Added a check function for missing values in tabulation variables, 
which returns a warning message if any of the tabulation variables contains missing values 
and suggests to consider removing them.

* Re-ordered columns and standardised the data type for output tables.

# cellkeyperturbation 2.0.0

* New threshold parameter added (with default of 10) for the create_perturbed_table function. Counts < threshold will be set to missing. This means that the user will not need to go through an additional process to suppress small counts after applying perturbation.

* Warnings if any records are missing record keys and exception raised if percentage with record keys < 50%.

* The 'record_key_arg' parameter renamed to 'record_key' to match the Python implementation.

# cellkeyperturbation 1.0.0

* First release

# cellkeyperturbation (development version 0.0.0.9000)


