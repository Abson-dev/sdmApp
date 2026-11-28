# Spatial Analysis > Summary: overview of the loaded data.

output$sumlayers <- DT::renderDataTable({
  DT::datatable(env_summary(env()),
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

output$occ_data_select <- DT::renderDataTable({
  req(occ_state$table)
  cols <- c(occ_state$lon, occ_state$lat, occ_state$species)
  DT::datatable(occ_state$table[, cols, drop = FALSE],
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

output$SpeciesTable <- DT::renderDataTable({
  req(occ_state$table)
  cols <- c(occ_state$lon, occ_state$lat, occ_state$species)
  DT::datatable(occ_summary(occ_state$table[, cols, drop = FALSE]),
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

output$ui_view_species_data <- renderUI({
  occ <- occ_sf()
  n_presence <- sum(occ[[species()]] == 1)
  fluidRow(mainPanel(width = 8, tabsetPanel(
    type = "tabs",
    tabPanel(
      "Environmental data summary",
      p(env_description(env())),
      DT::dataTableOutput("sumlayers")
    ),
    tabPanel(
      "Occurrence data",
      p(sprintf(
        "%d points for '%s': %d presences and %d absences.",
        nrow(occ), species(), n_presence, nrow(occ) - n_presence
      )),
      DT::dataTableOutput("occ_data_select")
    ),
    tabPanel(
      "Occurrence data summary",
      DT::dataTableOutput("SpeciesTable")
    )
  )))
})
