# Spatial Analysis > Spatial autocorrelation of the predictors
# (blockCV::cv_spatial_autocor), used to size the spatial blocks.

observeEvent(input$sp_auto, {
  req(length(input$var_auto) > 0)
  result <- tryCatch(
    withProgress(
      message = "Spatial autocorrelation",
      blockCV::cv_spatial_autocor(
        r = env()[[input$var_auto]], plot = FALSE, progress = FALSE
      )
    ),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    showNotification(
      paste(
        "Spatial autocorrelation failed:", conditionMessage(result),
        "Try other predictors."
      ),
      type = "error", duration = NULL
    )
    return()
  }
  spatial_state$autocor <- result
  updateSelectInput(session, "vario_var", choices = input$var_auto)
})

autocor <- reactive({
  req(spatial_state$autocor)
})

variogram_plot <- reactive({
  req(input$vario_var)
  ac <- autocor()
  i <- match(input$vario_var, ac$range_table$layers)
  req(!is.na(i))
  plot(ac$variograms[[i]])
})

output$barchart <- renderPlot(autocor()$plots$barchart)
output$mapplot <- renderPlot(autocor()$plots$map_plot)
output$variogram <- renderPlot(print(variogram_plot()))
output$tableRange <- DT::renderDataTable({
  DT::datatable(autocor()$range_table,
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

output$download_barchart <- downloadHandler(
  filename = function() "barchart.png",
  content = function(file) save_plot(file, autocor()$plots$barchart)
)
output$download_mapplot <- downloadHandler(
  filename = function() "mapplot.png",
  content = function(file) save_plot(file, autocor()$plots$map_plot)
)
output$download_tableRange <- downloadHandler(
  filename = function() "autocorrelation_range.csv",
  content = function(file) {
    utils::write.csv(autocor()$range_table, file, row.names = FALSE)
  }
)
output$download_variogram <- downloadHandler(
  filename = function() paste0("variogram_", input$vario_var, ".png"),
  content = function(file) save_plot(file, variogram_plot())
)

output$ui_spatial_auto_range <- renderUI({
  fluidRow(
    column(12, h4("Spatial autocorrelation"), align = "center"),
    mainPanel(width = 8, tabsetPanel(
      type = "tabs",
      tabPanel(
        "Apply",
        p("Spatial autocorrelation ranges in the environmental variables."),
        selectInput("var_auto", "Please select the species predictors",
          names(env()),
          multiple = TRUE, selectize = TRUE
        ),
        p("This can take a long time with many variables."),
        actionButton("sp_auto", "Apply", class = "btn-primary")
      ),
      tabPanel(
        "Barchart",
        downloadButton("download_barchart", "Download"),
        plotOutput("barchart")
      ),
      tabPanel(
        "Map plot",
        p(
          "Spatial blocks sized on the median autocorrelation range across",
          "the selected variables."
        ),
        downloadButton("download_mapplot", "Download"),
        plotOutput("mapplot")
      ),
      tabPanel(
        "Autocorrelation range table",
        downloadButton("download_tableRange", "Download"),
        DT::dataTableOutput("tableRange")
      ),
      tabPanel(
        "Variogram",
        selectInput(
          "vario_var", "Predictor",
          isolate(spatial_state$autocor$range_table$layers)
        ),
        downloadButton("download_variogram", "Download"),
        plotOutput("variogram")
      )
    ))
  )
})
