niakhar_raster <- function() {
  raster::raster(system.file("extdata", "bio1.tif", package = "sdmApp"))
}

niakhar_points <- function() {
  occ <- utils::read.csv2(system.file("extdata", "Niakhar.csv",
                                      package = "sdmApp"))
  pa <- sf::st_as_sf(occ, coords = c("X_WGS84", "Y_WGS84"), crs = 4326)
  pa["Faidherbia.albida"]
}

# A hand-made object shaped like blockCV >= 3.0 output, so the core logic is
# tested without depending on blockCV being installed.
fake_cv <- function(pa, k = 2, column = "Faidherbia.albida") {
  ids <- rep_len(seq_len(k), nrow(pa))
  folds <- lapply(seq_len(k), function(i) {
    list(which(ids != i), which(ids == i))
  })
  structure(list(folds_list = folds, column = column, k = k),
            class = "cv_spatial")
}

test_that("sdmApp_fold_Explorer works with a blockCV >= 3 style object", {
  r <- niakhar_raster()
  pa <- niakhar_points()

  p <- sdmApp_fold_Explorer(fake_cv(pa), r, pa, num = 1)
  expect_s3_class(p, "ggplot")
})

test_that("sdmApp_fold_Explorer works with a legacy SpatialBlock object", {
  r <- niakhar_raster()
  pa <- niakhar_points()
  cv <- fake_cv(pa)
  legacy <- structure(list(folds = cv$folds_list, species = NULL, k = 2),
                      class = "SpatialBlock")

  p <- sdmApp_fold_Explorer(legacy, r, pa, num = 2)
  expect_s3_class(p, "ggplot")
})

test_that("sdmApp_fold_Explorer accepts a terra SpatRaster background", {
  skip_if_not_installed("terra")
  r <- terra::rast(system.file("extdata", "bio1.tif", package = "sdmApp"))
  pa <- niakhar_points()

  p <- sdmApp_fold_Explorer(fake_cv(pa), r, pa, num = 1)
  expect_s3_class(p, "ggplot")
})

test_that("sdmApp_fold_Explorer validates its inputs", {
  r <- niakhar_raster()
  pa <- niakhar_points()
  cv <- fake_cv(pa, k = 2)

  expect_error(sdmApp_fold_Explorer(cv, NULL, pa, 1), "raster layer")
  expect_error(sdmApp_fold_Explorer(cv, 1:3, pa, 1), "Raster")
  expect_error(sdmApp_fold_Explorer(cv, r, NULL, 1), "Species data")
  expect_error(sdmApp_fold_Explorer(NULL, r, pa, 1), "blockCV")
  expect_error(sdmApp_fold_Explorer(list(a = 1), r, pa, 1), "folds")
  expect_error(sdmApp_fold_Explorer(cv, r, pa, 0), "between 1 and 2")
  expect_error(sdmApp_fold_Explorer(cv, r, pa, 3), "between 1 and 2")
  expect_error(sdmApp_fold_Explorer(cv, r, pa, 1.5), "whole number")
  expect_error(sdmApp_fold_Explorer(fake_cv(pa, column = "nope"), r, pa, 1),
               "'nope'")
})

test_that("sdmApp_fold_Explorer draws real blockCV::cv_spatial() folds", {
  skip_on_cran()
  skip_if_not_installed("blockCV", minimum_version = "3.0.0")
  r <- niakhar_raster()
  pa <- niakhar_points()

  cv <- suppressMessages(blockCV::cv_spatial(
    x = pa, column = "Faidherbia.albida", r = r, size = 2000, k = 3,
    iteration = 5, plot = FALSE, progress = FALSE, report = FALSE
  ))
  p <- sdmApp_fold_Explorer(cv, r, pa, num = 2)
  expect_s3_class(p, "ggplot")
})
