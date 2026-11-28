# Shared fixtures for the tests of the shiny interface.

app_dir <- function() {
  system.file("shiny", "sdmApp", package = "sdmApp")
}

# Source the interface helpers into a fresh environment.
app_helpers <- function() {
  env <- new.env()
  sys.source(file.path(app_dir(), "helpers.R"), envir = env)
  env
}

app_deps_available <- function(pkgs = c("terra", "dismo")) {
  all(vapply(pkgs, requireNamespace, logical(1), quietly = TRUE))
}

extdata <- function(...) {
  system.file("extdata", ..., package = "sdmApp")
}

# A small, fast data set: three predictors and a subsample of the Niakhar
# occurrences.
small_env <- function(h) {
  h$read_env_layers(extdata(c("bio1.tif", "bio12.tif", "Elev.tif")))
}

small_occ <- function(h, env, n = 600) {
  df <- h$read_occurrences(extdata("Niakhar.csv"), "text", sep = ";", dec = ",")
  set.seed(42)
  df <- df[sample(nrow(df), n), ]
  h$occ_as_sf(df, "X_WGS84", "Y_WGS84", "Faidherbia.albida", terra::crs(env))
}

# A ggplot is only fully evaluated when it is built: check that it draws.
expect_drawable <- function(p) {
  testthat::expect_s3_class(p, "ggplot")
  testthat::expect_no_error(ggplot2::ggplot_build(p))
}
