# Plot a continuous raster

Displays a continuous raster layer as a `ggplot` map using a terrain
colour ramp. The layer is sampled on a regular grid so that large
rasters render quickly.

## Usage

``` r
sdmApp_RasterPlot(x)
```

## Arguments

- x:

  A
  [raster::RasterLayer](https://rdrr.io/pkg/raster/man/Raster-classes.html)
  object.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object, or `NULL` if `x` is a base graphics raster
(`grDevices::is.raster(x)` is `TRUE`).

## Author

Aboubacar HEMA

## Examples

``` r
r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
sdmApp_RasterPlot(r)
```
