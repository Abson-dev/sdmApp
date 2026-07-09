# Explore spatial cross-validation folds

Visualises the placement of a chosen fold and the distribution of the
species data across training and testing sets, on top of a background
raster. Useful for inspecting the folds produced by blockCV.

## Usage

``` r
sdmApp_fold_Explorer(blocks, rasterLayer, speciesData, num)
```

## Arguments

- blocks:

  A `SpatialBlock` object (from blockCV).

- rasterLayer:

  A raster object used as the background map.

- speciesData:

  A simple features (`sf`) or `SpatialPoints` object holding the species
  data (the response variable).

- num:

  Integer. Index of the fold to display as the test set.

## Value

A combined plot (via
[`cowplot::plot_grid()`](https://wilkelab.org/cowplot/reference/plot_grid.html))
showing the training and testing sets for the selected fold.

## Author

Aboubacar HEMA

## Examples

``` r
if (FALSE) { # \dontrun{
library(blockCV)
awt <- raster::brick(system.file("extdata", "awt.grd", package = "blockCV"))
PA <- read.csv(system.file("extdata", "PA.csv", package = "blockCV"))
pa_data <- sf::st_as_sf(PA, coords = c("x", "y"), crs = raster::crs(awt))
sb <- spatialBlock(speciesData = pa_data, species = "Species",
                   rasterLayer = awt, theRange = 70000, k = 5,
                   selection = "random", iteration = 100)
sdmApp_fold_Explorer(sb, awt, pa_data, 1)
} # }
```
