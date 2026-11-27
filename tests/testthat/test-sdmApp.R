test_that("sdmApp validates the theme argument", {
  expect_error(sdmApp(theme = "not-a-theme"), "Invalid value")
  expect_error(sdmApp(theme = c("IHSN", "yeti")), "Invalid value")
})

test_that("sdmApp validates maxRequestSize", {
  expect_error(sdmApp(maxRequestSize = "big"), "positive numeric")
  expect_error(sdmApp(maxRequestSize = -5), "positive numeric")
  expect_error(sdmApp(maxRequestSize = c(10, 20)), "positive numeric")
})

test_that("sdmApp validates debug", {
  expect_error(sdmApp(debug = "yes"), "TRUE or FALSE")
})

test_that("missing suggested packages produce an actionable error", {
  local_mocked_bindings(
    requireNamespace = function(package, ...) package != "dismo",
    .package = "base"
  )
  expect_error(.sdmApp_check_deps(), "dismo")
  expect_error(.sdmApp_check_deps(), "install.packages")
})

test_that("the shiny app files ship with the package", {
  app_dir <- system.file("shiny", "sdmApp", package = "sdmApp")
  expect_true(all(file.exists(file.path(app_dir,
                                        c("global.R", "ui.R", "server.R")))))
})

test_that("the shiny app no longer calls functions removed from blockCV", {
  app_dir <- system.file("shiny", "sdmApp", package = "sdmApp")
  code <- unlist(lapply(
    list.files(app_dir, pattern = "[.]R$", recursive = TRUE,
               full.names = TRUE),
    readLines, warn = FALSE
  ))
  code <- code[!grepl("^[[:space:]]*#", code)]
  removed <- c("spatialBlock(", "spatialAutoRange(", "summarise_fold(")
  hits <- vapply(removed, function(f) any(grepl(f, code, fixed = TRUE)),
                 logical(1))
  expect_false(any(hits))
})
