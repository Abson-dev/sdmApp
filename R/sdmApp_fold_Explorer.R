#' Explore spatial cross-validation folds
#'
#' Visualises the placement of a chosen fold and the distribution of the
#' species data across training and testing sets, on top of a background
#' raster. Useful for inspecting the folds produced by \pkg{blockCV}.
#'
#' @param blocks A `SpatialBlock` object (from \pkg{blockCV}).
#' @param rasterLayer A raster object used as the background map.
#' @param speciesData A simple features (`sf`) or `SpatialPoints` object
#'   holding the species data (the response variable).
#' @param num Integer. Index of the fold to display as the test set.
#'
#' @return A combined plot (via [cowplot::plot_grid()]) showing the
#'   training and testing sets for the selected fold.
#'
#' @author Aboubacar HEMA
#'
#' @importFrom raster sampleRegular as.data.frame
#' @importFrom sf st_as_sf
#' @importFrom stats median
#' @importFrom cowplot plot_grid
#' @importFrom ggplot2 ggplot geom_raster geom_sf aes scale_fill_gradient2
#'   guides theme_bw labs ggtitle theme element_text .data
#' @export
#'
#' @examples
#' \dontrun{
#' library(blockCV)
#' awt <- raster::brick(system.file("extdata", "awt.grd", package = "blockCV"))
#' PA <- read.csv(system.file("extdata", "PA.csv", package = "blockCV"))
#' pa_data <- sf::st_as_sf(PA, coords = c("x", "y"), crs = raster::crs(awt))
#' sb <- spatialBlock(speciesData = pa_data, species = "Species",
#'                    rasterLayer = awt, theRange = 70000, k = 5,
#'                    selection = "random", iteration = 100)
#' sdmApp_fold_Explorer(sb, awt, pa_data, 1)
#' }
sdmApp_fold_Explorer <- function(blocks, rasterLayer, speciesData, num) {
  if (is.null(rasterLayer)) {
    stop("A raster layer should be provided.", call. = FALSE)
  }
  if (is.null(speciesData)) {
    stop("Species data should be provided.", call. = FALSE)
  }
  if (is.null(blocks)) {
    stop("An object of class 'SpatialBlock' is needed.", call. = FALSE)
  }

  is_spatial_block <- inherits(blocks, "SpatialBlock")
  polyObj <- if (is_spatial_block) blocks$blocks else NULL

  if (num < 0 || num > length(blocks$folds)) {
    stop("The 'num' parameter is out of range.", call. = FALSE)
  }

  folds   <- blocks$folds
  species <- blocks$species

  speciesData <- sf::st_as_sf(speciesData)
  speciesData[[1]] <- as.factor(speciesData[[1]])

  samp <- raster::sampleRegular(rasterLayer[[1]], 5e5, asRaster = TRUE)
  map_df <- raster::as.data.frame(samp, xy = TRUE, centroids = TRUE,
                                  na.rm = TRUE)
  colnames(map_df) <- c("Easting", "Northing", "MAP")
  mid <- stats::median(map_df$MAP)

  basePlot <- ggplot2::ggplot() +
    ggplot2::geom_raster(
      data = map_df,
      ggplot2::aes(x = .data[["Easting"]], y = .data[["Northing"]],
                   fill = .data[["MAP"]])
    ) +
    ggplot2::scale_fill_gradient2(low = "darkred", mid = "yellow",
                                  high = "darkgreen", midpoint = mid) +
    ggplot2::guides(fill = "none") +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "", y = "")

  trainSet <- unlist(folds[[num]][1])
  testSet  <- unlist(folds[[num]][2])
  training <- speciesData[trainSet, ]
  testing  <- speciesData[testSet, ]

  add_poly <- function(p) {
    if (!is_spatial_block) {
      return(p)
    }
    plotPoly <- sf::st_as_sf(polyObj[polyObj$folds == num, ])
    p + ggplot2::geom_sf(data = plotPoly, color = "red",
                         fill = "orangered4", alpha = 0.04, size = 0.2)
  }

  title_theme <- ggplot2::theme(
    plot.title = ggplot2::element_text(hjust = 0.5, size = 10)
  )

  if (is.null(species)) {
    ptr <- add_poly(basePlot) +
      ggplot2::geom_sf(data = training, alpha = 0.7, color = "blue",
                       size = 2) +
      ggplot2::ggtitle("Training set") + title_theme
    pts <- add_poly(basePlot) +
      ggplot2::geom_sf(data = testing, alpha = 0.7, color = "blue",
                       size = 2) +
      ggplot2::ggtitle("Testing set") + title_theme
  } else {
    ptr <- add_poly(basePlot) +
      ggplot2::geom_sf(data = training,
                       ggplot2::aes(color = .data[[species]]),
                       show.legend = "point", alpha = 0.7, size = 2) +
      ggplot2::labs(color = species) +
      ggplot2::ggtitle("Training set") + title_theme
    pts <- add_poly(basePlot) +
      ggplot2::geom_sf(data = testing,
                       ggplot2::aes(color = .data[[species]]),
                       show.legend = "point", alpha = 0.7, size = 2) +
      ggplot2::labs(color = species) +
      ggplot2::ggtitle("Testing set") + title_theme
  }

  cowplot::plot_grid(ptr, pts)
}
