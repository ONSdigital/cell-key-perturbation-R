# Cell Key Perturbation in R

# Method Description


### Overview

 | Descriptive      | Details                         |
 |:---              | :----                           |
 | Support Area     | Statistical Disclosure Control  | 
 | Method Theme     | Statistical Disclosure Control  |
 | Status           | Ready to Use  |
 | Inputs           | data, record_key_arg, geog, tab_vars, ptable |
 | Outputs          | frequency table with cell key perturbation applied |
 | Method Version   | 1.0.0                              |

### Summary

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


### Terminology

- Record key - A random number assigned to each record 
- Cell value - The number of records or frequency for a cell
- Cell key - The sum of record keys for a given cell
- pvalue - perturbation value. The value of noise added to cells, e.g. +1, -1
- pcv - perturbation cell value. This is an amended cell value needed to merge 
on the ptable
- ptable - perturbation table. The look-up file containing the pvalues, this 
determines which cells get perturbed and by how much.


### Statistical Process Flow / Formal Definition

Cell key perturbation requires that the data to be aggregated contain a column 
for 'record key'. Previously, record keys between 0-255 have been used (as for 
census-2021). The method has been extended to also handle record keys in the 
range 0-4096 for purpose of processing administrative data. 
Record keys are random, uniformly distributed integers within the chosen range.

The method requires microdata, a ptable file, and the variables to be 
tabulated to be specified. It is expected that users will tabulate 1-4 
variables for a particular geography level e.g. tabulate age by gender at local 
authority level. 

The create_perturbed_table function counts how many rows in the data
contain each combination of categories e.g. how many respondents are of
each age category in each local authority area. The sum of the record
keys for each record in each cell is also calculated. Modulo 256 or 4096
of the sum is taken so this 'cell key' is within range. The table now has 
perturbation cell values (pcv) and cell keys (ckey).

The ptable is merged with the data, matching on 'pcv' and 'ckey'. The merge 
provides a 'pvalue' for each cell. The post perturbation count ('count' column) 
is the pre-perturbation count ('pre_sdc_count'), plus the perturbation value
('pvalue'). After this step, the counts have had the required perturbation 
applied. The output is the frequency table with the post-perturbation 'count' 
column. The result is that counts have been deliberately changed based on the 
ptable, for the purpose of disclosure protection.

To limit the size of the ptable, only 750 rows are used, and rows
501-750 are used repeatedly for larger cell values. E.g. instead of
containing 100,001 rows, when the cell value is 100,001 the 501st row
is used. Rows 501-750 will be used for cell values of 501-750, as well
as 751-1000, 1001-1250, 1251-1500 and so on. To achieve this effect an
alternative cell value column (pcv) is calculated which will be between 0-750.
For cell values 0-750 the pcv will be the same as the cell value. For
cell values above 750, the values are transformed by -1, modulo 250,
+501. This achieves the looping effect so that cell values 751, 1001,
1251 and so on will have a pcv of 501.

As well as specifying the level of perturbation, the ptable can also be used 
to apply rounding, and a threshold for small counts. The example ptable 
supplied with this method, ptable_10_5, applies the 10_5 rule (supressing 
values less then 10 and rounding others to the nearest 5) for record keys 
in range 0-255.

### Assumptions & Vailidity

The microdata must contain one column per variable, which are expected to be 
categorical (they can be numeric but categorical is more suitable for 
frequency tables). 

Ideally, the ptable used and the record keys attached to the microdata should 
use the same record key range, 0-255 or 0-4095.

Cell Key Perturbation is consistent and repeatable, so the same cells are 
always perturbed in the same way.

### Worked Example (optional)

### Issues for Consideration (optional)

### References (optional)


# User Notes

### Finding and Installing the method

This method requires R version 2.10 or higher and uses the data.table package.

The method package can be installed from GitHub using the following code in 
the RStudio terminal:

```
# install.packages("devtools")
devtools::install_github("ONSdigital/cell-key-perturbation-R", build_vignettes = TRUE)
```

In your code you can load the cell key perturbation package using:

```
library(cellkeyperturbation)
```

### Requirements and Dependencies 

- This method requires microdata and a ptable file. 
- The microdata and the ptable each need to be supplied as a data.table.
- The microdata must include a record key variable for cell key perturbation 
to be applied.
- There are no methods dependent on cell key perturbation.


### Assumptions and Validity 

The microdata must contain one column per variable, which are expected to be 
categorical (they can be numeric but categorical is more suitable for 
frequency tables). 

The 'record key' column in the microdata will be an interger, randomly 
uniformly distributed either in the range 0-255 or 0-4095.

A ptable file needs to be supplied which determines which cells are perturbed 
and by how much (most cells are perturbed by +0). 

The ptable used and the record keys attached to the microdata should ideally use  
the same record key range, 0-255 or 0-4095. The method will still work if they
do not match but a warning message will be generated.

By default a ptable that applies the '10-5 rule' is provided with the method 
package and works with record keys in the range 0-255. This ptable will 
remove all cells \<10, and round all others to the nearest 5. This provides 
more protection than necessary but will ensure safe outputs. 

Other ptables may be available depending on the data used, for example 
census 2021 data will require the ptable_census21 to be used and is based 
on cell keys in the range 0-255.

Cell Key Perturbation is consistent and repeatable, so the same cells are 
always perturbed in the same way.


## How to Use the Method

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

```
# library(cellkeyperturbation)
micro
ptable_10_5
```

## Worked Example

1.  Install the cell key perturbation package.
```
# install.packages("devtools")
devtools::install_github("ONSdigital/cell-key-perturbation-R")
```

2.  Load the package.
```
library(cellkeyperturbation)
```

3. Test calling the method using the example data (micro) and 
ptable (ptable_10_5), specifying the record_key, geog and tab_vars as
columns in micro.

```
perturbed_table <- create_perturbed_table(data = micro,
                                         record_key_arg = "record_key",
                                         geog = c("var1"),
                                         tab_vars = c("var5","var8"),
                                         ptable = ptable_10_5)
```

4.  To use the method with your own microdata and ptable, ensure that these are 
each ready to pass to the method in the form of a data.table. These can be 
read in from csv files using data.table's fast read function, 'fread'. 
For example:

```
library(data.table)
input_microdata <- fread("input_microdata.csv")

```

5.  Define the arguments of the create_perturbed_table function (data, 
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

6. Drop the additional columns used for processing before publishing the data. 
The resulting frequency table and counts can be saved to a csv file using 
data.table's fast write function. For example:

```
perturbed_table[,':='(ckey=NULL, pcv=NULL, pre_sdc_count=NULL, pvalue=NULL)]
fwrite(perturbed_table,"perturbed_table.csv")
```

### Treatment of Special Cases


### Other Outputs and Metadata (optional)

In addition to the category variables and the post-perturbation count, the 
output data set contains 5 additional columns which were used for processing. 
The ckey, pcv, pre_sdc_count and pvalue columns should be dropped before the 
contingency table is published.

### Issues for Consideration (optional)
 
 
### Appendix (optional)

The help pages for the package include 

- Introduction to cellkeyperturbation vignette
- create_perturbed_table - describes the main function used to create a 
frequency table with perturbation applied
- micro - an example randomly generated dataset to showcase the method
- ptable_10_5 - an example ptable for applying perturbation with a threshold 
of 10 and rounding to base 5

These can be viewed by selecting the cellkeyperturbation package name in the 
packages tab of RStudio or using: 

```
help(package=cellkeyperturbation)

vignette("intro_to_cellkeyperturbation")

#library(cellkeyperturbation)
help(create_perturbed_table)
help(micro)
help(ptable_10_5)
```


### Additional Information

The ONS Statistical Methods Library at https://statisticalmethodslibrary.ons.gov.uk/ 
contains:
.	Further information about the methods including a link to the GitHub 
repository which contains detailed API information as part of the method code.
.	Information about other methods available through the library.


### License

Unless stated otherwise, the SML codebase is released under the MIT License. 
This covers both the codebase and any sample code in the documentation.
The documentation is available under the terms of the Open Government 3.0 
license.
