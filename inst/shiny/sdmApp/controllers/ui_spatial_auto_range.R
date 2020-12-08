# sac<-reactive({
#   a = try(withProgress(message = 'Spatial Autorange',
#                        spatialAutoRange(rasterLayer = data$Env,
#                                         doParallel = T,
#                                         plotVariograms = TRUE,
#                                         showPlots = FALSE)))
#   a
# })
#
# range<-reactive({
#   sac<-sac()
#   round(sac$range,0)
#
# })
output$ui_spatial_auto_range<-renderUI({
output$tableRange <- DT::renderDataTable({
    datatable(tableRange(),
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=20)

    )})
  observeEvent(input$vario_var,{
    output$variogram<-renderPlot({
      sac<-sac()
      vect<-names(data$Env)
      plot(sac$variograms[[which(vect==input$vario_var)]])
    })
  })

  output$barchart <- renderPlot({
    sac<-sac()
    sac$plots$barchart
  })

  output$mapplot <- renderPlot({
    sac<-sac()
    sac$plots$mapplot
  })

  fluidRow(column(12, h4("Spatial"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("barchart",
                                                     p('Spatial autocorrelation ranges in input covariates'),
                                                     plotOutput("barchart")),
                                            tabPanel("mapplot",
                                                     p('Corresponding spatial blocks (the selected block size is based on median spatial autocorrelation range across all input data)'),
                                                     plotOutput("mapplot")),
                                            tabPanel("Autocorrelation range table",
                                                     p('Spatial autocorrelation ranges table in input covariates'),
                                                     DT::dataTableOutput("tableRange")),
                                            tabPanel("Variogramme",
                                                     selectInput('vario_var', 'Please select the predictor to see variogram corresponding', names(data$Env), multiple = FALSE, selectize = TRUE),
                                                     plotOutput("variogram"))

           ),
           id = "tabs")

  )
})
