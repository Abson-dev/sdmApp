#### domain contents ###

output$ui_domain<-renderUI({

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
  enfa_plot<-reactive({
    glc <- glc()

    mod.enfa <- mod.enfa()
    CENFA::scatter(x = mod.enfa, y = glc,n=nlayers(data$Env),p=1)
  })
  output$enfa_var<-renderPlot({
    enfa_plot()
  })

  observeEvent(input$Domain,{
    validate(
      need(length(input$var_expl_Domain) > 0, 'Choose specie predictors first !')
    )

    data$enfa<-raster::subset(data$Env,input$var_expl_Domain)
    Specdata<-Specdata()
    set.seed(1994)
    fold<-dismo::kfold(Specdata,input$number_no_block_fold_Domain)
    #fold<-kfold()
    model<-list()
    evaluate_model<-list()
    for (i in 1:5) {
      p<-Specdata[Specdata[fold != i,ncol(Specdata)] == 1, 1:(ncol(Specdata)-1)]
      a<-Specdata[Specdata[fold != i,ncol(Specdata)] == 0, 1:(ncol(Specdata)-1)]
      occtest<-Specdata[Specdata[fold == i,ncol(Specdata)] == 1, 1:(ncol(Specdata)-1)]

      bgtest<-Specdata[Specdata[fold == i,ncol(Specdata)] == 0, 1:(ncol(Specdata)-1)]
      model[[i]] <- dismo::domain(data$enfa, p) #, factors='Sol'
      evaluate_model[[i]] <- evaluate(occtest, bgtest, model[[i]], data$enfa)

    }
    model_pred<-list()
    auc <- sapply(evaluate_model, function(x){x@auc})
    model_pred[["espece"]]<-predict(data$enfa, model[[which.max(auc)]])
    model_pred[["AUC"]]<-auc[which.max(auc)]
    model_pred[["threshold"]]<- threshold(evaluate_model[[which.max(auc)]], 'spec_sens')
    model_pred[["PresenceAbsence"]]<-model_pred[["espece"]]>model_pred[["threshold"]]
    model_pred[["ProbaPresence"]]<-TimesRasters(model_pred[["espece"]],model_pred[["PresenceAbsence"]])

    observeEvent(input$probaplot_Domain,{
      if(input$probaplot_Domain=='Probability of occurence(absence/presence)'){
        title_probaplot_Domain<-'Probability of occurence(absence/presence)'
        map<-model_pred[["espece"]]}
      if(input$probaplot_Domain=='Presence/Absence'){
        title_probaplot_Domain<-'Presence/Absence'
        map<-model_pred[["PresenceAbsence"]]

      }
      if(input$probaplot_Domain=='Probability of occurence(presence)'){
        title_probaplot_Domain<-'Probability of occurence(presence)'
        map<-model_pred[["ProbaPresence"]]
      }
      output$proba_occ_Domain<-renderPlot({
        if(title_probaplot_Domain=='Presence/Absence'){PASpecies(map)}
        else{
          ggR_P(map)
        }

      })
    })
    observeEvent(input$model_ev_Domain,{
      if(input$model_ev_Domain == 'ROC') {ev<-'ROC'}
      if(input$model_ev_Domain == 'density') {ev<-'density'}
      if(input$model_ev_Domain == 'boxplot') {ev<-'boxplot'}
      if(input$model_ev_Domain == 'kappa') {ev<-'kappa'}
      if(input$model_ev_Domain == 'FPR') {ev<-'FPR'}
      if(input$model_ev_Domain == 'prevalence') {ev<-'prevalence'}
      output$eval_Domain<-renderPlot({
        if(ev=='density'){density(evaluate_model[[which.max(auc)]])}
        else{
          if(ev=='boxplot'){boxplot(evaluate_model[[which.max(auc)]], col=c('red', 'green'),xlab=load.occ$spec_select)}
          else{
            plot(evaluate_model[[which.max(auc)]],ev)
          }
        }


      })
    })
    observeEvent(input$response_var_Domain,{
      output$response_eco_Domain<-renderPlot({
        dismo::response(model[[which.max(auc)]],var=input$response_var_Domain,main=load.occ$spec_select)
      })
    })
    output$var_importance_Domain<-renderPlot({
      plot(model[[which.max(auc)]], main=load.occ$spec_select,xlab="Purcentage(%)")
    })
  })


  out <- NULL
  txt_setup<-'The Domain algorithm computes the Gower distance between environmental variables at any location and those at any of the known locations of occurrence (training sites).'
  out <- fluidRow(
    column(width = 12, offset = 0, h3("Domain"), class="wb-header"),
    column(width = 12, offset = 0, p("The first step is to choose specie predictors accordint to ENFA or other source, afther apply Domain method."), class="wb-header-hint"),
    fluidRow(column(12, h4("Read Me", tipify(icon("info-circle"), title=txt_setup, placement="bottom"), class="wb-block-title"), align="center"))
  )
  out<-list(out,
            sidebarPanel(
              selectInput("choice_block_Domain", "Please Choose your model technic (without spatial blocking or with spatial blocking)",
                          c(without="Modelling without spatial blocking",with="Modelling with spatial blocking")
              ),
              conditionalPanel(
                condition = "input.choice_block_Domain == 'Modelling without spatial blocking'",
                sliderInput("number_no_block_fold_Domain", "Please set the number of fold", min = 1, max = 100, value = 5)
              )),
            conditionalPanel(
              condition = "input.choice_block_Domain == 'Modelling without spatial blocking'",
              mainPanel(width = 6, tabsetPanel(type = "tabs",
                                               tabPanel("Specie predictors",
                                                        selectInput('var_expl_Domain', 'Please select the specie predictors', names(data$Env), multiple = TRUE, selectize = TRUE),
                                                        myActionButton("Domain",label=("Apply Domain"), "primary"),
                                                        plotOutput("enfa_var")
                                               ),
                                               tabPanel("Map",

                                                        selectInput('probaplot_Domain', '', c("Probability of occurence(absence/presence)","Presence/Absence","Probability of occurence(presence)"), multiple = FALSE, selectize = TRUE),
                                                        plotOutput("proba_occ_Domain")

                                               ),
                                               tabPanel("Model Evaluation",
                                                        selectInput('model_ev_Domain', 'Please select the metric to evaluate the model', c("ROC","density","boxplot","kappa","FPR","prevalence"), multiple = FALSE, selectize = TRUE),
                                                        plotOutput("eval_Domain")
                                               ),
                                               tabPanel("Variable response",
                                                        selectInput('response_var_Domain', 'Please select the variable to get its ecological response', names(data$enfa), multiple = FALSE, selectize = TRUE),
                                                        plotOutput("response_eco_Domain")
                                               ),
                                               tabPanel("Variable Importance",
                                                        plotOutput("var_importance_Domain")
                                               )


              ),
              id = "tabs"))
  )
  out
})
#### end domain ###