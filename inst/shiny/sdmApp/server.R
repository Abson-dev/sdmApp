# server.R is always sourced from the app directory (sdmApp() uses
# chdir = TRUE, and shiny-server runs apps from their folder).
app_dir <- getwd()

function(input, output, session) {
  # Per-session state ---------------------------------------------------------

  env_state <- reactiveValues(env = NULL, paths = NULL)
  occ_state <- reactiveValues(
    table = NULL, path = NULL, lon = NULL, lat = NULL, species = NULL
  )
  spatial_state <- reactiveValues(autocor = NULL, blocks = NULL)
  ui_state <- reactiveValues(
    preparation = "btn_preparation_1",
    models = "btn_models_1"
  )

  # Shared reactives ----------------------------------------------------------

  env <- reactive({
    req(env_state$env)
  })

  species <- reactive({
    req(occ_state$species)
  })

  occ_sf <- reactive({
    req(occ_state$table, occ_state$species)
    occ_as_sf(
      occ_state$table, occ_state$lon, occ_state$lat, occ_state$species,
      terra::crs(env())
    )
  })

  has_data <- reactive({
    !is.null(env_state$env) && !is.null(occ_state$species)
  })

  # Ecological-niche factor analysis (CENFA works on raster/sp objects).
  enfa <- reactive({
    req(has_data())
    withProgress(message = "Ecological-niche factor analysis", {
      env_raster <- env_as_raster(env())
      fit <- CENFA::enfa(
        x = env_raster,
        s.dat = presence_as_spatial(occ_sf(), species()),
        field = species()
      )
      list(
        fit = fit,
        glc = CENFA::GLcenfa(x = env_raster),
        n_factors = CENFA::brStick(CENFA::s.factor(fit))
      )
    })
  })

  draw_enfa <- function(yax = 2) {
    e <- enfa()
    CENFA::scatter(
      x = e$fit, y = e$glc, n = terra::nlyr(env()), p = 1, yax = yax
    )
  }

  # Shared UI helpers ---------------------------------------------------------

  no_data_ui <- function() {
    fluidRow(
      column(12, h3("No environmental variables or occurrence data available!"),
        class = "wb-header"
      ),
      column(12, p("Go to the Data Upload tab to load data."),
        class = "wb-header-hint"
      )
    )
  }

  # Vertical menu of buttons. `items` is a data frame with columns `label`
  # and `header` (NA when no header precedes the button). The active button,
  # stored in ui_state[[key]], is highlighted.
  menu_ui <- function(prefix, items, key) {
    out <- list()
    for (i in seq_len(nrow(items))) {
      id <- paste0(prefix, i)
      if (!is.na(items$header[[i]])) {
        header <- column(12, h4(items$header[[i]]), align = "center")
        out <- c(out, list(fluidRow(header)))
      }
      active <- identical(ui_state[[key]], id)
      style <- if (active) "btn-primary" else "btn-default"
      button <- actionButton(id, items$label[[i]],
        class = paste("btn-xs btn-block", style)
      )
      out <- c(out, list(fluidRow(column(12, button))))
    }
    tagList(out)
  }

  register_menu <- function(prefix, n, key) {
    lapply(seq_len(n), function(i) {
      id <- paste0(prefix, i)
      observeEvent(input[[id]], {
        ui_state[[key]] <- id
      })
    })
    invisible(NULL)
  }

  datatable_options <- list(
    scrollX = TRUE, scrollY = 250, pageLength = 20,
    lengthMenu = list(c(20, 50, 100, -1), c("20", "50", "100", "All"))
  )

  # Controllers ---------------------------------------------------------------

  for (file in list.files(file.path(app_dir, "controllers"),
    pattern = "[.]R$", full.names = TRUE
  )) {
    source(file, local = TRUE)
  }
}
