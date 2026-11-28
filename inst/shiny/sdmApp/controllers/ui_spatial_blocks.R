# Spatial Analysis > Spatial blocking (blockCV::cv_spatial). The resulting
# folds can then be used to cross-validate the models.

observeEvent(input$block_button, {
  req(input$block_size > 0)
  result <- tryCatch(
    withProgress(
      message = "Spatial blocking",
      blockCV::cv_spatial(
        x = occ_sf(),
        column = species(),
        r = env(),
        size = input$block_size,
        k = input$number_fold,
        selection = input$allocation_fold,
        iteration = 100,
        biomod2 = FALSE,
        plot = FALSE,
        progress = FALSE,
        report = FALSE
      )
    ),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    showNotification(
      paste("Spatial blocking failed:", conditionMessage(result)),
      type = "error", duration = NULL
    )
    return()
  }
  spatial_state$blocks <- result
  updateSliderInput(session, "test_fold", max = input$number_fold, value = 1)
})

blocks <- reactive({
  req(spatial_state$blocks)
})

output$sp_block <- renderPlot({
  blockCV::cv_plot(cv = blocks(), x = occ_sf(), r = env())
})

output$test_train_plot <- renderPlot({
  req(input$test_fold <= length(blocks()$folds_list))
  sdmApp::sdmApp_fold_Explorer(blocks(), env(), occ_sf(), input$test_fold)
})

output$sum_fold <- DT::renderDataTable({
  DT::datatable(fold_summary(blocks()),
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

output$ui_spatial_blocks <- renderUI({
  default_size <- isolate({
    ac <- spatial_state$autocor
    if (is.null(ac)) NA else round(ac$range)
  })
  fluidRow(
    column(12, h4("Spatial blocking"), p(
      "Spatial blocking can take a long time with many variables. The folds",
      "created here can be used in the Modeling tab ('Spatial blocks'",
      "cross-validation)."
    ), align = "center"),
    mainPanel(width = 8, tabsetPanel(
      type = "tabs",
      tabPanel(
        "Spatial blocking",
        numericInput("block_size",
          "Block size (metres; defaults to the autocorrelation range)",
          value = default_size, min = 1
        ),
        sliderInput("number_fold", "Folds", min = 2, max = 20, value = 5),
        selectInput(
          "allocation_fold", "Allocation of blocks to folds",
          c("random", "systematic")
        ),
        actionButton("block_button", "Apply", class = "btn-primary"),
        plotOutput("sp_block"),
        sliderInput("test_fold", "Fold to show as the test set",
          min = 1, max = 5, value = 1, step = 1, ticks = FALSE
        ),
        plotOutput("test_train_plot")
      ),
      tabPanel(
        "Fold summary",
        p("test_percent is the share of the points used for testing."),
        DT::dataTableOutput("sum_fold")
      )
    ))
  )
})
