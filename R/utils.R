# Internal helpers shared by the mapping functions. Not exported.

# Is `x` a raster we know how to draw? Accepts raster's Raster* classes and
# terra's SpatRaster.
.is_raster <- function(x) {
  inherits(x, c("Raster", "SpatRaster"))
}

# Turn the first layer of a raster into a data frame with columns
# Easting, Northing and MAP, sampling at most `size` cells on a regular grid
# so that large rasters stay quick to plot.
.raster_to_df <- function(x, size = 5e5) {
  if (inherits(x, "SpatRaster")) {
    x <- raster::raster(x[[1]])
  } else if (raster::nlayers(x) > 1L) {
    x <- x[[1]]
  }
  samp <- raster::sampleRegular(x, size, asRaster = TRUE)
  map_df <- raster::as.data.frame(samp, xy = TRUE, centroids = TRUE,
                                  na.rm = TRUE)
  colnames(map_df) <- c("Easting", "Northing", "MAP")
  map_df
}

# Name of the first layer, for plot titles.
.layer_name <- function(x) {
  names(x)[1]
}

.title_theme <- function() {
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 10))
}
