# Modeling tab: one sdm_model module per method, plus the left-hand menu.

model_methods <- sdm_methods()
model_items <- data.frame(
  label = model_methods$label,
  header = ifelse(duplicated(model_methods$group), NA, model_methods$group)
)

register_menu("btn_models_", nrow(model_items), "models")

spatial_folds <- reactive(spatial_state$blocks)

model_fits <- lapply(model_methods$id, function(method) {
  sdm_model_server(
    id = method,
    method = method,
    env = env,
    occ = occ_sf,
    species = species,
    spatial_cv = spatial_folds,
    draw_enfa = draw_enfa
  )
})
names(model_fits) <- model_methods$id

output$ui_models_sidebar_left <- renderUI({
  menu_ui("btn_models_", model_items, "models")
})

output$ui_models_main <- renderUI({
  i <- as.integer(sub("btn_models_", "", ui_state$models))
  sdm_model_ui(model_methods$id[[i]], model_methods$id[[i]], names(env()))
})

output$ui_Models <- renderUI({
  if (!has_data()) {
    return(no_data_ui())
  }
  fluidRow(
    column(2, uiOutput("ui_models_sidebar_left"), class = "wb_sidebar"),
    column(10, uiOutput("ui_models_main"), class = "wb-maincolumn")
  )
})
