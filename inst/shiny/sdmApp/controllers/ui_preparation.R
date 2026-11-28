# Spatial Analysis tab: left-hand menu and dispatch to the sub-pages.

preparation_items <- data.frame(
  label = c(
    "Summary", "Correlation", "ENFA", "Spatial autocorrelation",
    "Spatial blocking"
  ),
  header = c("View", "Spatial Analysis", NA, NA, NA)
)
preparation_pages <- c(
  "ui_view_species_data", "ui_correlation", "ui_enfa",
  "ui_spatial_auto_range", "ui_spatial_blocks"
)

register_menu("btn_preparation_", nrow(preparation_items), "preparation")

output$ui_preparation_sidebar_left <- renderUI({
  menu_ui("btn_preparation_", preparation_items, "preparation")
})

output$ui_preparation_main <- renderUI({
  i <- as.integer(sub("btn_preparation_", "", ui_state$preparation))
  uiOutput(preparation_pages[[i]])
})

output$ui_preparation <- renderUI({
  if (!has_data()) {
    return(no_data_ui())
  }
  fluidRow(
    column(2, uiOutput("ui_preparation_sidebar_left"), class = "wb_sidebar"),
    column(10, uiOutput("ui_preparation_main"), class = "wb-maincolumn")
  )
})
