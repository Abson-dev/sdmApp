#' Plot a presence/absence map
#'
#' Turns a binary (presence/absence) raster into a `ggplot` map, sampling
#' the layer on a regular grid so that large rasters can be displayed
#' quickly.
#'
#' @param x A [raster::RasterLayer-class] or [terra::SpatRaster-class]
#'   object holding presence (`TRUE`, `1`) and absence (`FALSE`, `0`)
#'   values. Only the first layer is drawn.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @author Aboubacar HEMA
#'
#' @importFrom raster sampleRegular as.data.frame
#' @importFrom ggplot2 ggplot geom_raster aes theme_bw labs ggtitle theme
#' @importFrom ggplot2 element_text scale_fill_manual .data
#' @export
#'
#' @examples
#' r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
#' r <- r > 4000
#' sdmApp_PA(r)
sdmApp_PA <- function(x) {
  if (!.is_raster(x)) {
    stop("'x' must be a Raster* or SpatRaster object.", call. = FALSE)
  }

  map_df <- .raster_to_df(x)
  values <- as.numeric(map_df$MAP)
  if (!all(values %in% c(0, 1))) {
    stop("'x' must only contain presence (1/TRUE) and absence (0/FALSE) ",
         "values.", call. = FALSE)
  }
  # Map values to labelled levels explicitly so that a raster holding only
  # presences (or only absences) still gets the right colour and label.
  map_df$MAP <- factor(values, levels = c(0, 1),
                       labels = c("Absence", "Presence"))

  ggplot2::ggplot(map_df) +
    ggplot2::geom_raster(
      ggplot2::aes(x = .data[["Easting"]], y = .data[["Northing"]],
                   fill = .data[["MAP"]])
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Longitude", y = "Latitude") +
    ggplot2::ggtitle(label = .layer_name(x)) +
    .title_theme() +
    ggplot2::scale_fill_manual(
      values = c(Absence = "red", Presence = "green"),
      name = "Species",
      drop = FALSE
    )
}
