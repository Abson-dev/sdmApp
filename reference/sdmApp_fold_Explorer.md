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

  A cross-validation object from blockCV: either a `cv_spatial` (or
  other `cv_*`) object, or a legacy `SpatialBlock` object.

- rasterLayer:

  A [raster::Raster](https://rdrr.io/pkg/raster/man/Raster-classes.html)
  or
  [terra::SpatRaster](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  object used as the background map (only the first layer is drawn).

- speciesData:

  A simple features (`sf`) or `Spatial*` object holding the species
  data, in the same order as the data used to build `blocks`.

- num:

  Integer. Index of the fold to display as the test set, between 1 and
  the number of folds.

## Value

A combined plot (via
[`cowplot::plot_grid()`](https://wilkelab.org/cowplot/reference/plot_grid.html))
showing the training and testing sets for the selected fold.

## Details

Both the current blockCV interface (version 3.0 and later: objects
returned by `cv_spatial()`, `cv_cluster()`, `cv_buffer()`, `cv_nndm()`,
...) and the legacy `SpatialBlock` objects returned by `spatialBlock()`
in blockCV \< 3.0 are supported. When the object carries spatial blocks
(as `cv_spatial()` and `spatialBlock()` do), the blocks of the selected
fold are outlined in red.

## Author

Aboubacar HEMA

## Examples

``` r
# \donttest{
if (requireNamespace("blockCV", quietly = TRUE) &&
    utils::packageVersion("blockCV") >= "3.0.0") {
  r <- raster::raster(system.file("extdata", "bio1.tif", package = "sdmApp"))
  occ <- utils::read.csv2(system.file("extdata", "Niakhar.csv",
                                      package = "sdmApp"))
  pa_data <- sf::st_as_sf(occ, coords = c("X_WGS84", "Y_WGS84"),
                          crs = 4326)
  pa_data <- pa_data["Faidherbia.albida"]

  cv <- blockCV::cv_spatial(x = pa_data, column = "Faidherbia.albida",
                            r = r, size = 2000, k = 3, iteration = 20,
                            plot = FALSE, progress = FALSE,
                            report = FALSE)
  sdmApp_fold_Explorer(cv, r, pa_data, num = 1)
}

# }
```
