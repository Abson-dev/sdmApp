# range_sp<-reactive({
#   sac<-load.occ$sac
#   round(sac$range,0)
# })


output$ui_spatial_blocks<-renderUI({
  observeEvent(input$block_button,{
   observeEvent(input$number_fold,{
     load.occ$k<-input$number_fold
   })

   observeEvent(input$allocation_fold,{

     load.occ$allocation_fold<-input$allocation_fold
   })
   sp_Specdata<-reactive({
     dsf<-load.occ$select
     dsf[,load.occ$spec_select]<-as.factor(dsf[,load.occ$spec_select])
     dsf<-dsf %>% dplyr::rename(lon=load.occ$lon,lat=load.occ$lat)
     dsf
   })

   sp_pa_data<-reactive({
     load.occ$sp_pa_data<-sf::st_as_sf(sp_Specdata(), coords = c("lon","lat"), crs = crs(data$Env))
     load.occ$sp_pa_data
   })

   spatialblock<-reactive({
     a = try(withProgress(message = 'Spatial blocking',
                          blockCV::cv_spatial(x = sp_pa_data(),
                                              column = load.occ$spec_select,
                                              r = data$var_auto,
                                              size = block_range(), # size of the blocks (m)
                                              k = load.occ$k,
                                              selection = load.occ$allocation_fold,
                                              iteration = 100, # find evenly dispersed folds
                                              biomod2 = FALSE,
                                              plot = FALSE,
                                              progress = FALSE,
                                              report = FALSE)))
     if(inherits(a, 'try-error'))
     {
       output$Envbug_sp <- renderUI(p('Spatial blocking failed, please check your inputs and try again!'))
     } else {
       output$Envbug_sp <- renderUI(p())
       load.occ$spatialblock<-a
       a
     }
   })

  output$sp_block<-renderPlot({
    spatialblock<-spatialblock()
    blockCV::cv_plot(cv = spatialblock, x = sp_pa_data(), r = data$var_auto)
  })


  output$sum_fold <- DT::renderDataTable({
    spatialblock<-spatialblock()
    sumfold<-reactive({
      a = try(withProgress(message = 'Summary fold...',
             {
               rec <- spatialblock$records
               n_test <- rowSums(rec[, grepl("^test", names(rec)), drop = FALSE])
               n_all <- n_test + rowSums(rec[, grepl("^train", names(rec)), drop = FALSE])
               data.frame(fold = seq_len(nrow(rec)), rec,
                          test_percent = round(100 * n_test / n_all, 1),
                          check.names = FALSE)
             }))
      if(inherits(a, 'try-error'))
      {
        output$Envbug_fold <- renderUI(p('Spatial blocking failed, please check your inputs and try again!'))
      } else {
        output$Envbug_fold <- renderUI(p())
        a
      }
    })
    datatable(sumfold(),
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=20)

    )})
  observeEvent(input$test_fold,{
    load.occ$fold<-input$test_fold

  output$test_train_plot<-renderPlot({
    spatialblock<-spatialblock()
    sdmApp::sdmApp_fold_Explorer(spatialblock, data$Env, sp_pa_data(),load.occ$fold) #1=load.occ$fold
  })
  })
  })
  fluidRow(column(12, h4("Spatial blocking"),p("'The spatial blocking procedure can take a long time depending on the number of input variables"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("Spatial blocking",
                                                     p('Set spatial bloking parameters'),
                                                     sliderInput("number_fold", "folds", min=2, max=100, value=5),
                                                     selectInput("allocation_fold","allocation of blocks to folds",choices = c("random","systematic"),selected="random"),
                                                     sliderInput("test_fold","Select the number of fold to assign as test dataset",min = 1,max=100,value = 1),
                                                     myActionButton("block_button",label=("Apply"), "primary"),
                                                     uiOutput("Envbug_sp"),
                                                     plotOutput("sp_block"),
                                                     plotOutput("test_train_plot")),
                                            tabPanel("Fold summary",
                                                     p('The percentage values indicate the percentage of data the test dataset corresponds to'),
                                                     uiOutput("Envbug_fold"),
                                                     DT::dataTableOutput("sum_fold"))

           ),
           id = "tabs")

  )

})
