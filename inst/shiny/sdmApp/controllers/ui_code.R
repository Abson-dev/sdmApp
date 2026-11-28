# R-Code tab: an R script reproducing the data loading done in the app.

current_code <- reactive({
  lines <- c(
    paste("# Created with sdmApp", utils::packageVersion("sdmApp")),
    "library(sdmApp)",
    ""
  )
  if (!is.null(env_state$paths)) {
    lines <- c(
      lines,
      "# Environmental variables",
      sprintf(
        "env <- terra::rast(c(\n  %s\n))",
        paste(dQuote(env_state$paths, FALSE), collapse = ",\n  ")
      ),
      ""
    )
  }
  if (!is.null(occ_state$path)) {
    lines <- c(
      lines,
      "# Species occurrences",
      if (occurrence_type(occ_state$path) == "text") {
        sprintf(
          "occ <- read.table(%s, header = TRUE, sep = %s, dec = %s)",
          dQuote(occ_state$path, FALSE), dQuote(input$sep, FALSE),
          dQuote(input$dec, FALSE)
        )
      } else {
        reader <- switch(occurrence_type(occ_state$path),
          Excel = "readxl::read_excel",
          SPSS = "haven::read_sav",
          Stata = "haven::read_dta",
          SAS = "haven::read_sas"
        )
        sprintf(
          "occ <- as.data.frame(%s(%s))", reader,
          dQuote(occ_state$path, FALSE)
        )
      },
      sprintf(
        "occ <- sf::st_as_sf(occ, coords = c(%s, %s), crs = terra::crs(env))",
        dQuote(occ_state$lon, FALSE), dQuote(occ_state$lat, FALSE)
      ),
      ""
    )
  }
  lines
})

output$current_code <- renderUI({
  HTML(paste0(
    "<pre class='r'><code class='r' id='codeout'>",
    paste(highr::hi_html(current_code()), collapse = "\n"),
    "</code></pre>"
  ))
})

output$btn_save_script <- downloadHandler(
  filename = function() "sdmApp_script.R",
  content = function(file) writeLines(current_code(), file)
)

output$ui_code <- renderUI({
  if (!has_data()) {
    return(no_data_ui())
  }
  fluidRow(
    column(12, h3("View the current generated script"), class = "wb-header"),
    column(12, p(
      "Browse and download the script that loads your data, as a starting",
      "point for reproducing your analysis from the R command line."
    ), class = "wb-header-hint"),
    column(12,
      downloadButton("btn_save_script", "Save script to file",
        class = "btn-primary"
      ),
      align = "center"
    ),
    column(12, tags$br(), uiOutput("current_code"))
  )
})
