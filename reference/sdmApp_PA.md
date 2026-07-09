# Plot a presence/absence map

Turns a binary (presence/absence) raster into a `ggplot` map, sampling
the layer on a regular grid so that large rasters can be displayed
quickly.

## Usage

``` r
sdmApp_PA(x)
```

## Arguments

- x:

  A
  [raster::RasterLayer](https://rdrr.io/pkg/raster/man/Raster-classes.html)
  object holding presence (`TRUE`, `1`) and absence (`FALSE`, `0`)
  values.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Author

Aboubacar HEMA

## Examples

``` r
r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
r <- r > 4000
sdmApp_PA(r)
```
