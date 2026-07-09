test_that("sdmApp_TimesRasters masks probabilities by presence", {
  skip_if_not_installed("raster")

  r <- raster::raster(system.file("extdata", "AETI.tif", package = "sdmApp"))
  pa <- r > raster::cellStats(r, stat = "mean", na.rm = TRUE)
  prob <- r / raster::maxValue(r)
  names(prob) <- "probability of occurrence"

  z <- sdmApp_TimesRasters(prob, pa)

  expect_s4_class(z, "RasterLayer")
  expect_identical(names(z), names(prob))
  # absence cells (pa == 0) must be zero in the masked output
  masked <- raster::values(z)[raster::values(pa) == 0]
  expect_true(all(masked == 0 | is.na(masked)))
})

test_that("sdmApp_TimesRasters rejects non-raster input", {
  expect_error(sdmApp_TimesRasters(1, 2), "Raster")
})
