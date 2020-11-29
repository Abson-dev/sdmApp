library(shiny)

shinyServer(function(session, input, output) {
  wd <- setwd(getShinyOption(".appDir", getwd()))
  on.exit(setwd(wd))

  for (file in list.files("controllers")) {
    source(file.path("controllers", file), local=TRUE)
  }
  values <- reactiveValues(starting = TRUE)
  session$onFlushed(function() {
    values$starting <- FALSE
  })
})
