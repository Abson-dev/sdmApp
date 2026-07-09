# Mask a probability-of-occurrence map with a presence/absence map

Multiplies a probability-of-occurrence raster by a presence/absence
raster so that only cells predicted as presence keep their probability
value; absence cells become zero. The name of the first raster is
preserved on the result.

## Usage

``` r
sdmApp_TimesRasters(x, y)
```

## Arguments

- x:

  Probability-of-occurrence map, a
  [raster::RasterLayer](https://rdrr.io/pkg/raster/man/Raster-classes.html)
  object.

- y:

  Presence/absence map, a
  [raster::RasterLayer](https://rdrr.io/pkg/raster/man/Raster-classes.html)
  object with the same extent and resolution as `x`.

## Value

A
[raster::RasterLayer](https://rdrr.io/pkg/raster/man/Raster-classes.html)
object giving the probability of occurrence restricted to presence
cells.

## Author

Aboubacar HEMA

## Examples

``` r
r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
r2 <- r > raster::cellStats(r, stat = "mean", na.rm = TRUE)
r <- r / raster::maxValue(r)
names(r) <- "probability of occurrence"
z <- sdmApp_TimesRasters(r, r2)
sdmApp_RasterPlot(z)
```
