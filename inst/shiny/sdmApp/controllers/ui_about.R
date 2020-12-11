output$ui_about <- renderUI({
  out <- fluidRow(
    column(width = 8, offset = 2, h2(("sdmApp"))),
    column(width = 8, offset = 2, tags$img(src=paste0(system.file("docs", package = "sdmApp"),"Logo_sdmApp.png"),height=50,width=50)),
    column(width = 8, offset = 2, p("sdmApp is a R package containing a shiny application that allows non-expert R users to easily model species distribution. It offers a reproducible worklow for species distribution modelling into a single and user friendly environment. sdmApp takes raster data (in format supported by the raster package) and species occurrence data (several format supported) as input argument. the sdmApp provides an interactive, graphical user interface (GUI).",tags$a("GitHub pages", href="https://github.com/Abson-dev/sdmApp", target="_blank"))
    ))

  out <- list(out, fluidRow(
    column(width = 8, offset = 2, h4(("Contact and Feedback"))),
    column(width = 8, offset = 2, p("In case you have any suggestions or bug reports, please file an issue at the",
                                    tags$a("issue tracker", href="https://github.com/Abson-dev", target="_blank"),"in our",
                                    tags$a("GitHub repo", href="https://github.com/Abson-dev", target="_blank"),".")),
    column(width = 8, offset = 2, p("Before reporting any bugs, please make sure that you are working with an up-to-date",tags$b("R"),"installation and
                                        that all packages have been updated. You can do so by entering",code("update.packages(ask=FALSE)"),"into your",code("R"),"prompt."))
  ))
  out
})
