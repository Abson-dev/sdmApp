#' Explore spatial cross-validation folds
#'
#' Visualises the placement of a chosen fold and the distribution of the
#' species data across training and testing sets, on top of a background
#' raster. Useful for inspecting the folds produced by \pkg{blockCV}.
#'
#' Both the current \pkg{blockCV} interface (version 3.0 and later: objects
#' returned by `cv_spatial()`, `cv_cluster()`, `cv_buffer()`, `cv_nndm()`,
#' ...) and the legacy `SpatialBlock` objects returned by `spatialBlock()`
#' in \pkg{blockCV} < 3.0 are supported. When the object carries spatial
#' blocks (as `cv_spatial()` and `spatialBlock()` do), the blocks of the
#' selected fold are outlined in red.
#'
#' @param blocks A cross-validation object from \pkg{blockCV}: either a
#'   `cv_spatial` (or other `cv_*`) object, or a legacy `SpatialBlock`
#'   object.
#' @param rasterLayer A [raster::Raster-class] or [terra::SpatRaster-class]
#'   object used as the background map (only the first layer is drawn).
#' @param speciesData A simple features (`sf`) or `Spatial*` object holding
#'   the species data, in the same order as the data used to build
#'   `blocks`.
#' @param num Integer. Index of the fold to display as the test set, between
#'   1 and the number of folds.
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
#' @importFrom ggplot2 guides theme_bw labs ggtitle theme element_text .data
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("blockCV", quietly = TRUE) &&
#'     utils::packageVersion("blockCV") >= "3.0.0") {
#'   r <- raster::raster(system.file("extdata", "bio1.tif", package = "sdmApp"))
#'   occ <- utils::read.csv2(system.file("extdata", "Niakhar.csv",
#'                                       package = "sdmApp"))
#'   pa_data <- sf::st_as_sf(occ, coords = c("X_WGS84", "Y_WGS84"),
#'                           crs = 4326)
#'   pa_data <- pa_data["Faidherbia.albida"]
#'
#'   cv <- blockCV::cv_spatial(x = pa_data, column = "Faidherbia.albida",
#'                             r = r, size = 2000, k = 3, iteration = 20,
#'                             plot = FALSE, progress = FALSE,
#'                             report = FALSE)
#'   sdmApp_fold_Explorer(cv, r, pa_data, num = 1)
#' }
#' }
sdmApp_fold_Explorer <- function(blocks, rasterLayer, speciesData, num) {
  if (is.null(rasterLayer)) {
    stop("A raster layer should be provided.", call. = FALSE)
  }
  if (!.is_raster(rasterLayer)) {
    stop("'rasterLayer' must be a Raster* or SpatRaster object.",
         call. = FALSE)
  }
  if (is.null(speciesData)) {
    stop("Species data should be provided.", call. = FALSE)
  }
  if (is.null(blocks)) {
    stop("A blockCV cross-validation object is needed.", call. = FALSE)
  }

  cv <- .cv_parts(blocks)
  k <- length(cv$folds)

  num_ok <- is.numeric(num) && length(num) == 1L && !is.na(num) &&
    num == round(num) && num >= 1 && num <= k
  if (!num_ok) {
    stop("'num' must be a single whole number between 1 and ", k,
         " (the number of folds).", call. = FALSE)
  }

  speciesData <- sf::st_as_sf(speciesData)
  species <- cv$species
  if (!is.null(species)) {
    if (!species %in% names(speciesData)) {
      stop("Column '", species, "' used to build the folds was not found ",
           "in 'speciesData'.", call. = FALSE)
    }
    speciesData[[species]] <- as.factor(speciesData[[species]])
  }

  map_df <- .raster_to_df(rasterLayer)
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

  if (!is.null(cv$polygons)) {
    fold_poly <- cv$polygons[cv$polygons$folds == num, ]
    basePlot <- basePlot +
      ggplot2::geom_sf(data = fold_poly, color = "red",
                       fill = "orangered4", alpha = 0.04, linewidth = 0.2)
  }

  draw_points <- function(points, title) {
    if (is.null(species)) {
      layer <- ggplot2::geom_sf(data = points, alpha = 0.7, color = "blue",
                                size = 2)
    } else {
      layer <- list(
        ggplot2::geom_sf(data = points,
                         ggplot2::aes(color = .data[[species]]),
                         show.legend = "point", alpha = 0.7, size = 2),
        ggplot2::labs(color = species)
      )
    }
    basePlot + layer + ggplot2::ggtitle(title) + .title_theme()
  }

  fold <- cv$folds[[num]]
  ptr <- draw_points(speciesData[unlist(fold[1]), ], "Training set")
  pts <- draw_points(speciesData[unlist(fold[2]), ], "Testing set")

  cowplot::plot_grid(ptr, pts)
}

# Internal: pull folds, species column and (optional) block polygons out of
# a blockCV object, hiding the differences between blockCV versions.
#
# * blockCV >= 3.0 (`cv_spatial`, `cv_cluster`, `cv_buffer`, ...):
#   `$folds_list`, `$column`, and for `cv_spatial` an sf `$blocks`.
# * blockCV < 3.0 (`SpatialBlock`, `EnvironmentalBlock`, `BufferedBlock`):
#   `$folds`, `$species`, and for `SpatialBlock` an sp `$blocks`.
.cv_parts <- function(blocks) {
  if (!is.list(blocks)) {
    stop("'blocks' must be a cross-validation object from blockCV ",
         "(for example the output of blockCV::cv_spatial()).",
         call. = FALSE)
  }
  if (!is.null(blocks$folds_list)) {
    folds   <- blocks$folds_list
    species <- blocks$column
  } else if (!is.null(blocks$folds)) {
    folds   <- blocks$folds
    species <- blocks$species
  } else {
    stop("'blocks' does not contain any folds. Supply the output of ",
         "blockCV::cv_spatial() (or another blockCV cv_* function).",
         call. = FALSE)
  }

  polygons <- blocks$blocks
  if (!is.null(polygons)) {
    polygons <- sf::st_as_sf(polygons)
    if (!"folds" %in% names(polygons)) {
      polygons <- NULL
    }
  }

  list(folds = folds, species = species, polygons = polygons)
}
