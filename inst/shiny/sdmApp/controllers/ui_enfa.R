# Spatial Analysis > Ecological-niche factor analysis (ENFA).

enfa_axis <- reactive({
  n <- enfa()$n_factors
  if (n > 1 && !is.null(input$number_spec)) as.numeric(input$number_spec) else 2
})

marg_spec <- reactive({
  data.frame(enfa()$fit@co)
})

output$enfa_scatter <- renderPlot({
  draw_enfa(yax = enfa_axis())
})

output$marg <- DT::renderDataTable({
  DT::datatable(round(marg_spec(), 4),
    rownames = TRUE, selection = "none", options = datatable_options
  )
})

output$download_enfa_scatter <- downloadHandler(
  filename = function() "ENFA.png",
  content = function(file) {
    yax <- enfa_axis()
    save_plot(file, function() draw_enfa(yax = yax))
  }
)

output$download_Marg_Spec <- downloadHandler(
  filename = function() paste0("Marg_Spec_", Sys.Date(), ".csv"),
  content = function(file) utils::write.csv(marg_spec(), file)
)

output$ui_enfa <- renderUI({
  n <- enfa()$n_factors
  fluidRow(
    column(12, h4("Ecological Niche Factor Analysis"), p(
      "Ecological-niche factor analysis (ENFA, Hirzel et al., 2002) relies",
      "on the concept of the ecological niche. Based on the computation of",
      "two parameters, the marginality and the specialization, ENFA",
      "provides a measure of the realised niche within the available space."
    ), align = "center"),
    mainPanel(width = 8, tabsetPanel(
      type = "tabs",
      tabPanel(
        "ENFA",
        p("Number of significant specialization factors:", code(n)),
        if (n > 1) {
          selectInput("number_spec", "Specialization axis to plot", 2:n)
        },
        downloadButton("download_enfa_scatter", "Download"),
        plotOutput("enfa_scatter")
      ),
      tabPanel(
        "Marginality and specialization",
        downloadButton("download_Marg_Spec", "Download"),
        DT::dataTableOutput("marg")
      )
    ))
  )
})
