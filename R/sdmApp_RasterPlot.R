#' Plot a continuous raster
#'
#' Displays a continuous raster layer as a `ggplot` map using a terrain
#' colour ramp. The layer is sampled on a regular grid so that large
#' rasters render quickly.
#'
#' @param x A [raster::RasterLayer-class] object.
#'
#' @return A [ggplot2::ggplot] object, or `NULL` if `x` is a base graphics
#'   raster (`grDevices::is.raster(x)` is `TRUE`).
#'
#' @author Aboubacar HEMA
#'
#' @importFrom raster sampleRegular as.data.frame
#' @importFrom grDevices is.raster terrain.colors
#' @importFrom ggplot2 ggplot geom_raster aes theme_bw labs ggtitle theme
#'   element_text scale_fill_gradientn .data
#' @export
#'
#' @examples
#' r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
#' sdmApp_RasterPlot(r)
sdmApp_RasterPlot <- function(x) {
  if (grDevices::is.raster(x)) {
    return(NULL)
  }
  if (!inherits(x, "Raster")) {
    stop("'x' must be a Raster* object.", call. = FALSE)
  }

  samp <- raster::sampleRegular(x, 5e5, asRaster = TRUE)
  map_df <- raster::as.data.frame(samp, xy = TRUE, centroids = TRUE,
                                  na.rm = TRUE)
  colnames(map_df) <- c("Easting", "Northing", "MAP")

  ggplot2::ggplot(map_df) +
    ggplot2::geom_raster(
      ggplot2::aes(x = .data[["Easting"]], y = .data[["Northing"]],
                   fill = .data[["MAP"]])
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Longitude", y = "Latitude") +
    ggplot2::ggtitle(label = names(x)) +
    ggplot2::scale_fill_gradientn(
      name = " ",
      colours = rev(grDevices::terrain.colors(10))
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 10)
    )
}
