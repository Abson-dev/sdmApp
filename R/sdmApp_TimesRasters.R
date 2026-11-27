#' Mask a probability-of-occurrence map with a presence/absence map
#'
#' Multiplies a probability-of-occurrence raster by a presence/absence
#' raster so that only cells predicted as presence keep their probability
#' value; absence cells become zero. The name of the first raster is
#' preserved on the result.
#'
#' @param x Probability-of-occurrence map, a [raster::RasterLayer-class]
#'   object.
#' @param y Presence/absence map, a [raster::RasterLayer-class] object with
#'   the same extent, resolution and coordinate reference system as `x`.
#'   Two [terra::SpatRaster-class] objects are also accepted.
#'
#' @return A [raster::RasterLayer-class] object giving the
#'   probability of occurrence restricted to presence cells.
#'
#' @author Aboubacar HEMA
#'
#' @export
#'
#' @examples
#' r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
#' r2 <- r > raster::cellStats(r, stat = "mean", na.rm = TRUE)
#' r <- r / raster::maxValue(r)
#' names(r) <- "probability of occurrence"
#' z <- sdmApp_TimesRasters(r, r2)
#' sdmApp_RasterPlot(z)
sdmApp_TimesRasters <- function(x, y) {
  both_raster <- inherits(x, "Raster") && inherits(y, "Raster")
  both_terra  <- inherits(x, "SpatRaster") && inherits(y, "SpatRaster")
  if (!both_raster && !both_terra) {
    stop("'x' and 'y' must both be Raster* objects (or both SpatRaster ",
         "objects).", call. = FALSE)
  }
  same_geometry <- !both_raster ||
    isTRUE(raster::compareRaster(x, y, stopiffalse = FALSE))
  if (!same_geometry) {
    stop("'x' and 'y' must have the same extent, resolution and ",
         "coordinate reference system.", call. = FALSE)
  }
  z <- x * y
  names(z) <- names(x)
  z
}
