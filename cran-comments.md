## Resubmission

This is a resubmission with the following changes:
- Removed redundant "in R/R" wording from the Title and Description fields.
- Added a reference to the methodology in the DESCRIPTION file using a URL 
  to the package documentation.
- Removed the example with "\dontrun" as it requires an active BigQuery 
  connection and credentials. That function already has another runnable example.
- Removed fixed calls to set.seed() inside functions and made seeding optional 
  via function arguments.


## Resubmission

This is a resubmission.  
- Removed a failing URL in a vignette as requested by CRAN.


## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time

This NOTE appears to be environment-related and occurred on the CI system.
The package source files do not contain future timestamps.


## Comments
- This is the first CRAN submission of this package.
  Previous versions were released on GitHub only.

- I was unable to run check_win_devel() due to network restrictions
  blocking FTP connections to win-builder.r-project.org.
