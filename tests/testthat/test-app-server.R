# End-to-end test of the shiny server: loads data, runs the spatial
# analysis and fits a model, without a browser.

test_that("the shiny app runs a full analysis", {
  skip_on_cran()
  ok <- tryCatch(
    {
      sdmApp:::.sdmApp_check_deps()
      TRUE
    },
    error = function(e) FALSE
  )
  skip_if_not(ok, "Packages needed by the interface are not installed.")

  old <- options(shiny.maxRequestSize = NULL)
  on.exit(options(old), add = TRUE)
  app <- sdmApp(shiny.server = TRUE)
  h <- app_helpers()

  shiny::testServer(app, {
    # Before any data is loaded the analysis tabs ask for data.
    expect_false(has_data())
    expect_match(as.character(output$ui_Models$html), "No environmental")

    env_state$env <- small_env(h)
    env_state$paths <- extdata(c("bio1.tif", "bio12.tif", "Elev.tif"))
    occ_state$table <- h$read_occurrences(
      extdata("Niakhar.csv"), "text",
      sep = ";", dec = ","
    )[1:600, ]
    occ_state$path <- extdata("Niakhar.csv")
    occ_state$lon <- "X_WGS84"
    occ_state$lat <- "Y_WGS84"
    occ_state$species <- "Faidherbia.albida"
    session$setInputs(sep = ";", dec = ",", layer = "bio1")
    expect_true(has_data())

    # Every page renders.
    for (o in c("ui_import_data", "ui_preparation", "ui_Models", "ui_code")) {
      expect_type(output[[o]]$html, "character")
    }
    expect_s3_class(env_plot(), "ggplot")
    expect_match(paste(current_code(), collapse = "\n"), "terra::rast")

    # Spatial analysis.
    expect_equal(dim(cor_matrix()), c(3L, 3L))
    expect_gte(enfa()$n_factors, 1)
    session$setInputs(
      block_size = 3000, number_fold = 3, allocation_fold = "random",
      test_fold = 1, block_button = 1
    )
    expect_s3_class(spatial_state$blocks, "cv_spatial")

    # The menus switch pages.
    session$setInputs(btn_models_4 = 1)
    expect_identical(ui_state$models, "btn_models_4")

    # A model cross-validated on the spatial blocks.
    session$setInputs(
      `glm-predictors` = c("bio1", "bio12"), `glm-cv` = "spatial",
      `glm-k` = 3, `glm-map_type` = "presence_absence",
      `glm-evaluation_type` = "ROC"
    )
    session$setInputs(`glm-run` = 1)
    fit <- model_fits$glm()
    expect_length(fit$auc, 3)
    expect_identical(fit$predictors, c("bio1", "bio12"))
  })
})
