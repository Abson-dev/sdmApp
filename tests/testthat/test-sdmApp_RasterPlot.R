test_that("sdmApp_RasterPlot returns a ggplot from a continuous raster", {
  skip_if_not_installed("raster")
  skip_if_not_installed("ggplot2")

  r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
  p <- sdmApp_RasterPlot(r)
  expect_s3_class(p, "ggplot")
})

test_that("sdmApp_RasterPlot returns NULL for a base graphics raster", {
  m <- matrix(c(0, 1, 0, 1), nrow = 2)
  expect_null(sdmApp_RasterPlot(grDevices::as.raster(m)))
})

test_that("sdmApp_RasterPlot accepts a terra SpatRaster", {
  skip_if_not_installed("terra")
  r <- terra::rast(system.file("extdata", "AETI.tif", package = "sdmApp"))
  p <- sdmApp_RasterPlot(r)
  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$title, "AETI")
})

test_that("sdmApp_RasterPlot rejects non-raster input", {
  expect_error(sdmApp_RasterPlot(1:10), "Raster")
})
