###########################################"" Data Preparation#############
###############################################################"###########

######
output$ui_view_species_data <- renderUI({
  ###############
  ###species selected
  occ_data_select_df = reactive({
    datatable(load.occ$select,
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=10)
    )
  })

  output$occ_data_select <- DT::renderDataTable({
    occ_data_select_df()
  })

  ###############  function ######################
  # all variables available in the input data set
  allVars <- reactive({
    inp <- load.occ$select
    if (is.null(inp)) {
      return(NULL)
    }
    cn <- colnames(inp)
    cl <- sapply(1:ncol(inp), function(x) {
      class(inp[[x]])
    })
    names(cn) <- paste0(cn," (",cl,")")
    cn
  })
  ###############  end function ######################
  ###############  function ######################
  dataTypes <- reactive({
    inputdata <- load.occ$select
    if (is.null(inputdata)) {
      return(NULL)
    }
    cn <- colnames(inputdata)
    cl <- sapply(1:ncol(inputdata), function(x) {
      class(inputdata[[x]])
    })
    cl
  })

  output$SpeciesTable <- DT::renderDataTable({
    ############# function ########
    sdmData <- reactive({
      inputdata <- load.occ$select
      if (is.null(inputdata)) {
        return(NULL)
      }
      vars <- allVars()
      df <- data.frame(
        "Variable Name"=vars
      )
      df$nrCodes <- sapply(inputdata, function(x) { length(unique(x))} )
      df$nrNA <- sapply(inputdata, function(x) { sum(is.na(x))} )
      df$min<-sapply(inputdata, function(x) { min(x,na.rm = TRUE)} )
      df$max<-sapply(inputdata, function(x) { max(x,na.rm = TRUE)} )
      colnames(df) <- c("Variable name",  "Number of levels", "Number of missing","minimum","maximum")
      rownames(df) <- NULL
      df
    })
    datatable(sdmData(),
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=10)
    )
  })

  output$sumlayers<-DT::renderDataTable({
    summrize_rasters<-reactive({
      df<-data.frame("Layers name"=names(data$Env),"Minimum"=minValue(data$Env),"Maximum"=maxValue(data$Env))
      rownames(df) <- NULL
      df
    })
    datatable(summrize_rasters(),
              rownames = FALSE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=10)
    )
  })

  txt_species_data <- paste0("The loaded dataset  consists of",code(nrow(load.occ$select)),"observations and ",code(ncol(load.occ$select)),"variables. ")
  txt_rasters_info<-paste0("You have" ,code(raster::nlayers(data$Env)),"layers.The extent is xmin=",code(raster::extent(data$Env)@xmin),",xmax=",code(raster::extent(data$Env)@xmax),",ymin=",code(raster::extent(data$Env)@ymin),",ymax=",code(raster::extent(data$Env)@ymax))
  fluidRow(
    mainPanel(width = 8, tabsetPanel(type = "tabs",
                                     tabPanel("Occurence data",
                                              p(HTML(txt_species_data)),
                                              dataTableOutput("occ_data_select")
                                     ),
                                     tabPanel("Summarise Occurence data",
                                              p(HTML(txt_rasters_info)),
                                              dataTableOutput("SpeciesTable")
                                     ),
                                     tabPanel("Layers summerize",
                                              dataTableOutput("sumlayers"))


    ),
    id = "tabs")
  )


})








# output$ui_choice_species <- renderUI({
#   #input$btn_reset_sdc # dependency so that variable-types will get updated!
#   #out <- NULL
#   #if (!is.null(obj$last_error)) {
#   #  out <- list(out, fluidRow(column(12, verbatimTextOutput("ui_lasterror")), class = "wb-error-toast"))
#   #}
#
#   txt_setup <- "Select the following variables for setting up the SDC problem instance: categorical key variables, continuous key variables (optional), variables selected for PRAM (optional), sample weight (optional), hierarchical identifier (optional), variables to be deleted (optional). Also, specify the parameter alpha and set a seed at the bottom of this page."
#   txt_setup <- paste(txt_setup, tags$br(), tags$br(), "Tip - Before you start, make sure that variable types are appropriate. If not, go to the Microdata tab and convert variables to numeric or factor.")
#   out <- NULL
#   out <- list(out,
#               fluidRow(column(12, h4("Select variables", tipify(icon("info-circle"), title=txt_setup, placement="bottom"), class="wb-block-title"), align="center")),
#               fluidRow(column(12, DT::dataTableOutput("SpeciesTable", height="100%"))))
#   out
# })

###########################################"

####ui correlation

#glc <- GLcenfa(x = ENFA_var)



#load.occ$spec_select<-input$Pcol
#coor$pa_dataF <- sf::st_as_sf(coor$Specdata, coords = c("lon","lat"), crs = crs(data$Env))
#coor$Cor <- raster::extract(data$Env, coor$pa_dataF, df = TRUE)
#coor$Cor<-coor$Cor[,-1]
Specdata<-reactive({
  dsf<-load.occ$select
  dsf<-dsf %>% dplyr::rename(lon=load.occ$lon,lat=load.occ$lat)
  dsf
})
# correlation matrix
Z<-reactive({
  CENFA::parScale(data$Env)
})


# Efficient calculation of covariance matrices for Raster* objects
mat<-reactive({
  CENFA::parCov(Z())
})

pa_data<-reactive({
  sf::st_as_sf(Specdata(), coords = c("lon","lat"), crs = crs(data$Env))

})
Cor<-reactive({
  Corr<-raster::extract(data$Env, pa_data(), df = TRUE)
  Corr<-Corr[,-1]
  Corr
})

p.mat <-reactive({
  p_mat<-ggcorrplot::cor_pmat(Cor())
  p_mat
})
output$ui_correlation <- renderUI({


  output$coor_mat <- DT::renderDataTable({
    datatable(mat(),
              rownames = TRUE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=20)

    )})
  output$coor_plot <- renderPlot({
    ggcorrplot::ggcorrplot(mat(),ggtheme = ggplot2::theme_gray,
                           hc.order = TRUE,
                           type = "lower",
                           p.mat = p.mat(),
                           colors = c("#6D9EC1", "white", "#E46726"))
  })
  fluidRow(column(12, h4("Correlation between rasters"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("Correlation matrix",
                                                     DT::dataTableOutput("coor_mat")
                                            ),
                                            tabPanel("Correlation Plot",
                                                     plotOutput("coor_plot")
                                            )


           ),
           id = "tabs")
  )
})

Specdata<-reactive({
  dsf<-load.occ$select
  dsf<-dsf %>% dplyr::rename(lon=load.occ$lon,lat=load.occ$lat)
  dsf
})

Specdata_Presence<-reactive({
  dsf<-Specdata()
  dsf<-dsf[dsf[,ncol(dsf)] == 1,]
  sp::coordinates(dsf) <-~lon+lat
  sp::proj4string(dsf) <-raster::crs(data$Env)
  dsf
})

glc<-reactive({
  GLcenfa(x = data$Env)
})

mod.enfa<-reactive({
  pr<-Specdata_Presence()
  pr@data$load.occ$spec_select<-as.numeric(pr@data$load.occ$spec_select)
  CENFA::enfa(x = data$Env, s.dat = pr, field = load.occ$spec_select)
})

############ end ui correlation

####ui enfa

output$ui_enfa<-renderUI({
  glc <- glc()

  mod.enfa <- mod.enfa()
  if(brStick(s.factor(mod.enfa()))==1){

    output$enfa_scatter<-renderPlot({
      CENFA::scatter(x = mod.enfa,y = glc,n=nlayers(data$Env),p=1)
    })
  }
  else{
    observeEvent(input$number_spec,{

      output$enfa_scatter<-renderPlot({
        CENFA::scatter(x = mod.enfa,yax=as.numeric(input$number_spec),y = glc,n=nlayers(data$Env),p=1)

      })
    })
  }



  marg_spec<-reactive({
    mod.enfa <- mod.enfa()
    data.frame(mod.enfa@co)
  })

  output$marg<- DT::renderDataTable({
    datatable(marg_spec(),
              rownames = TRUE,
              selection="none",
              options = list(scrollX=TRUE, scrollY=250, lengthMenu=list(c(20, 50, 100, -1), c('20', '50', '100', 'All')), pageLength=20)

    )})
  txt_enfa_info<-paste0('The number of significant factors is',code(brStick(s.factor(mod.enfa()))))
  fluidRow(column(12, h4("Ecological Niche Factor Analysis"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("ENFA",
                                                     conditionalPanel(
                                                       condition = brStick(s.factor(mod.enfa()))>1,
                                                       selectInput('number_spec', 'Please select the number between 2 and the number of significant factors.', 2:brStick(s.factor(mod.enfa())), multiple = FALSE, selectize = TRUE)
                                                     ),
                                                     plotOutput("enfa_scatter"))
                                            ,
                                            tabPanel("Marginality and specialization",
                                                     p(HTML(txt_enfa_info)),
                                                     DT::dataTableOutput("marg")
                                            )),
                     id = "tabs")

  )
})

sac<-reactive({
  a = try(withProgress(message = 'Variables loading',
                       spatialAutoRange(rasterLayer = data$Env,
                                        doParallel = T,
                                        plotVariograms = TRUE,
                                        showPlots = FALSE)))
  a
})

range<-reactive({
  sac<-sac()
  round(sac$range,0)

})
output$ui_spatial_auto_range<-renderUI({


  tableRange<-reactive({
    sac<-sac()
    sac$rangeTable
  })




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
    a = try(withProgress(message = 'Variables loading',
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
    a

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
    Explorer(spatialblock, data$Env, pa_data(),load.occ$fold)
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
output$ui_preparation_main <- renderUI({
  out <- NULL
  val <- obj$cur_selection_results
  if (val=="btn_preparation_results_1") {
    return(uiOutput("ui_view_species_data"))
  }
  if (val=="btn_preparation_results_2") {
    return(uiOutput("ui_correlation"))
  }
  if (val=="btn_preparation_results_3") {
    return(uiOutput("ui_enfa"))
  }
  if (val=="btn_impute_results_4") {
    return(uiOutput("ui_spatial_auto_range"))
  }
  if (val=="btn_impute_results_5") {
    return(uiOutput("ui_spatial_blocks"))
  }

})

output$ui_preparation_sidebar_left <- renderUI({
  output$ui_sel_preparation_btns <- renderUI({
    cc1 <- c("Summarise")
    cc2 <- c("Correlation", "ENFA", "spatial autocorrelation", "spatial blocks")
    df <- data.frame(lab=c(cc1,cc2), header=NA)
    df$header[1] <- "View"
    df$header[2] <- "Spatial Analysis"
    out <- NULL
    for (i in 1:nrow(df)) {
      id <- paste0("btn_preparation_results_",i)
      if (obj$cur_selection_results==id) {
        style <- "primary"
      } else {
        style <- "default"
      }
      if (!is.na(df$header[i])) {
        out <- list(out, fluidRow(column(12, h4(df$header[i]), align="center")))
      }
      out <- list(out, fluidRow(
        column(12, bsButton(id, label=df$lab[i], block=TRUE, size="extra-small", style=style))
      ))
    }
    out
  })
  # required observers that update the color of the active button!
  eval(parse(text=genObserver_menus(pat="btn_preparation_results_", n=1:5, updateVal="cur_selection_results")))
  return(uiOutput("ui_sel_preparation_btns"))
})
output$ui_anonymize_noproblem <- renderUI({
  return(list(
    noInputData(uri="ui_preparation"),
    fluidRow(column(12, tags$br(), p(""), align="center"))
    #fluidRow(column(12, myActionButton("nodata_anonymize_uploadproblem", label="Upload a previously saved problem", btn.style="primary"), align="center"))
  ))
})
output$ui_preparation <- renderUI({
  if(length(input$Occ)==0){
    return(uiOutput("ui_anonymize_noproblem"))}
  else{
    fluidRow(
      column(2, uiOutput("ui_preparation_sidebar_left"), class="wb_sidebar"),
      column(10, uiOutput("ui_preparation_main"), class="wb-maincolumn"))
  }
}
)

#########################################
