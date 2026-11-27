test_that("sdmApp_PA returns a ggplot from a binary raster", {
  skip_if_not_installed("raster")
  skip_if_not_installed("ggplot2")

  r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
  pa <- r > 4000

  p <- sdmApp_PA(pa)
  expect_s3_class(p, "ggplot")
})

test_that("sdmApp_PA rejects non-raster input", {
  expect_error(sdmApp_PA(1:10), "Raster")
})

test_that("sdmApp_PA labels a presence-only raster as presence", {
  r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
  all_presence <- r > -Inf

  p <- sdmApp_PA(all_presence)
  expect_identical(levels(p$data$MAP), c("Absence", "Presence"))
  expect_true(all(p$data$MAP == "Presence"))
})

test_that("sdmApp_PA rejects non-binary rasters", {
  r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
  expect_error(sdmApp_PA(r), "presence")
})

test_that("sdmApp_PA accepts a terra SpatRaster", {
  skip_if_not_installed("terra")
  r <- terra::rast(system.file("extdata", "AETI.tif", package = "sdmApp"))
  expect_s3_class(sdmApp_PA(r > 4000), "ggplot")
})
