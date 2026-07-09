test_that("sdmApp validates the theme argument", {
  expect_error(sdmApp(theme = "not-a-theme"), "Invalid value")
})

test_that("sdmApp validates maxRequestSize", {
  expect_error(sdmApp(maxRequestSize = "big"), "numeric")
})
