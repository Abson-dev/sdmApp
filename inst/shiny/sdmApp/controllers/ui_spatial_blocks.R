
sp<-reactiveValues()

output$ui_spatial_blocks<-renderUI({
  observeEvent(input$number_fold,{
    load.occ$k<-input$number_fold
  })

  observeEvent(input$allocation_fold,{

    load.occ$allocation_fold<-input$allocation_fold
  })
  Specdata<-reactive({
    dsf<-load.occ$select
    dsf<-dsf %>% dplyr::rename(lon=load.occ$lon,lat=load.occ$lat)
    dsf
  })

  pa_data<-reactive({
    load.occ$pa_data<-sf::st_as_sf(Specdata(), coords = c("lon","lat"), crs = crs(data$Env))
    load.occ$pa_data
  })
  spatialblock<-reactive({
    a = try(withProgress(message = 'Spatial blocking',
                         spatialBlock(speciesData = pa_data(),
                                      species = load.occ$spec_select,
                                      rasterLayer = data$Env,
                                      theRange = range(), #load.occ$range, # size of the blocks
                                      k = load.occ$k,
                                      showBlocks = TRUE,
                                      selection = load.occ$allocation_fold,
                                      iteration = 100, # find evenly dispersed folds
                                      biomod2Format = FALSE,
                                      xOffset = 0, # shift the blocks horizontally
                                      yOffset = 0)))
    if(inherits(a, 'try-error'))
      {
      output$Envbug_sp <- renderUI(p('Spatial blocking failed, please check your inputs and try again!'))
    } else {
      output$Envbug_sp <- renderUI(p())
      a
    }
  })

  output$sp_block<-renderPlot({
    spatialblock<-spatialblock()
    spatialblock$plots + geom_sf(data = pa_data(), alpha = 0.5)
  })


  output$sum_fold <- DT::renderDataTable({
    spatialblock<-spatialblock()
    sumfold<-summarise_fold(spatialblock)
    datatable(sumfold,
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=20)

    )})
  observeEvent(input$test_fold,{
    load.occ$fold<-input$test_fold
  })
  output$test_train_plot<-renderPlot({
    spatialblock<-spatialblock()
    Explorer(spatialblock, data$Env, pa_data(),1) #1=load.occ$fold
  })

  fluidRow(column(12, h4("Spatial blocking"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("Spatial blocking",
                                                     p('Set spatial bloking parameters'),
                                                     sliderInput("number_fold", "folds", min=1, max=100, value=5),
                                                     selectInput("allocation_fold","allocation of blocks to folds",choices = c("random","systematic"),selected="random"),
                                                     sliderInput("test_fold","Select the number of fold to assign as test dataset",min = 1,max=100,value = 1),
                                                     plotOutput("sp_block"),
                                                     plotOutput("test_train_plot")),
                                            tabPanel("Summarize fold",
                                                     p('Fold summarizing. Purcentage means the purcentage of test dataset'),
                                                     DT::dataTableOutput("sum_fold"))

           ),
           id = "tabs")

  )

})
