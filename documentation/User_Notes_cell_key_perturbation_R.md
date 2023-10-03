# Statistical Method User Notes -- Cell Key Perturbation


### Overview

 | Descriptive      | Details                         |
 |:---              | :----                           |
 | Method name      |Cell key perturbation            | 
 | Method theme     |Statistical disclosure control   |
 | Expert group     |Statistical Disclosure Control   |
 | Languages        |R                           |
 | Release          |1.0                              |


### User Note Amendments/Change Log

 | Document version  | Description |Author(s)       |     Date        |    Comments      |
 |:---               | :----       |:---            |:---             |:---              |      
 |1.0                |First draft based on python version  | Elinor Everitt      |03/10/23         |First draft 

### Method Specification

<https://github.com/ONSdigital/cell-key-perturbation-R/blob/main/documentation/Method_Specification_cell_key_perturbation_R.md>

### How to run the method (single or multi language)

Please see the following link to the Cell Key Perturbation GitHub repository:
<https://github.com/ONSdigital/cell-key-perturbation-R>

R version can be accessed using the following code to import:
```
# install.packages("devtools")
devtools::install_github("ONSdigital/cell-key-perturbation-R")
```

Once the package is loaded, help pages for the package can be viewed: 
```
library(cellkeyperturbation)
help(package=cellkeyperturbation)
```
The help pages include 
- Introduction to cellkeyperturbation vignette
- create_perturbed_table - describes the main function used to create a frequency table with perturbation applied
- micro - an example randomly generated dataset to showcase the method
- ptable_10_5 - an example ptable for applying perturbation with a threshold of 10 and rounding to base 5

### Pre-processing and assumptions

The code is intended for use when producing frequency tables based on
microdata (row-level data, one row per statistical unit - person,
household etc.). The microdata will contain one column per variable,
which is expected to be categorical (they can be numeric but categorical
is more suitable for frequency tables). The microdata will also contain
a column for 'record key', which is required to run the method. The
record key will be an integer, randomly uniformly distributed between
0-255.

### Inputs

The 'ptable' file contains the parameters which determine which cells
are perturbed and which are not (most cells are perturbed by +0). The
ptable contains each possible combination of cell key (0-255) and cell
value, and the perturbation a cell with that cell key and cell value
would receive. A user must use the provided ptables to ensure sufficient
protection. By default a ptable that applies the '10-5 rule' will be
provided. This ptable will remove all cells \<10, and round all others
to the nearest 5. This provides more protection than necessary but will
ensure safe outputs. Other ptables may be available depending on the
data used, for example census data will require the ptable_census21 to
be used.

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

The microdata and ptable are provided as arguments to the perturbation
function.

The user decides which variables they would like to be tabulated.

Step-by-step instructions:

1.  Install the cell key perturbation package.
```
# install.packages("devtools")
devtools::install_github("ONSdigital/cell-key-perturbation-R")
```

2.  Load the package.
```
library(cellkeyperturbation)
```

3.  Ensure that the data and ptable to be used are both ready to pass to the method in the form of a data.table. An example dataset (micro) and ptable 
    (ptable_10_5) are supplied with the method and are ready to be used.

4.  Set the geog and tab_vars parameters. These will both need to be defined as
    vectors. For tab_vars, the variables should be supplied in a vector
    of strings e.g. ```c("Age","Health","Occupation")```. The variables
    can also be left blank, i.e. ```tab_vars=c()``` or ```tab_vars=NULL```. The geography is also
    supplied as a vector e.g. ```c("Region")```. An example is included in
    the docstrings. We strongly expect users to tabulate at a given
    geography level e.g. Local Authority, Ward. If no geography is
    required, so records from all geographical areas are together, then
    a 'national' geography including all areas could be used,
    alternatively the geography can be left blank (i.e.
    ```geog=c()```or ```geog=NULL```.). However, at least one of 'tab_vars' or 'geog' must be
    populated - if both are left blank the code will not work.

5.  Define the arguments of the create_perturbed_table function (data,
    record_key_arg, geog, tab_vars and ptable) and run the function to
    create the table. 
    
 | Variable name | Variable Definition |Type of Variable| Format of specific variable (if applicable)| Expected range of the values | Meaning of the values| Expected level of aggregation | Frequency |Comments | 
 |:---       |:---     |:---     |:---   |:--- |:--- |:--- | :--- | :--- |
 | Record key | A random number 'key' which determines which cells receive perturbation |Integer | Numeric/integer | 0-255 | The values do not carry meaning, but they must remain unchanged to provide consistency in the results | It is expected that users will tabulate 1-4 variables for a particular geography level e.g. tabulate age by sex at local authority level |  | | 


### Outputs

The output from the code is a data.table containing a frequency table with the
counts having been affected by perturbation, as specified in the ptable. 
For most ptables, the most obvious effect will be that all counts less than 10
will have been reduced to 0 (removed). Counts being below a threshold is
a condition of exporting data from IDS and other secure environments.
The table will be in the following format:


  | ckey  | pcv  | var1 | var5 | var8 | pre_sdc_count | pvalue | count  |
  |:---   | :---- | :---- |:---- | :---- |:----          | :---- |:---- | 
  |  64   |  16  |  1   |   1  |   A  |      16       |   -1   |   15   | 
  | 196   |   5  |  1   |   1  |   B  |       5       |   -5   |    0   | 
  | 123   |  10  |  1   |   1  |   C  |      10       |    0   |   10   | 
  |   3   |  10  |  1   |   1  |   D  |      10       |    0   |   10   | 
  | 149   |  12  |  1   |   2  |   A  |      12       |   -2   |   10   | 
  | ...   | ...  | ...  |  ... |  ... |     ...       |  ...   |        | 
  
  
### Test data / method illustration

The method requires microdata, a ptable file, and the variables to be
tabulated as inputs. The function counts how many rows in the data
contain each combination of categories e.g. how many respondents are of
each age category in each local authority area. The sum of the record
keys for each record in each cell is also calculated. Modulo 256 of the
sum is taken so this 'cell key' is between 0-255. The table now has cell
values and cell keys.

To reduce the size of the ptable, only 750 rows are used, and rows
501-750 are used repeatedly for larger cell values. E.g. instead of
containing 100,001 rows, when the cell value is 100,001 the 501st row
is used. Rows 501-750 will be used for cell values of 501-750, as well
as 751-1000, 1001-1250, 1251-1500 and so on. To achieve this effect an
alternative cell value column is calculated which will be between 0-750.
For cell values 0-750 the pcv will be the same as the cell value. For
cell values above 750, the values are transformed by -1, modulo 250,
+501. This achieves the looping effect so that cell values 751, 1001,
1251 and so on will have a pcv of 501.

After the pcv and cell keys are calculated, the ptable can be merged on,
matching on pcv and 'ckey'. This merge provides a 'pvalue' for each
cell. The post perturbation count ('count' column) is the
pre-perturbation count ('pre_sdc_count'), plus the perturbation value
('pvalue'). After this step, the counts have had the required
perturbation applied. The output is the frequency table with the
post-perturbation 'count' column.

### Supporting Information

The code uses the data.table package.
