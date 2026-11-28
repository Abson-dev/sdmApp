# Shiny module for one species distribution modelling method.
#
# The same module serves every method listed in sdm_methods(): it lets the
# user pick predictors and a cross-validation scheme, fits the model with
# fit_sdm_kfold() and shows the maps, evaluation plots, response curves and
# (when available) variable importance, each with a download button.
#
# The helpers it calls (sdm_methods(), fit_sdm_kfold(), ...) are defined in
# helpers.R and sourced into the same environment by global.R, which lintr
# cannot see when it checks this file on its own.
# nolint start: object_usage_linter.

map_choices <- c(
  "Occurrence map" = "probability",
  "Occurrence map (Presence/Absence)" = "presence_absence",
  "Occurrence map (Presence)" = "presence_probability"
)

sdm_model_ui <- function(id, method, layer_names) {
  ns <- shiny::NS(id)
  info <- sdm_methods()[sdm_methods()$id == method, ]

  tabs <- list(
    shiny::tabPanel(
      "Species predictors",
      shiny::selectInput(ns("predictors"),
        "Please select the species predictors",
        layer_names,
        multiple = TRUE, selectize = TRUE
      ),
      shiny::actionButton(ns("run"), paste("Apply", info$label),
        class = "btn-primary"
      ),
      shiny::p(
        "The ENFA plot below can help you choose predictors that",
        "contribute to the species' marginality and specialization."
      ),
      shiny::plotOutput(ns("enfa"))
    ),
    shiny::tabPanel(
      "Map",
      shiny::selectInput(ns("map_type"), NULL, map_choices),
      shiny::radioButtons(ns("map_format"), "Select the file type to export",
        c("png", "pdf", "tif"),
        inline = TRUE
      ),
      shiny::downloadButton(ns("download_map"), "Download"),
      shiny::plotOutput(ns("map"))
    ),
    shiny::tabPanel(
      "Model evaluation",
      shiny::uiOutput(ns("evaluation_summary")),
      shiny::selectInput(
        ns("evaluation_type"),
        "Please select the metric to evaluate the model",
        evaluation_types()
      ),
      shiny::radioButtons(ns("evaluation_format"),
        "Select the file type to export", c("png", "pdf"),
        inline = TRUE
      ),
      shiny::downloadButton(ns("download_evaluation"), "Download"),
      shiny::plotOutput(ns("evaluation"))
    ),
    shiny::tabPanel(
      "Variable response",
      shiny::radioButtons(ns("response_format"),
        "Select the file type to export", c("png", "pdf"),
        inline = TRUE
      ),
      shiny::downloadButton(ns("download_response"), "Download"),
      shiny::plotOutput(ns("response"))
    )
  )
  if (info$importance) {
    tabs <- c(tabs, list(shiny::tabPanel(
      "Variable importance",
      shiny::radioButtons(ns("importance_format"),
        "Select the file type to export", c("png", "pdf"),
        inline = TRUE
      ),
      shiny::downloadButton(ns("download_importance"), "Download"),
      shiny::plotOutput(ns("importance"))
    )))
  }

  shiny::tagList(
    shiny::fluidRow(
      shiny::column(12, shiny::h3(info$label), class = "wb-header"),
      shiny::column(12, shiny::p(
        "Choose the species predictors (for example with the help of the",
        "ENFA) and a cross-validation scheme, then fit the model."
      ), class = "wb-header-hint")
    ),
    shiny::sidebarPanel(
      width = 4,
      shiny::radioButtons(
        ns("cv"), "Cross-validation",
        c(
          "Random k-fold" = "random",
          "Spatial blocks (from the Spatial blocking tab)" = "spatial"
        )
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'random'", ns("cv")),
        shiny::sliderInput(ns("k"), "Number of folds",
          min = 2, max = 20, value = 5
        )
      ),
      shiny::uiOutput(ns("cv_status"))
    ),
    shiny::mainPanel(
      width = 8,
      do.call(shiny::tabsetPanel, c(list(type = "tabs"), tabs))
    )
  )
}

# Arguments:
#   env:          reactive returning the SpatRaster of all predictors.
#   occ:          reactive returning the occurrence sf object.
#   species:      reactive returning the species column name.
#   spatial_cv:   reactive returning a blockCV cv_spatial object or NULL.
#   draw_enfa:    function drawing the ENFA scatter plot.
sdm_model_server <- function(id, method, env, occ, species, spatial_cv,
                             draw_enfa) {
  shiny::moduleServer(id, function(input, output, session) {
    output$enfa <- shiny::renderPlot({
      draw_enfa()
    })

    output$cv_status <- shiny::renderUI({
      if (input$cv == "spatial" && is.null(spatial_cv())) {
        shiny::p(
          class = "text-danger",
          "No spatial blocks yet: run the Spatial blocking step in the",
          "Spatial Analysis tab first."
        )
      }
    })

    fit <- shiny::eventReactive(input$run, {
      shiny::validate(
        shiny::need(
          length(input$predictors) > 0, "Choose species predictors first!"
        ),
        shiny::need(
          input$cv == "random" || !is.null(spatial_cv()),
          "Run the spatial blocking first, or choose random k-fold."
        )
      )
      fold_ids <- if (input$cv == "spatial") spatial_cv()$folds_ids else NULL
      label <- sdm_method_label(method)
      shiny::withProgress(message = paste("Fitting", label), {
        tryCatch(
          fit_sdm_kfold(method, env()[[input$predictors]], occ(), species(),
            k = input$k, fold_ids = fold_ids
          ),
          error = function(e) {
            shiny::showNotification(
              paste("Model fitting failed:", conditionMessage(e)),
              type = "error", duration = NULL
            )
            NULL
          }
        )
      })
    })

    ready_fit <- shiny::reactive({
      f <- fit()
      shiny::validate(
        shiny::need(!is.null(f), "The model could not be fitted.")
      )
      f
    })

    map_plot <- shiny::reactive(plot_sdm_map(ready_fit(), input$map_type))
    output$map <- shiny::renderPlot(map_plot())
    output$download_map <- shiny::downloadHandler(
      filename = function() {
        paste0(method, "_", input$map_type, ".", input$map_format)
      },
      content = function(file) {
        if (input$map_format == "tif") {
          terra::writeRaster(sdm_map_raster(ready_fit(), input$map_type), file,
            overwrite = TRUE
          )
        } else {
          save_plot(file, map_plot(), input$map_format)
        }
      }
    )

    output$evaluation_summary <- shiny::renderUI({
      f <- ready_fit()
      shiny::p(sprintf(
        paste(
          "Best fold: %d of %d. AUC = %.3f.",
          "Threshold (max. sensitivity + specificity) = %.3f."
        ),
        f$best, length(f$auc), f$auc[[f$best]], f$threshold
      ))
    })
    output$evaluation <- shiny::renderPlot({
      plot_evaluation(ready_fit(), input$evaluation_type)
    })
    output$download_evaluation <- shiny::downloadHandler(
      filename = function() {
        paste0(method, "_", input$evaluation_type, ".", input$evaluation_format)
      },
      content = function(file) {
        f <- ready_fit()
        save_plot(file, function() plot_evaluation(f, input$evaluation_type),
          type = input$evaluation_format
        )
      }
    )

    response_plot <- shiny::reactive(plot_response_curves(ready_fit()))
    output$response <- shiny::renderPlot(response_plot())
    output$download_response <- shiny::downloadHandler(
      filename = function() {
        paste0(method, "_response.", input$response_format)
      },
      content = function(file) {
        save_plot(file, response_plot(), input$response_format)
      }
    )

    importance_plot <- shiny::reactive(plot_variable_importance(ready_fit()))
    output$importance <- shiny::renderPlot(importance_plot())
    output$download_importance <- shiny::downloadHandler(
      filename = function() {
        paste0(method, "_importance.", input$importance_format)
      },
      content = function(file) {
        save_plot(file, importance_plot(), input$importance_format)
      }
    )

    fit
  })
}
# nolint end
