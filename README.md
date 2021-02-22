# sdmApp <img src="inst/docs/Logo_sdmApp.png" align="right" width="120" />
 Species Distribution Models Application


# `sdmApp`: Statistical Details

| Package                                                                                                                                                         | Status                                                                                                                                                                                       | Usage                                                                                                                                             | GitHub                                                                                                                                                         | Miscellaneous                                                                                                                                                   |
  |-----------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | [![CRAN\_Release\_Badge](https://www.r-pkg.org/badges/version-ago/sdmApp)](https://CRAN.R-project.org/package=sdmApp)                                 | [![Travis Build Status](https://travis-ci.org/Abson-dev/sdmApp.svg?branch=master)](https://travis-ci.org/Abson-dev/sdmApp)                                               | [![Daily downloads badge](https://cranlogs.r-pkg.org/badges/last-day/sdmApp?color=blue)](https://CRAN.R-project.org/package=sdmApp)     | [![GitHub version](https://img.shields.io/badge/GitHub-0.0.2-orange.svg?style=flat-square)](https://github.com/Abson-dev/sdmApp/)               | [![Website](https://img.shields.io/badge/website-sdmApp-orange.svg?colorB=E91E63)](https://Abson-dev.github.io/sdmApp/)                          |
  | [![CRAN Checks](https://cranchecks.info/badges/summary/sdmApp)](https://cran.r-project.org/web/checks/check_results_sdmApp.html)                      | [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/Abson-dev/sdmApp?branch=master&svg=true)](https://ci.appveyor.com/project/Abson-dev/sdmApp) | [![Weekly downloads badge](https://cranlogs.r-pkg.org/badges/last-week/sdmApp?color=blue)](https://CRAN.R-project.org/package=sdmApp)   | [![Forks](https://img.shields.io/badge/forks-0-blue.svg)](https://github.com/Abson-dev/sdmApp/)                                                    | [![minimal R version](https://img.shields.io/badge/R%3E%3D-3.5.0-6666ff.svg)](https://cran.r-project.org/)                                                      |
  | [![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)                                                  | [![R build status](https://github.com/Abson-dev/sdmApp/workflows/R-CMD-check/badge.svg)](https://github.com/Abson-dev/sdmApp)                                            | [![Monthly downloads badge](https://cranlogs.r-pkg.org/badges/last-month/sdmApp?color=blue)](https://CRAN.R-project.org/package=sdmApp) | [![Github Issues](https://img.shields.io/badge/issues-1-red.svg)](https://github.com/Abson-dev/sdmApp/issues)                                       | [![vignettes](https://img.shields.io/badge/vignettes-0.0.1-orange.svg?colorB=FF5722)](https://github.com/Abson-dev/sdmApp)                   |
  | [![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/Abson-dev/sdmApp.svg)](https://github.com/Abson-dev/sdmApp) | [![Coverage Status](https://coveralls.io/repos/github/Abson-dev/sdmApp/badge.svg?branch=master)](https://coveralls.io/github/Abson-dev/sdmApp?branch=master)             | [![Total downloads badge](https://cranlogs.r-pkg.org/badges/grand-total/sdmApp?color=blue)](https://CRAN.R-project.org/package=sdmApp)  | [![Github Stars](https://img.shields.io/github/stars/Abson-dev/sdmApp.svg?style=social&label=Github)](https://github.com/Abson-dev/sdmApp) | [![DOI](https://zenodo.org/badge/DOI/10.1016/zenodo.107481.svg)](https://doi.org/https://doi.org/10.1016/j.ecolind.2021.107481)                                                       |
  | [![Licence](https://img.shields.io/badge/licence-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)                                                | [![Codecov test coverage](https://codecov.io/gh/Abson-dev/sdmApp/branch/master/graph/badge.svg)](https://codecov.io/gh/Abson-dev/sdmApp?branch=master)                   | [![HitCount](https://hits.dwyl.com/Abson-dev/sdmApp.svg)](https://hits.dwyl.com/Abson-dev/sdmApp)                             | [![Last-changedate](https://img.shields.io/badge/last%20change-2021--02--01-yellowgreen.svg)](https://github.com/Abson-dev/sdmApp/commits/master)    | [![GitHub last commit](https://img.shields.io/github/last-commit/Abson-dev/sdmApp.svg)](https://github.com/Abson-dev/sdmApp/commits/master) |
  | [![status](https://tinyverse.netlify.com/badge/sdmApp)](https://CRAN.R-project.org/package=sdmApp)                                                    | [![lints](https://github.com/Abson-dev/sdmApp/workflows/lint/badge.svg)](https://github.com/Abson-dev/sdmApp)                                                            | [![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://github.com/Abson-dev/sdmApp)                                           | [![Project Status](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)                                                   | [![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/Abson-dev/sdmApp/issues) |


*sdmApp* is a *R package* containing a *Shiny* application that allows non-expert *R* users to easily model species distribution. It offers a reproducible work flow for species distribution modeling into a single and user friendly environment. *sdmApp* takes *Raster* data (in format supported by the *Raster package*) and species occurrence data (several format supported) as input argument. This *package* provides an interactive graphical user interface (GUI).
 This document will give an overview of the main functionalities of the graphical user interface. The main features of the *GUI* is:

* Uploading data (*raster* and species occurrence files)
* View correlation between *raster*
* Use [CENFA](https://CRAN.R-project.org/package=CENFA) to select species predictors
* Apply a spatial blocking for cross-validation based on the [blockCV](https://CRAN.R-project.org/package=blockCV) package
* Apply species distribution models with or without a spatial blocking strategy 

* Export results
* Keep reproduce (*R* code) by being able do download the underlying code from *sdmApp*.

 The *GUI* is build around 5 main windows, which can be selected from the navigation bar at the top of the screen. Initially, some of these windows will be empty and their content changes once data (both *raster* and species occurrence files) have been uploaded.
 
 
 ## Installation
To install the *package* from *github* use:

```r
remotes::install_github("Abson-dev/sdmApp", dependencies = TRUE)
library(sdmApp)
sdmApp()
```
<img src="inst/docs/sdmApp.PNG" />


<img src="inst/docs/export1.PNG" />

<img src="inst/docs/export2.PNG" />

<img src="inst/docs/export3.PNG" />

<img src="inst/docs/export4.PNG" />


<img src="inst/docs/export5.PNG" />

<img src="inst/docs/export6.PNG" />


<img src="inst/docs/export7.PNG" />

<img src="inst/docs/export8.PNG" />


<img src="inst/docs/export9.PNG" />

<img src="inst/docs/export10.PNG" />

## License

The *sdmApp* sticker was made through *R* art kindly shared by this [link](https://art.djnavarro.net/) and released under a [CC-BY-SA 4.0](https://www.donneesquebec.ca/licence/) license.
