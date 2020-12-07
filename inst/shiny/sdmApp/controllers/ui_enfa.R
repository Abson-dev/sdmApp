Specdata<-reactive({
  dsf<-load.occ$select
  dsf<-dsf %>% dplyr::rename(lon=load.occ$lon,lat=load.occ$lat)
  dsf[,1]<-as.numeric(dsf[,1])
  dsf[,2]<-as.numeric(dsf[,2])
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
  fluidRow(column(12, h4("Ecological Niche Factor Analysis"),p("ENFA ((ecological-niche factor analysis, Hirzel et al.,
2002a)
) is based on the concept of the ecological niche, and provides a measure of the realised niche within the available space from
the computation of two parameters, the marginality and the specialization.
"), align="center"),
           mainPanel(width = 8, tabsetPanel(type = "tabs",
                                            tabPanel("ENFA",
                                                     conditionalPanel(
                                                       condition = brStick(s.factor(mod.enfa()))>1,
                                                       p(HTML(txt_enfa_info)),
                                                       selectInput('number_spec', 'Please select a number between 2 and the number of significant factors.', 2:brStick(s.factor(mod.enfa())), multiple = FALSE, selectize = TRUE)
                                                     ),
                                                     plotOutput("enfa_scatter"))
                                            ,
                                            tabPanel("Marginality and specialization",

                                                     DT::dataTableOutput("marg")
                                            )),
                     id = "tabs")

  )
})
