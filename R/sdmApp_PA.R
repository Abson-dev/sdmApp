#' Plot a presence/absence map
#'
#' Turns a binary (presence/absence) raster into a `ggplot` map, sampling
#' the layer on a regular grid so that large rasters can be displayed
#' quickly.
#'
#' @param x A [raster::RasterLayer-class] object holding presence (`TRUE`,
#'   `1`) and absence (`FALSE`, `0`) values.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @author Aboubacar HEMA
#'
#' @importFrom raster sampleRegular as.data.frame
#' @importFrom ggplot2 ggplot geom_raster aes theme_bw labs ggtitle theme
#'   element_text scale_fill_manual .data
#' @export
#'
#' @examples
#' r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
#' r <- r > 4000
#' sdmApp_PA(r)
sdmApp_PA <- function(x) {
  if (!inherits(x, "Raster")) {
    stop("'x' must be a Raster* object.", call. = FALSE)
  }

  samp <- raster::sampleRegular(x, 5e5, asRaster = TRUE)
  map_df <- raster::as.data.frame(samp, xy = TRUE, centroids = TRUE,
                                  na.rm = TRUE)
  colnames(map_df) <- c("Easting", "Northing", "MAP")
  map_df$MAP <- factor(map_df$MAP)

  ggplot2::ggplot(map_df) +
    ggplot2::geom_raster(
      ggplot2::aes(x = .data[["Easting"]], y = .data[["Northing"]],
                   fill = .data[["MAP"]])
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Longitude", y = "Latitude") +
    ggplot2::ggtitle(label = names(x)) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 10)
    ) +
    ggplot2::scale_fill_manual(
      values = c("red", "green"),
      name = "Specie",
      labels = c("Absence", "Presence")
    )
}
