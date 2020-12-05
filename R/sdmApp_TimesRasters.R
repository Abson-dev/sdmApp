#' Times two rasters
#'
#' @param x Probability of occurence map, a \code{Raster object}
#' @param y Presence/Absence map, a \code{Raster object}
#'
#' @return Probability of occurence map with only presence
#' @export
#'
#' @examples
#' \dontrun{
#' r <- raster::raster(system.file("extdata","AETI.tif",package = "sdmApp"))
#' r2 <- r > 4000
#' z<-sdmApp_TimesRasters(r,r2)
#' sdmApp_RasterPlot(z)
#' }
sdmApp_TimesRasters<-function(x,y){
  z<-x * y
  names(z)<-names(x)
  return(z)
}
