library(data.table)

#' Create a frequency table which has has a cell key perturbation applied
#'
#' 'create_perturbed_table()' creates a frequency table which has has a
#'  cell key perturbation technique applied with help from a p-table which
#'  determines how perturbation is applied.
#'  The perturbation adds a small amount of noise to some cells in a table,
#'  meaning that users cannot be sure whether differences between tables
#'  represent a real person, or are caused by the perturbation.
#'  Cell Key Perturbation is consistent and repeatable, so the same cells are
#'  always perturbed in the same way.
#'
#' @param data A data.table containing the data to be tabulated and perturbed
#' @param geog A string vector giving the column name in 'data' that contains the desired geography level for the frequency table
#' @param tab_vars A string vector giving the column names in 'data' of the variables to be tabulated.
#' @param record_key_arg A String containing the column name in 'data' giving the record keys required for perturbation.
#' @param ptable A data.table containing the 'ptable' file which determines when perturbation is applied.
#'
#' @return Returns a data.table giving a frequency table which has had cell key perturbation applied according to the ptable supplied.
#'
#' @examples
#' micro <- fread("census_2011.csv")
#' ptable_10_5 <- fread("ptable_10_5_rule.csv")
#'
#' geog <- c("Region")
#' tab_vars <- c("Age","Health","Occupation")
#' record_key_arg <-"record_key"
#'
#' perturbed_table  <- create_perturbed_table(micro, geog, tab_vars, record_key_arg, ptable_10_5)
#'
#' Using direct inputs, and selecting no geography breakdown:
#'
#' perturbed_table <-create_perturbed_table(data = micro,
#'                                          record_key = "Record_key",
#'                                          geog = c(),
#'                                          tab_vars = c("Sex","Industry","Occupation"),
#'                                          ptable = ptable_10_5)
#'
create_perturbed_table <- function(data, geog, tab_vars, record_key_arg, ptable)
{
  #drop unnecessary columns
  data=data[,c(geog,tab_vars,record_key_arg),with=FALSE]

  #convert every column to factor, except record_key
  cols <- colnames(data)[!(colnames(data) %in% record_key_arg)]
  data[,(cols):=lapply(.SD,as.factor),.SDcols=cols]

  #tabulate - use table to get zero cells
  aggregated_table<-as.data.table(table(data[,c(geog,tab_vars),with=FALSE]))
  colnames(aggregated_table)[colnames(aggregated_table) == "N"] <- "pre_sdc_count"

  #calculate cell keys
  cellkeys<-setDT(data)[,.(ckey = sum(get(record_key_arg))%%256), keyby = c(geog,tab_vars)]
  aggregated_table<-merge(aggregated_table,cellkeys,by=c(geog,tab_vars),all.x=TRUE)

  #calculate pcv
  aggregated_table$pcv<-as.integer(((aggregated_table$pre_sdc_count-1)%%250)+501)
  setDT(aggregated_table)[pre_sdc_count<=750, pcv:=pre_sdc_count,]

  #merge on ptable
  aggregated_table<-merge(aggregated_table,ptable,by=c("ckey","pcv"), all.x=TRUE,sort=FALSE)
  aggregated_table[pre_sdc_count==0,pvalue:=0]
  setDT(aggregated_table)[,count:=pre_sdc_count+pvalue,]

  return(aggregated_table)
}
