
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cellkeyperturbation

<!-- badges: start -->
<!-- badges: end -->

This package runs the SDC methods required for frequency tables in IDS.
It enables the user to create a frequency table which has cell key
perturbation applied to the counts, meaning that users cannot be sure
whether differences between tables represent a real person, or are
caused by the perturbation.

Cell Key Perturbation is consistent and repeatable, so the same cells
are always perturbed in the same way.

## Installation

You can install the development version of cellkeyperturbation from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("ONSdigital/cell-key-perturbation-R")
```

## Example

This is an example which showing how to create a perturbed table from
data included in this package in order to showcase the method.

micro is an example dataset containing randomly generated data.

ptable_10_5 is an example ptable containing the rules to apply cell key
perturbation with a threshold of 10 and rounding to base 5.

``` r
library(cellkeyperturbation)
perturbed_table <-create_perturbed_table(data = micro,
                                         record_key_arg = "record_key",
                                         geog = c("var1"),
                                         tab_vars = c("var5","var8"),
                                         ptable = ptable_10_5)
```
