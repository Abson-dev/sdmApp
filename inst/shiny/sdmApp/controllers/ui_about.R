# Help/About tab.

output$ui_about <- renderUI({
  fluidRow(
    column(width = 8, offset = 2, h2("sdmApp")),
    column(width = 8, offset = 2, p(
      "sdmApp is an R package containing a 'shiny' application that allows",
      "non-expert R users to easily model species distribution. It offers a",
      "reproducible workflow for species distribution modelling in a single",
      "and user-friendly environment. sdmApp takes raster data (in any",
      "format supported by the terra package) and species occurrence data",
      "(several formats supported) as input."
    )),
    column(width = 8, offset = 2, h4("Workflow")),
    column(width = 8, offset = 2, tags$ol(
      tags$li("Data Upload: load the environmental rasters and occurrences."),
      tags$li(
        "Spatial Analysis: inspect correlation, run the ENFA, and build",
        "spatial blocks for cross-validation."
      ),
      tags$li("Modeling: fit, evaluate and map one of seven models."),
      tags$li("R-Code: download a script that reloads your data.")
    )),
    column(width = 8, offset = 2, h4("Contact and feedback")),
    column(width = 8, offset = 2, p(
      "Suggestions and bug reports are welcome on the",
      tags$a("issue tracker",
        href = "https://github.com/Abson-dev/sdmApp/issues",
        target = "_blank"
      ), "."
    ))
  )
})
