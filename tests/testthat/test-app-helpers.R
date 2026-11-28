test_that("environmental layers are read into a named SpatRaster", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()

  env <- small_env(h)
  expect_s4_class(env, "SpatRaster")
  expect_identical(names(env), c("bio1", "bio12", "Elev"))
  expect_error(h$read_env_layers(character()), "No raster")
})

test_that("layers with a different geometry are aligned on the first one", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()
  coarse <- terra::aggregate(terra::rast(extdata("bio12.tif")), 3)
  path <- tempfile(fileext = ".tif")
  terra::writeRaster(coarse, path)

  env <- h$read_env_layers(c(extdata("bio1.tif"), path))
  expect_true(terra::compareGeom(env[[1]], env[[2]]))
})

test_that("categorical layers become factors", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()
  env <- h$read_env_layers(extdata(c("bio1.tif", "Elev.tif")),
    categorical = "Elev"
  )
  expect_true(terra::is.factor(env)[[2]])
  expect_false(terra::is.factor(env)[[1]])
  expect_drawable(h$plot_env_layer(env[["Elev"]]))
})

test_that("occurrence files are read with syntactic column names", {
  h <- app_helpers()
  df <- h$read_occurrences(extdata("Niakhar.csv"), "text", sep = ";", dec = ",")
  expect_true("Faidherbia.albida" %in% names(df))
  expect_type(df$X_WGS84, "double")

  skip_if_not_installed("readxl")
  xl <- h$read_occurrences(extdata("Niakhar.xlsx"), "Excel")
  expect_equal(nrow(xl), nrow(df))
})

test_that("the occurrence file type is inferred from the extension", {
  h <- app_helpers()
  expect_identical(h$occurrence_type("a/b.CSV"), "text")
  expect_identical(h$occurrence_type("b.xlsx"), "Excel")
  expect_identical(h$occurrence_type("b.sav"), "SPSS")
  expect_identical(h$occurrence_type("b.dta"), "Stata")
  expect_identical(h$occurrence_type("b.sas7bdat"), "SAS")
  expect_error(h$occurrence_type("b.json"), "Unsupported")
})

test_that("occ_as_sf validates columns and presence/absence values", {
  h <- app_helpers()
  df <- data.frame(x = c(1, 2, NA), y = c(1, 2, 3), sp = c(1, 0, 1))

  occ <- h$occ_as_sf(df, "x", "y", "sp", 4326)
  expect_s3_class(occ, "sf")
  expect_equal(nrow(occ), 2) # the row with a missing coordinate is dropped
  expect_error(h$occ_as_sf(df, "x", "y", "nope", 4326), "'nope'")
  df$sp <- c(1, 2, 0)
  expect_error(h$occ_as_sf(df, "x", "y", "sp", 4326), "0")
})

test_that("summaries describe the loaded data", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()
  env <- small_env(h)

  s <- h$env_summary(env)
  expect_identical(s$Layer, names(env))
  expect_true(all(s$Minimum <= s$Maximum))
  expect_match(h$env_description(env), "3 layer")

  o <- h$occ_summary(data.frame(a = c(1, 2, NA), b = c("x", "y", "y")))
  expect_equal(o$Missing, c(1L, 0L))
  expect_true(is.na(o$Minimum[2]))
})

test_that("correlation is computed between layers", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()
  m <- h$correlation_matrix(small_env(h))
  expect_equal(dim(m), c(3L, 3L))
  expect_equal(unname(diag(m)), c(1, 1, 1))
})

test_that("fit_sdm_kfold fits, evaluates and maps a model", {
  skip_if_not(app_deps_available(c("terra", "dismo")))
  h <- app_helpers()
  env <- small_env(h)
  occ <- small_occ(h, env)

  fit <- h$fit_sdm_kfold("glm", env, occ, "Faidherbia.albida", k = 3)
  expect_length(fit$auc, 3)
  expect_true(all(fit$auc >= 0 & fit$auc <= 1))
  expect_s3_class(fit$model, "glm")
  expect_s4_class(fit$prediction, "SpatRaster")

  # GLM predictions are probabilities, not log-odds.
  rng <- terra::minmax(fit$prediction)
  expect_true(rng[1] >= 0 && rng[2] <= 1)

  # Absence cells of the presence/absence map are zero in the masked map.
  pa <- terra::values(fit$presence_absence)
  masked <- terra::values(fit$presence_probability)
  expect_true(all(masked[pa == 0 & !is.na(pa)] == 0))

  expect_drawable(h$plot_sdm_map(fit, "presence_absence"))
  expect_drawable(h$plot_response_curves(fit))
  expect_null(h$plot_variable_importance(fit))
})

test_that("the cross-validation folds keep training and test data apart", {
  skip_if_not(app_deps_available(c("terra", "dismo")))
  h <- app_helpers()
  env <- small_env(h)
  occ <- small_occ(h, env)

  # Fold ids given explicitly (as spatial blocking does) are honoured.
  ids <- rep_len(1:2, nrow(occ))
  fit <- h$fit_sdm_kfold("bioclim", env, occ, "Faidherbia.albida",
    fold_ids = ids
  )
  expect_length(fit$auc, 2)
  expect_error(
    h$fit_sdm_kfold("bioclim", env, occ, "Faidherbia.albida", fold_ids = 1:3),
    "one entry per occurrence"
  )
})

test_that("every modelling method can be fitted", {
  skip_on_cran()
  methods <- c(
    bioclim = "dismo", domain = "dismo", mahal = "dismo",
    rf = "randomForest", svm = "kernlab", maxent = "rJava"
  )
  h <- app_helpers()
  skip_if_not(app_deps_available(c("terra", "dismo")))
  env <- small_env(h)
  occ <- small_occ(h, env, n = 300)

  for (m in names(methods)) {
    if (!requireNamespace(methods[[m]], quietly = TRUE)) next
    fit <- tryCatch(
      h$fit_sdm_kfold(m, env, occ, "Faidherbia.albida", k = 2),
      error = function(e) {
        # MaxEnt also needs a working Java installation.
        if (m == "maxent") {
          skip(paste("MaxEnt unavailable:", conditionMessage(e)))
        }
        stop(e)
      }
    )
    expect_s4_class(fit$prediction, "SpatRaster")
    if (m %in% c("rf", "maxent")) {
      expect_drawable(h$plot_variable_importance(fit))
    }
  }
})

test_that("style_plot applies the aesthetics options", {
  skip_if_not(app_deps_available("terra"))
  h <- app_helpers()
  p <- h$plot_env_layer(small_env(h)[["bio1"]])

  styled <- h$style_plot(p, list(
    theme = "minimal", add_title = TRUE, title = "My title",
    label_axes = TRUE, lab_x = "X", lab_y = "Y",
    adj_leg = "Remove legend"
  ))
  expect_drawable(styled)
  expect_identical(styled$labels$title, "My title")
  expect_identical(styled$labels$x, "X")
  expect_identical(styled$theme$legend.position, "none")
})

test_that("save_plot writes png and pdf files", {
  h <- app_helpers()
  png_file <- h$save_plot(tempfile(fileext = ".png"), function() plot(1:3))
  pdf_file <- h$save_plot(tempfile(fileext = ".pdf"), function() plot(1:3),
    type = "pdf"
  )
  expect_gt(file.size(png_file), 0)
  expect_gt(file.size(pdf_file), 0)
})
