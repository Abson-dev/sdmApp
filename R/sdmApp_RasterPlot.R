#' Plot a continuous raster
#'
#' Displays a continuous raster layer as a `ggplot` map using a terrain
#' colour ramp. The layer is sampled on a regular grid so that large
#' rasters render quickly.
#'
#' @param x A [raster::RasterLayer-class] or [terra::SpatRaster-class]
#'   object. Only the first layer is drawn.
#'
#' @return A [ggplot2::ggplot] object, or `NULL` if `x` is a base graphics
#'   raster (`grDevices::is.raster(x)` is `TRUE`).
#'
#' @author Aboubacar HEMA
#'
#' @importFrom raster sampleRegular as.data.frame
#' @importFrom grDevices is.raster terrain.colors
#' @importFrom ggplot2 ggplot geom_raster aes theme_bw labs ggtitle theme
#' @importFrom ggplot2 element_text scale_fill_gradientn .data
#' @export
#'
#' @examples
#' r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
#' sdmApp_RasterPlot(r)
sdmApp_RasterPlot <- function(x) {
  if (grDevices::is.raster(x)) {
    return(NULL)
  }
  if (!.is_raster(x)) {
    stop("'x' must be a Raster* or SpatRaster object.", call. = FALSE)
  }

  map_df <- .raster_to_df(x)

  ggplot2::ggplot(map_df) +
    ggplot2::geom_raster(
      ggplot2::aes(x = .data[["Easting"]], y = .data[["Northing"]],
                   fill = .data[["MAP"]])
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Longitude", y = "Latitude") +
    ggplot2::ggtitle(label = .layer_name(x)) +
    ggplot2::scale_fill_gradientn(
      name = " ",
      colours = rev(grDevices::terrain.colors(10))
    ) +
    .title_theme()
}
