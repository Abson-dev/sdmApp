# sdmApp <img src="inst/docs/Logo_sdmApp.png" align="right" width="120" />
 Species Distribution Models Application

<!--[![Build Status](https://travis-ci.com/Abson-dev/sdmApp.svg?branch=master)](https://travis-ci.com/Abson-dev/sdmApp)
[![Travis build status](https://travis-ci.com/Abson-dev/sdmApp.svg?branch=master)](https://travis-ci.com/Abson-dev/sdmApp)-->
<!--[![codecov](https://codecov.io/gh/Abson-dev/sdmApp/branch/master/graph/badge.svg)](https://codecov.io/gh/Abson-dev/sdmApp)-->
[![R build status](https://github.com/Abson-dev/sdmApp/workflows/R-CMD-check/badge.svg)](https://github.com/Abson-dev/sdmApp/actions)
[![Coverage Status](https://coveralls.io/repos/github/Abson-dev/sdmApp/badge.svg?branch=master)](https://coveralls.io/github/Abson-dev/sdmApp?branch=master)
[![License](https://img.shields.io/badge/license-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![CRAN version](https://www.r-pkg.org/badges/version/sdmApp)](https://CRAN.R-project.org/package=sdmApp)
![Github](https://img.shields.io/badge/Github-0.0.1-green.svg)
[![Last-change date](https://img.shields.io/github/last-commit/Abson-dev/sdmApp.svg)](https://github.com/Abson-dev/sdmApp/commits/master)
[![Downloads](http://cranlogs.r-pkg.org/badges/sdmApp)](https://CRAN.R-project.org/package=sdmApp)
[![total](http://cranlogs.r-pkg.org/badges/grand-total/sdmApp)](https://www.rpackages.io/package/sdmApp)
[![GitHub Issues](https://img.shields.io/github/issues/Abson-dev/sdmApp.svg
)](https://github.com/Abson-dev/sdmApp/issues)
[![Discussion](https://img.shields.io/badge/chat-wechat-brightgreen?style=flat)](./README.md#disscussiongroup)
[![Download Count](https://img.shields.io/github/downloads/Abson-dev/sdmApp/total.svg?style=for-the-badge)](https://github.com/Abson-dev/sdmApp/releases)
<!--[![DOI](https://zenodo.org/badge/116337503.svg)](https://zenodo.org/badge/latestdoi/116337503) -->


sdmApp is a R package containing a shiny application that allows non-expert R users to easily model species distribution. It offers a reproducible workflow for species distribution modeling into a single and user friendly environment. sdmApp takes raster data (in format supported by the raster package) and species occurrence data (several format supported) as input argument. The sdmApp provides an interactive, graphical user interface (GUI). This document will give an overview of the main functionalities of the graphical user interface. The main features of the GUI is:

* Uploading data (raster and species occurrence files)
* View correlation between raster
* Use Climate Ecological Niche Factors Analysis ([CENFA](https://cran.r-project.org/web/packages/CENFA/index.html) to select species predictors
* Apply a spatial blocking for cross-validation (based on the [blockCV](https://cran.r-project.org/web/packages/blockCV/index.html) package)
* Apply species distribution models with or without a spatial blocking strategy 

* Export results
* Keep reproduce (R code) by being able do download the underlying code from sdmApp.

 The GUI is build around 6 main windows, which can be selected from the navigation bar at the top of the screen. Initially, some of these windows will be empty and their content changes once data (both raster and species occurrence files) have been uploaded.
 
 
 ## Installation
To install the package from GitHub use:

```r
remotes::install_github("Abson-dev/sdmApp", dependencies = TRUE)
```
Or installing from CRAN (not yet available on CRAN):

```r
#install.packages("sdmApp", dependencies = TRUE)
```

## Vignette
To see the vignette of the package use:

```r
browseVignettes("sdmApp")
```
The vignette is also available via this [link](https://github.com/Abson-dev/sdmApp/blob/master/sdmApp_github.md).


## Help file

The help file is also available via this [link](https://github.com/Abson-dev/sdmApp/blob/master/doc/sdm.html).

## License

The sdmApp sticker was made through R art kindly shared by [art.djnavarro.net](art.djnavarro.net) and released under a [CC-BY-SA 4.0](https://www.donneesquebec.ca/fr/licence/) license.


## Example

<img src="https://imgur.com/gallery/Hc0HW9t" style="display: block; margin: auto;" />

