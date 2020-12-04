library(shiny)
library(grid)
library(sdmApp)
library(rhandsontable)
library(haven)
library(shinyBS)
library(data.table)
library(sf) # classes and functions for vector data
library(raster)# classes and functions for raster data
library(ggplot2)
library(biomod2)
library(dismo)
library(DT)
library(readxl)
library(shinyFiles)
library(shinydashboard)
library(SSDM)
library(automap)
library(blockCV)
library(tidyverse)
library(ggpubr)
library(CENFA)
library(rJava)
library(randomForest)
library(kernlab)
library(dplyr)

if (!getShinyOption("sdmAppInvoked", FALSE)) {### Beginning required code for deployment
  .startdir <- .guitheme <- .guijsfile <- NULL
  # maxRequestSize <- 50
  # options(shiny.maxRequestSize=ceiling(maxRequestSize)*1024^2)

  shinyOptions(.startdir = getwd())

  theme="IHSN"
  shinyOptions(.guitheme = "ihsn-root.css")
  shinyOptions(.guijsfile = "js/ihsn-style.js")
}## End of deployment code
# required that 'dQuote()' works nicely when
# outputting R-Code
options(useFancyQuotes=FALSE)
#obj=sdm is an object
obj <- reactiveValues()
obj$code_read_and_modify <- c()
#$code_setup <- c()
obj$code_model <- c()
obj$code <- c(
  paste("# created using sdmApp", packageVersion("sdmApp")),
  "library(sdmApp)", "",
  "obj <- NULL")

obj$cur_selection_results <- "btn_results_1"

