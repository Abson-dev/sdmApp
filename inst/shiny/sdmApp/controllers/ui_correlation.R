# Spatial Analysis > Correlation between environmental variables.

cor_matrix <- reactive({
  correlation_matrix(env())
})

cor_plot <- reactive({
  ggcorrplot::ggcorrplot(cor_matrix(),
    ggtheme = ggplot2::theme_gray,
    hc.order = TRUE,
    type = "lower",
    p.mat = correlation_pvalues(env(), occ_sf(), species()),
    colors = c("#6D9EC1", "white", "#E46726")
  )
})

output$coor_mat <- DT::renderDataTable({
  DT::datatable(round(cor_matrix(), 3),
    rownames = TRUE, selection = "none", options = datatable_options
  )
})

output$coor_plot <- renderPlot({
  withProgress(message = "Correlation plot", cor_plot())
})

output$download_cor_mat <- downloadHandler(
  filename = function() paste0("correlation_matrix_", Sys.Date(), ".csv"),
  content = function(file) utils::write.csv(cor_matrix(), file)
)

output$download_cor_plot <- downloadHandler(
  filename = function() paste("cor_plot", input$plot_type_cor, sep = "."),
  content = function(file) save_plot(file, cor_plot(), input$plot_type_cor)
)

output$ui_correlation <- renderUI({
  fluidRow(
    column(12, h4("Correlation between environmental variables"),
      align = "center"
    ),
    mainPanel(width = 8, tabsetPanel(
      type = "tabs",
      tabPanel(
        "Correlation matrix",
        downloadButton("download_cor_mat", "Download"),
        DT::dataTableOutput("coor_mat")
      ),
      tabPanel(
        "Correlation plot",
        p(
          "Crossed cells are not significant at the 5% level (tested at",
          "the occurrence points)."
        ),
        radioButtons("plot_type_cor", "Select the file type", c("png", "pdf"),
          inline = TRUE
        ),
        downloadButton("download_cor_plot", "Download"),
        plotOutput("coor_plot")
      )
    ))
  )
})
