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
