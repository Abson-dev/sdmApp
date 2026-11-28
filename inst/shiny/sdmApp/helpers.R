# Pure helper functions used by the sdmApp shiny interface.
#
# Everything here works on terra (SpatRaster) and sf objects and has no
# dependency on shiny, so it can be unit tested from tests/testthat. The
# only place that still converts to raster/sp is env_as_raster() and
# presence_as_spatial(), because the CENFA package only accepts those
# classes.

# The tidy-evaluation pronoun used inside ggplot2::aes(). Binding it here
# lets static checkers see it; aes() still treats the bare `.data` symbol as
# the pronoun.
.data <- ggplot2::.data

# Modelling methods offered by the interface ---------------------------------

sdm_methods <- function() {
  data.frame(
    id = c("bioclim", "domain", "mahal", "glm", "maxent", "rf", "svm"),
    label = c(
      "Bioclim", "Domain", "Mahalanobis distance",
      "Generalized Linear Models", "MaxEnt", "Random Forest",
      "Support Vector Machines"
    ),
    group = c(
      "Profile models", "Profile models", "Profile models",
      "Classical regression models", "Machine learning models",
      "Machine learning models", "Machine learning models"
    ),
    importance = c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )
}

sdm_method_label <- function(method) {
  m <- sdm_methods()
  m$label[match(method, m$id)]
}

# Reading data ---------------------------------------------------------------

raster_file_types <- function() {
  c("tif", "tiff", "grd", "asc", "sdat", "rst", "nc", "envi", "bil", "img")
}

occurrence_file_types <- function() {
  c(
    text = "csv", text = "txt", Excel = "xlsx", Excel = "xls",
    SPSS = "sav", SPSS = "zsav", SPSS = "por", Stata = "dta",
    SAS = "sas7bdat"
  )
}

# File type ("text", "Excel", "SPSS", "Stata" or "SAS") from the extension.
occurrence_type <- function(path) {
  ext <- tolower(tools::file_ext(path))
  types <- occurrence_file_types()
  type <- names(types)[match(ext, types)]
  if (is.na(type)) {
    stop("Unsupported occurrence file extension: '.", ext, "'.",
      call. = FALSE
    )
  }
  type
}

# Read raster layers into a single SpatRaster. Layers that do not share the
# geometry of the first one are resampled onto it (nearest neighbour for
# categorical layers, bilinear otherwise). Layer names are the file names
# without extension.
read_env_layers <- function(paths, categorical = character()) {
  if (length(paths) == 0L) {
    stop("No raster file selected.", call. = FALSE)
  }
  layer_names <- tools::file_path_sans_ext(basename(paths))
  layers <- lapply(seq_along(paths), function(i) {
    r <- terra::rast(paths[[i]])[[1]]
    names(r) <- layer_names[[i]]
    r
  })
  ref <- layers[[1]]
  layers <- lapply(layers, function(r) {
    is_cat <- names(r) %in% categorical
    if (!terra::compareGeom(ref, r, stopOnError = FALSE)) {
      method <- if (is_cat) "near" else "bilinear"
      if (!terra::same.crs(ref, r)) {
        r <- terra::project(r, ref, method = method)
      } else {
        r <- terra::resample(r, ref, method = method)
      }
    }
    if (is_cat) {
      r <- terra::as.factor(r)
    }
    r
  })
  terra::rast(layers)
}

# Read an occurrence table in one of the supported formats.
read_occurrences <- function(path, type, sep = ";", dec = ",") {
  out <- switch(type,
    text = utils::read.table(path,
      header = TRUE, sep = sep, dec = dec,
      stringsAsFactors = FALSE, check.names = TRUE
    ),
    Excel = readxl::read_excel(path, .name_repair = "universal_quiet"),
    SPSS = haven::read_sav(path),
    Stata = haven::read_dta(path),
    SAS = haven::read_sas(path),
    stop("Unknown occurrence file type: ", type, call. = FALSE)
  )
  as.data.frame(out)
}

# Turn an occurrence table into an sf point layer holding a single numeric
# presence (1) / absence (0) column named after `species`.
occ_as_sf <- function(df, lon, lat, species, crs) {
  for (col in c(lon, lat, species)) {
    if (!col %in% names(df)) {
      stop("Column '", col, "' not found in the occurrence data.",
        call. = FALSE
      )
    }
  }
  pa <- suppressWarnings(as.numeric(as.character(df[[species]])))
  if (!all(pa[!is.na(pa)] %in% c(0, 1))) {
    stop("The species column '", species, "' must only contain 0 ",
      "(absence) and 1 (presence).",
      call. = FALSE
    )
  }
  out <- data.frame(
    lon = suppressWarnings(as.numeric(as.character(df[[lon]]))),
    lat = suppressWarnings(as.numeric(as.character(df[[lat]]))),
    pa = pa
  )
  out <- out[stats::complete.cases(out), , drop = FALSE]
  names(out)[3] <- species
  sf::st_as_sf(out, coords = c("lon", "lat"), crs = crs)
}

# Summaries ------------------------------------------------------------------

env_summary <- function(env) {
  mm <- terra::minmax(env, compute = TRUE)
  data.frame(
    Layer = names(env),
    Minimum = as.numeric(mm[1, ]),
    Maximum = as.numeric(mm[2, ]),
    check.names = FALSE
  )
}

env_description <- function(env) {
  e <- as.vector(terra::ext(env))
  sprintf(
    "%d layer(s). Extent: xmin = %s, xmax = %s, ymin = %s, ymax = %s.",
    terra::nlyr(env), signif(e[["xmin"]], 6), signif(e[["xmax"]], 6),
    signif(e[["ymin"]], 6), signif(e[["ymax"]], 6)
  )
}

occ_summary <- function(df) {
  data.frame(
    Variable = names(df),
    Type = vapply(df, function(x) class(x)[1], character(1)),
    Levels = vapply(df, function(x) length(unique(x)), integer(1)),
    Missing = vapply(df, function(x) sum(is.na(x)), integer(1)),
    Minimum = vapply(df, function(x) {
      if (is.numeric(x)) min(x, na.rm = TRUE) else NA_real_
    }, numeric(1)),
    Maximum = vapply(df, function(x) {
      if (is.numeric(x)) max(x, na.rm = TRUE) else NA_real_
    }, numeric(1)),
    row.names = NULL,
    check.names = FALSE
  )
}

# Spatial analysis -----------------------------------------------------------

# Values of the predictors at the occurrence points, with the species column
# renamed to `pa` and a `row` column pointing back to the input rows.
# Points falling outside the rasters (NA values) are dropped.
extract_predictors <- function(env, occ, species) {
  vals <- terra::extract(env, terra::vect(occ), ID = FALSE)
  vals$pa <- occ[[species]]
  vals$row <- seq_len(nrow(vals))
  vals[stats::complete.cases(vals), , drop = FALSE]
}

# Pearson correlation between layers, computed over all raster cells.
correlation_matrix <- function(env) {
  terra::layerCor(env, "cor", use = "complete.obs")$correlation
}

correlation_pvalues <- function(env, occ, species) {
  vals <- extract_predictors(env, occ, species)
  ggcorrplot::cor_pmat(vals[names(env)])
}

# CENFA only accepts raster and sp objects: convert at the boundary.
env_as_raster <- function(env) {
  raster::stack(env)
}

presence_as_spatial <- function(occ, species) {
  sf::as_Spatial(occ[occ[[species]] == 1, ])
}

fold_summary <- function(cv) {
  rec <- cv$records
  n_test <- rowSums(rec[, grepl("^test", names(rec)), drop = FALSE])
  n_train <- rowSums(rec[, grepl("^train", names(rec)), drop = FALSE])
  data.frame(
    fold = seq_len(nrow(rec)), rec,
    test_percent = round(100 * n_test / (n_test + n_train), 1),
    check.names = FALSE
  )
}

# Model fitting --------------------------------------------------------------

# Fit one model on a training table holding the predictors and a 0/1 `pa`
# column. Profile methods only use the presences.
fit_sdm <- function(method, train, predictors) {
  x <- train[, predictors, drop = FALSE]
  presences <- x[train$pa == 1, , drop = FALSE]
  switch(method,
    bioclim = dismo::bioclim(presences),
    domain = dismo::domain(presences),
    mahal = dismo::mahal(presences),
    maxent = dismo::maxent(x = x, p = train$pa),
    glm = stats::glm(pa ~ .,
      data = cbind(x, pa = train$pa),
      family = stats::binomial()
    ),
    rf = withCallingHandlers(
      randomForest::randomForest(x = x, y = train$pa, importance = TRUE),
      warning = function(w) {
        # 0/1 response fitted as a regression on purpose, to get a
        # probability-like output.
        if (grepl("regression", conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    ),
    svm = kernlab::ksvm(pa ~ ., data = cbind(x, pa = train$pa)),
    stop("Unknown modelling method: ", method, call. = FALSE)
  )
}

# Predicted suitability for a table of predictor values, as a numeric
# vector. Used both for evaluation and (through terra::predict) for maps.
predict_sdm <- function(model, newdata, ...) {
  if (inherits(model, "glm")) {
    out <- stats::predict(model, newdata, type = "response")
  } else if (inherits(model, "ksvm")) {
    out <- kernlab::predict(model, newdata)
  } else if (inherits(model, "randomForest")) {
    out <- stats::predict(model, newdata)
  } else {
    out <- dismo::predict(model, newdata)
  }
  as.numeric(out)
}

# k-fold cross-validated species distribution model.
#
# The data are split into folds (randomly, or with `fold_ids`, for example
# the `folds_ids` of a blockCV::cv_spatial() object). A model is fitted on
# each training set and evaluated on the matching test set. The model with
# the highest AUC is then used to predict suitability over `env`, and the
# "spec_sens" threshold turns that map into presence/absence.
fit_sdm_kfold <- function(method, env, occ, species, k = 5,
                          fold_ids = NULL, seed = 1994) {
  predictors <- names(env)
  dat <- extract_predictors(env, occ, species)
  if (sum(dat$pa == 1) < 2 || sum(dat$pa == 0) < 1) {
    stop("At least two presences and one absence falling inside the ",
      "rasters are needed.",
      call. = FALSE
    )
  }

  if (is.null(fold_ids)) {
    set.seed(seed)
    folds <- dismo::kfold(nrow(dat), k = k)
  } else {
    if (length(fold_ids) != nrow(occ)) {
      stop("'fold_ids' must have one entry per occurrence point. Re-run ",
        "the spatial blocking with the current occurrence data.",
        call. = FALSE
      )
    }
    folds <- fold_ids[dat$row]
  }

  fold_levels <- sort(unique(folds))
  models <- vector("list", length(fold_levels))
  evaluations <- vector("list", length(fold_levels))
  for (j in seq_along(fold_levels)) {
    is_test <- folds == fold_levels[[j]]
    train <- dat[!is_test, , drop = FALSE]
    test <- dat[is_test, , drop = FALSE]
    if (!any(test$pa == 1) || !any(test$pa == 0) || !any(train$pa == 1)) {
      next
    }
    models[[j]] <- fit_sdm(method, train, predictors)
    test_x <- test[, predictors, drop = FALSE]
    evaluations[[j]] <- dismo::evaluate(
      p = predict_sdm(models[[j]], test_x[test$pa == 1, , drop = FALSE]),
      a = predict_sdm(models[[j]], test_x[test$pa == 0, , drop = FALSE])
    )
  }
  ok <- !vapply(evaluations, is.null, logical(1))
  if (!any(ok)) {
    stop("No fold contains both presences and absences in its test set. ",
      "Use fewer folds.",
      call. = FALSE
    )
  }
  models <- models[ok]
  evaluations <- evaluations[ok]

  auc <- vapply(evaluations, function(e) e@auc, numeric(1))
  best <- which.max(auc)
  model <- models[[best]]
  evaluation <- evaluations[[best]]

  prediction <- terra::predict(env, model, fun = predict_sdm, na.rm = TRUE)
  names(prediction) <- "Occurrence probability"
  threshold <- dismo::threshold(evaluation, "spec_sens")
  presence_absence <- prediction > threshold
  names(presence_absence) <- "Presence/absence"
  presence_probability <- sdmApp::sdmApp_TimesRasters(
    prediction, presence_absence
  )
  names(presence_probability) <- "Probability of presence"

  list(
    method = method,
    species = species,
    predictors = predictors,
    data = dat,
    models = models,
    evaluations = evaluations,
    auc = auc,
    best = best,
    model = model,
    evaluation = evaluation,
    threshold = threshold,
    prediction = prediction,
    presence_absence = presence_absence,
    presence_probability = presence_probability
  )
}

# Interpreting a fitted model ------------------------------------------------

# Marginal response curves: each numeric predictor varies over its observed
# range while the others are held at their median.
response_curves <- function(fit, n = 100) {
  dat <- fit$data[, fit$predictors, drop = FALSE]
  numeric_vars <- fit$predictors[vapply(dat, is.numeric, logical(1))]
  base <- lapply(dat, function(x) {
    if (is.numeric(x)) stats::median(x) else x[[1]]
  })
  curves <- lapply(numeric_vars, function(v) {
    grid <- as.data.frame(base)[rep(1, n), , drop = FALSE]
    grid[[v]] <- seq(min(dat[[v]]), max(dat[[v]]), length.out = n)
    data.frame(
      variable = v,
      value = grid[[v]],
      prediction = predict_sdm(fit$model, grid)
    )
  })
  do.call(rbind, curves)
}

plot_response_curves <- function(fit) {
  curves <- response_curves(fit)
  ggplot2::ggplot(
    curves,
    ggplot2::aes(
      x = .data[["value"]], y = .data[["prediction"]]
    )
  ) +
    ggplot2::geom_line(colour = "darkgreen", linewidth = 0.8) +
    ggplot2::facet_wrap(~variable, scales = "free_x") +
    ggplot2::labs(x = NULL, y = "Predicted suitability", title = fit$species) +
    ggplot2::theme_bw()
}

# Variable importance, for the methods that provide one; NULL otherwise.
variable_importance <- function(fit) {
  model <- fit$model
  if (inherits(model, "randomForest")) {
    imp <- randomForest::importance(model, type = 1)
    return(data.frame(
      variable = rownames(imp),
      importance = as.numeric(imp[, 1]),
      measure = "% increase in MSE"
    ))
  }
  if (inherits(model, "MaxEnt")) {
    res <- model@results
    rows <- grep("[.]contribution$", rownames(res))
    return(data.frame(
      variable = sub("[.]contribution$", "", rownames(res)[rows]),
      importance = as.numeric(res[rows, 1]),
      measure = "Percent contribution"
    ))
  }
  NULL
}

plot_variable_importance <- function(fit) {
  imp <- variable_importance(fit)
  if (is.null(imp)) {
    return(NULL)
  }
  imp$variable <- stats::reorder(imp$variable, imp$importance)
  ggplot2::ggplot(
    imp,
    ggplot2::aes(
      x = .data[["importance"]], y = .data[["variable"]]
    )
  ) +
    ggplot2::geom_col(fill = "steelblue") +
    ggplot2::labs(x = imp$measure[[1]], y = NULL, title = fit$species) +
    ggplot2::theme_bw()
}

evaluation_types <- function() {
  c("ROC", "density", "boxplot", "kappa", "FPR", "prevalence")
}

# Draw an evaluation plot (base graphics) for the best model of a fit.
plot_evaluation <- function(fit, type) {
  ev <- fit$evaluation
  switch(type,
    density = raster::density(ev),
    boxplot = raster::boxplot(ev,
      col = c("red", "green"),
      xlab = fit$species
    ),
    raster::plot(ev, type)
  )
  invisible(NULL)
}

# Map of a fitted model: "probability", "presence_absence" or
# "presence_probability".
plot_sdm_map <- function(fit, which = "probability") {
  switch(which,
    probability = sdmApp::sdmApp_RasterPlot(fit$prediction),
    presence_absence = sdmApp::sdmApp_PA(fit$presence_absence),
    presence_probability = sdmApp::sdmApp_RasterPlot(fit$presence_probability),
    stop("Unknown map type: ", which, call. = FALSE)
  )
}

sdm_map_raster <- function(fit, which = "probability") {
  switch(which,
    probability = fit$prediction,
    presence_absence = fit$presence_absence,
    presence_probability = fit$presence_probability
  )
}

# Plot customisation (Data Upload tab) ---------------------------------------

# Apply the options chosen in the "Change aesthetics" panel to a ggplot.
# `opts` is a list with the same names as the corresponding shiny inputs.
style_plot <- function(p, opts) {
  theme_fun <- switch(opts$theme %||% "bw",
    bw = ggplot2::theme_bw,
    classic = ggplot2::theme_classic,
    dark = ggplot2::theme_dark,
    grey = ggplot2::theme_grey,
    light = ggplot2::theme_light,
    linedraw = ggplot2::theme_linedraw,
    minimal = ggplot2::theme_minimal,
    ggplot2::theme_bw
  )
  p <- p + theme_fun()

  if (isTRUE(opts$label_axes)) {
    p <- p + ggplot2::labs(x = opts$lab_x, y = opts$lab_y)
  }
  if (isTRUE(opts$add_title)) {
    p <- p + ggplot2::ggtitle(opts$title)
  }
  if (identical(opts$adj_leg, "Change legend")) {
    p <- p + ggplot2::labs(fill = opts$leg_ttl)
  }

  th <- list(plot.title = ggplot2::element_text(hjust = 0.5, size = 10))
  if (isTRUE(opts$adj_fnt_sz)) {
    th$axis.title <- ggplot2::element_text(size = opts$fnt_sz_ttl)
    th$axis.text <- ggplot2::element_text(size = opts$fnt_sz_ax)
  }
  if (isTRUE(opts$adj_fnt)) {
    th$text <- ggplot2::element_text(family = opts$font)
  }
  if (isTRUE(opts$rot_txt)) {
    th$axis.text.x <- ggplot2::element_text(angle = 45, hjust = 1)
  }
  if (identical(opts$adj_leg, "Remove legend")) {
    th$legend.position <- "none"
  }
  if (identical(opts$adj_leg, "Change legend")) {
    th$legend.position <- opts$pos_leg
  }
  if (isTRUE(opts$adj_grd) && isTRUE(opts$grd_maj)) {
    th$panel.grid.major <- ggplot2::element_blank()
  }
  if (isTRUE(opts$adj_grd) && isTRUE(opts$grd_min)) {
    th$panel.grid.minor <- ggplot2::element_blank()
  }
  p + do.call(ggplot2::theme, th)
}

# Small utilities -------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

# Save a plot to `file` as png or pdf. `draw` is either a ggplot object or a
# function drawing with base graphics.
save_plot <- function(file, draw, type = "png") {
  if (identical(type, "pdf")) {
    grDevices::pdf(file)
  } else {
    grDevices::png(file, width = 800, height = 600)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  if (is.function(draw)) {
    draw()
  } else {
    print(draw)
  }
  invisible(file)
}

# Map of one environmental layer: discrete colours for categorical layers,
# a continuous ramp otherwise.
plot_env_layer <- function(layer) {
  if (!terra::is.factor(layer)) {
    return(sdmApp::sdmApp_RasterPlot(layer))
  }
  df <- terra::as.data.frame(layer, xy = TRUE, na.rm = TRUE)
  names(df) <- c("x", "y", "value")
  df$value <- factor(df$value)
  ggplot2::ggplot(df) +
    ggplot2::geom_raster(ggplot2::aes(
      x = .data[["x"]], y = .data[["y"]],
      fill = .data[["value"]]
    )) +
    ggplot2::labs(x = "Longitude", y = "Latitude", fill = NULL) +
    ggplot2::ggtitle(names(layer)) +
    ggplot2::theme_bw()
}
