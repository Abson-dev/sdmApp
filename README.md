# sdmApp <img src="/doc/Logo_sdmApp.png" align="right" width="120" />
 Species Distribution Models Application

<!--[![Build Status](https://travis-ci.org/rvalavi/blockCV.svg?branch=master)](https://travis-ci.org/rvalavi/blockCV)-->
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/rvalavi/blockCV?branch=master&svg=true)](https://github.com/Abson-dev/sdmApp/commits/master/sdmApp_github.md)
[![License](https://img.shields.io/badge/license-GPL%20%28%3E=%203%29-lightgrey.svg?style=flat)](http://www.gnu.org/licenses/gpl-3.0.html)
[![CRAN version](https://www.r-pkg.org/badges/version/sdmApp)](https://CRAN.R-project.org/package=sdmApp)
<!--[![CRAN\_Download\_Badge](http://cranlogs.r-pkg.org/badges/sdmApp)](https://CRAN.R-project.org/package=sdmApp)-->
<!--[![codecov](https://codecov.io/gh/rvalavi/blockCV/branch/master/graph/badge.svg)](https://codecov.io/gh/rvalavi/blockCV)
[![CRAN version](https://www.r-pkg.org/badges/version/blockCV)](https://CRAN.R-project.org/package=blockCV)
[![total](http://cranlogs.r-pkg.org/badges/grand-total/blockCV)](https://www.rpackages.io/package/blockCV) -->
<!--[![DOI](https://zenodo.org/badge/116337503.svg)](https://zenodo.org/badge/latestdoi/116337503) -->


sdmApp is a R package containing a shiny application that allows non-expert R users to easily model species distribution. It offers a reproducible worklow for species distribution modelling into a single and user friendly environment. sdmApp takes raster data (in format supported by the raster package) and species occurrence data (several format supported) as input argument. The sdmApp provides an interactive, graphical user interface (GUI). This document will give an overview of the main functionalities of the graphical user interface. The main features of the GUI is:

* Uploading data (raster and species occurence files)
* View correlation between raster
* Use Climate Ecological Niche Factors Analysis (CENFA) to select species predictors
* Apply a spatial blocking for cross-validation (based on the blockCV package)
* Apply species distribution models with or without a spatial blocking strategy 

* Export results
* Keep reproducibility (R code) by being able do download the underlying code from sdmApp.

 The GUI is build around 6 main windows, which can be selected from the navigation bar at the top of the screen. Initially, some of these windows will be empty and their content changes once data (both raster and species occurence files) have been uploaded.
 
 
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

The sdmApp sticker was made through R art kindly shared by [art.djnavarro.net](art.djnavarro.net) and released under a [CC-BY-SA 4.0](https://www.donneesquebec.ca/fr/licence/) licence.

## Citation
To cite package **sdmApp** in publications, please use:

[Aboubacar H](https://orcid.org/0000-0001-9756-7270), [Babacar N](https://orcid.org/0000-0001-9848-7459), [Louise L](https://orcid.org/0000-0002-7631-2399), [Abdoul Aziz D](https://orcid.org/0000-0002-2918-6211). **sdmApp package: A user-friendly application for species distribution modelling**. *Methods Ecol Evol*. 2019; 10:225–232. [lien de l'article à ajouter](https://doi.org/10.1111/2041-210X.13107)
