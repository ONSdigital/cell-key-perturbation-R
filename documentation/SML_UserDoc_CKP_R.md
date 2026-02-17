# Cell Key Perturbation in R
# SML User Guide

## Overview

 | Descriptive      | Details                                             |
 |:---              | :----                                               |
 | Support Area     | Statistical Disclosure Control                      | 
 | Method Theme     | Statistical Disclosure Control                      |
 | Status           | Ready to Use                                        |
 | Inputs           | (con), data, ptable, geog, tab_vars, record_key, use_existing_ons_id, threshold |
 | Outputs          | Frequency table with cell key perturbation applied  |
 | Method Version   | 3.0.0                                               |
 | Code Repository  | [https://github.com/ONSdigital/cell-key-perturbation-R](https://github.com/ONSdigital/cell-key-perturbation-R) |

## Summary

This method creates a frequency table which has had cell key perturbation 
applied to the counts to protect against disclosure. 

Cell key perturbation adds small amounts of noise to frequency tables. 
Noise is added to change the counts that appear 
in the frequency table by small amounts, for example a 14 is changed to a 15. 
This noise introduces uncertainty in the counts and makes it harder to identify
individuals, especially when taking the 'difference' between two similar
tables. It protects against the risk of disclosure by differencing since it 
cannot be determined whether a difference between two similar tables represents 
a real person, or is caused by the perturbation.

Cell Key Perturbation is consistent and repeatable, so the same cells are 
always perturbed in the same way.

It is expected that users will tabulate 1 to 4 variables for a particular 
geography level - for example, tabulate age by sex at local authority level. 

Full details of the methodology and statistical process flow are given in the [Methodology](#methodology) section.

Cell Key Perturbation method is available in [Python](https://github.com/ONSdigital/cell-key-perturbation) and 
[R](https://github.com/ONSdigital/cell-key-perturbation-R), each with integrated BigQuery functionality.

### BigQuery

The BigQuery version allows users to perform perturbation without reading raw data into local memory. 
The package creates the frequency table and runs perturbation with an SQL query. 
Then, it converts the final perturbed table into a `pandas.DataFrame`/`data.table` as an output. 

This will allow users to run the method on large datasets without breaking the memory limits. 

### Terminology

- ***Microdata*** - Data at the level of individual respondents
- ***Record key*** - A random number assigned to each record 
- ***Cell value*** - The number of records or frequency for a cell
- ***Cell key*** - The sum of record keys for a given cell
- ***pvalue*** - Perturbation value. The value of noise added to cells, e.g. +1, -1
- ***pcv*** - Perturbation cell value. This is an amended cell value needed to merge on the ptable
- ***ptable*** - Perturbation table. The look-up file containing the pvalues, this determines which cells get perturbed and by how much.

## Requirements 

- This method requires microdata and a perturbation table (ptable) file. 
- The microdata and the ptable both need to be supplied as `pandas.DataFrame`/`data.table` or BigQuery tables.
- The microdata must include a record key variable for cell key perturbation to be applied, unless `ons_id` will be used to create record key.
- You must use the provided ptable that corresponds to your microdata, e.g. `ptable_census21` for census 2021.

### Microdata and Record Keys

**Microdata** must be row-level, i.e. one row per statistical unit such as person or household. **Microdata** must contain one column per variable, which are expected to be categorical (they can be numeric but categorical is more suitable for frequency tables). 

**Record keys** should already be attached to the **microdata** as a column of integers in the range 0-255 or 0-4095, except certain ONS datasets with `ons_id`. 
The name of the **record key** column could change in different **microdata** tables. 
For example, **record key** columns in census data tables are named as `resident_record_key`, `household_record_key`, or `family_record_key` depending on the table type.

Certain ONS datasets contain `ons_id` column and use it as the basis for record keys to keep the perturbation consistent. 
If `ons_id` is available as a column in **microdata**, then **record keys** will be derived from `ons_id` by default. 
(This can be switched off by setting `use_existing_ons_id = False`)

The range of **record keys** should match the range of **cell keys** in the **ptable**. A warning message will be generated if those ranges do not match.

Cell Key Perturbation is consistent and repeatable, so the same cells are always perturbed in the same way. 

**The **record keys** need to be unchanged, changing the **record keys** would create inconsistent results and provide much less protection. You should use **record keys** attached to your **microdata** if provided instead of creating new ones to obtain consistent perturbation across different runs.**

### Perturbation Table (P-table)

The **perturbation table** contains the parameters which determine which cells are perturbed by how much and which are not (most cells are perturbed by +0). The **ptable** contains each possible combination of **cell key** (`ckey`) and **cell value** (`pcv`), and the **perturbation value** (`pvalue`) for each combination. 

A sample **ptable** that applies the '10-5 rule' is provided with the package and works with **record keys** in the range 0-255. This **ptable** will remove all cells below the threshold of 10, and round all others to the nearest 5. This provides more protection and will ensure safe outputs.

Other **ptables** may be available depending on the **microdata** used, for example census 2021 data will require the `ptable_census21` to be used and is based on cell keys in the range 0-255.

**You must use the specific **ptable** provided with the **microdata** you are working with to ensure sufficient and consistent protection, e.g. `ptable_census21` for census 2021.**


# User Instructions

## Installing the SML method

This method requires R version 2.10 or higher and uses the data.table package.

The method package can be installed by downloading the tar file from [https://github.com/ONSdigital/cell-key-perturbation-R/releases](https://github.com/ONSdigital/cell-key-perturbation-R/releases) and using the following code in the RStudio terminal, specifying your download location:

```r
install.packages("<path_to_file>/cellkeyperturbation_1.0.0.tar.gz", repos = NULL, type="source", build_vignettes = TRUE)
```

In your code you can load the cell key perturbation package using:

```r
library(cellkeyperturbation)
```

## Using the SML method

### Method Input

The 'create_perturbed_table()' function which creates the frequency table with 
cell key perturbation applied has the following arguments:

create_perturbed_table(data, geog, tab_vars, record_key_arg, ptable)

- data - a data.table containing the data to be tabulated and perturbed.
- geog - a string vector giving the column name in 'data' that contains the 
desired geography level you wish to tabulate at, e.g. c("Local_Authority", 
"Ward"). This can be the empty vector, c(), if no geography level is required.
- tab_vars - a string vector giving the column names in 'data' of the variables 
to be tabulated e.g. c("Age","Health","Occupation"). This can also be the empty 
vector, c(). However, at least one of 'tab_vars' or 'geog' must be populated - 
if both are left blank an error message will be returned.
- record_key_arg - a string containing the column name in 'data' giving the 
record keys required for perturbation. 
- ptable - a data.table containing the 'ptable' file which determines when 
perturbation is applied.

Example rows of a microdata table are shown below:

 | record_key  | var1  | var5  | var8  | 
 |       :---  | :---- | :---- | :---- | 
 |      84     | 2     | 9     | D     | 
 |     108     | 1     | 9     | C     | 
 |     212     | 1     | 1     | D     | 
 |     212     | 2     | 2     | A     | 
 |      86     | 2     | 4     | A     | 
   
Example rows of a ptable are shown below:  

 | pcv  | ckey  | pvalue |
 |:---  | :---- | :----  |
 |   1  |    0  |    -1  | 
 |   1  |    1  |    -1  | 
 |   1  |    2  |    -1  | 
 |   1  |    3  |    -1  | 
 |   1  |    4  |    -1  |  
 | ...  |  ...  |   ...  |    
 | 750  |  251  |     0  |
 | 750  |  252  |     0  | 
 | 750  |  253  |     0  | 
 | 750  |  254  |     0  |  
 | 750  |  255  |     0  |


### Method Output 

The output from the code is a data.table containing a frequency table with the
counts having been affected by perturbation, as specified in the ptable. 

The table will be in the following format:


  | ckey  | pcv   | var1  | var5 | var8  | pre_sdc_count | pvalue | count  |
  |:---   | :---- | :---- |:---- | :---- |:----          | :----  |:----   | 
  |  64   |  16   |  1    |   1  |   A   |      16       |   -1   |   15   | 
  | 196   |   5   |  1    |   1  |   B   |       5       |   -5   |    0   | 
  | 123   |  10   |  1    |   1  |   C   |       10      |    0   |   10   | 
  |   3   |  10   |  1    |   1  |   D   |      10       |    0   |   10   | 
  | 149   |  12   |  1    |   2  |   A   |      12       |   -2   |   10   | 
  | ...   | ...   | ...   |  ... |  ...  |     ...       |  ...   |        | 
  

The table contains the variables used as the categories used to summarise the 
data (in this example var1, var5 & var8), and five other columns:

- 'ckey' is the sum of record keys for each combination of variables
- 'pcv' is the perturbation cell value, the pre-perturbation count modulo 750
- 'pre_sdc_count' is the pre-perturbation count 
- 'pvalue' is the perturbation applied to the original count, most commonly 
it will be 0. This is obtained from the ptable using a join on ckey and pcv.
- 'count' is the post-perturbation count, the values to be output

The columns you are most likely interested in are the variables, which 
are the categories you've summarised by, plus the 'count' column.

The ckey, pcv, pre_sdc_count and pvalue columns should be dropped before the 
contingency table is published.


### Example (Synthetic) Data

An example data set and ptable are included in the method package: 
- micro - randomly generated data with record keys in the range 0-255
- ptable_10_5 - ptable which applies the 10_5 rule with record keys in 
range 0-255

These can be viewed using:

```r
# library(cellkeyperturbation)
micro
ptable_10_5
```

## Worked Example

1.  Install and load the cell key perturbation package.
```r
library(cellkeyperturbation)
```

2. Test calling the method using the example data (micro) and 
ptable (ptable_10_5), specifying the record_key, geog and tab_vars as
columns in micro.

```r
perturbed_table <- create_perturbed_table(data = micro,
                                         record_key_arg = "record_key",
                                         geog = c("var1"),
                                         tab_vars = c("var5","var8"),
                                         ptable = ptable_10_5)
```

3.  To use the method with your own microdata and ptable, ensure that these are 
each ready to pass to the method in the form of a data.table. These can be 
read in from csv files using data.table's fast read function, 'fread'. 
For example:

```r
library(data.table)
input_microdata <- fread("input_microdata.csv")

```

4.  Define the arguments of the create_perturbed_table function (data, 
record_key_arg, geog, tab_vars and ptable) and run the function to create the 
table. 
- The geog parameter should be supplied as a vector e.g. ```c("Region")```. 
We strongly expect users to tabulate at a given geography level e.g. Local 
Authority, Ward. If no geography is required, so records from all geographical 
areas are together, then a 'national' geography including all areas could be 
used, alternatively the geography can be left blank 
(i.e.```geog=c()```or ```geog=NULL```). 
- The tab_vars parameter should be supplied as a vector of strings 
e.g. ```c("Age","Health","Occupation")``` but can also be left blank, 
(i.e. ```tab_vars=c()``` or ```tab_vars=NULL```). 
- At least one of 'tab_vars' or 'geog' must be populated - if both are left 
blank an error message will be returned and the method will not work.

5. Drop the additional columns used for processing before publishing the data. 
The resulting frequency table and counts can be saved to a csv file using 
data.table's fast write function. For example:

```r
perturbed_table[,':='(ckey=NULL, pcv=NULL, pre_sdc_count=NULL, pvalue=NULL)]
fwrite(perturbed_table,"perturbed_table.csv")
```

### Other Outputs and Metadata

In addition to the category variables and the post-perturbation count, the 
output data set contains 5 additional columns which were used for processing. 
The ckey, pcv, pre_sdc_count and pvalue columns should be dropped before the 
contingency table is published.

### Appendix - Help Pages

The help pages for the package include 

- Introduction to cellkeyperturbation vignette
- create_perturbed_table - describes the main function used to create a 
frequency table with perturbation applied
- micro - an example randomly generated dataset to showcase the method
- ptable_10_5 - an example ptable for applying perturbation with a threshold 
of 10 and rounding to base 5

These can be viewed by selecting the cellkeyperturbation package name in the 
packages tab of RStudio or using: 

```r
help(package=cellkeyperturbation)

vignette("intro_to_cellkeyperturbation")

#library(cellkeyperturbation)
help(create_perturbed_table)
help(micro)
help(ptable_10_5)
```


# Methodology

The user is required to supply **microdata** and to specify which columns in the
data they want to tabulate by. They must also supply a **ptable** which will 
determine which cells get perturbed and by how much.

The **microdata** needs to contain a column for **record key**. **Record keys** are 
random, uniformly distributed integers within the chosen range. Previously, 
**record keys** between 0-255 have been used (as for census-2021). The method has 
been extended to also handle **record keys** in the range 0-4095 for the purpose of 
processing administrative data. 

It is expected that users will tabulate 1-4 variables for a particular geography 
level e.g. tabulate age by sex at local authority level. 

The `create_perturbed_table()` function counts how many rows in the data
contain each combination of categories e.g. how many respondents are of
each age category in each local authority area. The sum of the **record
keys** for each record in each cell is also calculated. Modulo 256 or 4096
of the sum is taken so this **cell key** is within range. The table now has 
**perturbation cell values** (`pcv`) and **cell keys** (`ckey`).

The **ptable** is merged with the data, matching on `pcv` and `ckey`. The merge 
provides a `pvalue` for each cell. The **post perturbation count** (`count`) 
is the **pre-perturbation count** (`pre_sdc_count`), plus the **perturbation value**
(`pvalue`). After this step, the counts have had the required perturbation 
applied. The output is the frequency table with the **post-perturbation count** (`count`) 
column. The result is that counts have been deliberately changed based on the 
**ptable**, for the purpose of disclosure protection.

To limit the size of the **ptable**, only 750 rows are used, and rows
501-750 are used repeatedly for larger cell values. E.g. instead of
containing 100,001 rows, when the cell value is 100,001 the 501st row
is used. Rows 501-750 will be used for cell values of 501-750, as well
as 751-1000, 1001-1250, 1251-1500 and so on. To achieve this effect an
alternative cell value column (`pcv`) is calculated which will be between 0-750.
For cell values 0-750 the `pcv` will be the same as the cell value. For
cell values above 750, the values are transformed by -1, modulo 250,
+501. This achieves the looping effect so that cell values 751, 1001,
1251 and so on will have a `pcv` of 501.

After cell key perturbation is applied, a **threshold** is applied so that any 
counts below the **threshold** will be suppressed (set to missing). The user can 
specify the value for the **threshold**, but if they do not, the default value of 
10 will be applied. Setting the **threshold** to zero would mean no suppression is 
applied.

As well as specifying the level of perturbation, the **ptable** can also be used 
to apply rounding, and a **threshold** for small counts. The example **ptable** 
supplied with this method, `ptable_10_5`, applies the 10_5 rule (supressing 
values less than 10 and rounding others to the nearest 5) for **record keys** 
in the range 0-255.


# Additional Information

The ONS Statistical Methods Library at https://statisticalmethodslibrary.ons.gov.uk/ contains:
-	Further information about the methods including a link to the GitHub 
repository which contains detailed API information as part of the method code.
-	Information about other methods available through the library.


## License

Unless stated otherwise, the SML codebase is released under the MIT License. 
This covers both the codebase and any sample code in the documentation.
The documentation is available under the terms of the Open Government 3.0 
license. 
