# Loaded once per R process, before ui.R and server.R. Only packages,
# helper functions and options live here: per-session state is created in
# server.R so that users of a shared deployment do not see each other's
# data.

library(shiny)

source("helpers.R", local = TRUE)
source(file.path("modules", "sdm_model.R"), local = TRUE)

# sdmApp() sets these shiny options before sourcing this file. When the app
# is deployed directly (for example on shiny-server), use the defaults.
if (!getShinyOption("sdmAppInvoked", FALSE)) {
  shinyOptions(.startdir = getwd())
  shinyOptions(.guitheme = "ihsn-root.css")
  shinyOptions(.guijsfile = NULL)
}

# Folder offered as the starting point of the file choosers: the example
# data shipped with the package.
example_data_dir <- system.file("extdata", package = "sdmApp")
