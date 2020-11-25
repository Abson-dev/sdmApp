

#' Using the interactive GUI - sdmApp
#'
#' @return An interactive GUI
#' @export
#'
#'@import shiny
#'
#' @examples
#'
#' #load the package
#' library(sdmApp)
#' sdmApp()
sdmApp <-function()
{
  #ui
  ui<-navbarPage(id="cirad","SDMs GUI",theme = "readtable",
                 tabPanel("Help/About",
                          uiOutput("ui_about")),
                 tabPanel("Data Upload",uiOutput("ui_import_data")),
                 tabPanel("Spatial Analysis",uiOutput("ui_preparation")),
                 tabPanel("Modeling",uiOutput("ui_Models")),
                 tabPanel("R-Code")


  )

  #server
  server<-function(input, output, session){}

  #app
  shinyApp(ui, server)

}
