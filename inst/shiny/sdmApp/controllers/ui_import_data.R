# Data Upload tab: environmental rasters and species occurrences.

file_roots <- c(
  Examples = example_data_dir,
  Home = normalizePath("~", winslash = "/", mustWork = FALSE),
  shinyFiles::getVolumes()()
)

shinyFiles::shinyFileChoose(input, "envfiles",
  session = session,
  roots = file_roots, filetypes = raster_file_types()
)
shinyFiles::shinyFileChoose(input, "occ_file",
  session = session,
  roots = file_roots, filetypes = unname(occurrence_file_types())
)

selected_env_paths <- reactive({
  req(is.list(input$envfiles))
  shinyFiles::parseFilePaths(file_roots, input$envfiles)$datapath
})

output$factors <- renderUI({
  layer_names <- tools::file_path_sans_ext(basename(selected_env_paths()))
  selectInput("factors", "Categorical layers", layer_names,
    multiple = TRUE, selectize = TRUE
  )
})

output$env_files <- renderUI({
  paths <- selected_env_paths()
  p(length(paths), "file(s) selected:", paste(basename(paths), collapse = ", "))
})

observeEvent(input$load_env, {
  paths <- selected_env_paths()
  categorical <- if (input$categorical_var == "Categorical") input$factors
  env <- tryCatch(
    withProgress(
      message = "Loading environmental variables",
      read_env_layers(paths, categorical = categorical)
    ),
    error = function(e) e
  )
  if (inherits(env, "error")) {
    output$env_error <- renderUI(p(
      class = "text-danger",
      "Loading the environmental variables failed:", conditionMessage(env)
    ))
    return()
  }
  output$env_error <- renderUI(NULL)
  env_state$env <- env
  env_state$paths <- paths
  updateSelectInput(session, "layer", choices = names(env))
})

output$env_info <- renderUI({
  if (is.null(env_state$env)) {
    return(p("No environmental variables loaded yet."))
  }
  p(env_description(env_state$env))
})

plot_options <- reactive({
  keys <- c(
    "label_axes", "lab_x", "lab_y", "add_title", "title", "adj_fnt_sz",
    "fnt_sz_ttl", "fnt_sz_ax", "adj_fnt", "font", "rot_txt", "adj_grd",
    "grd_maj", "grd_min", "theme", "adj_leg", "leg_ttl", "pos_leg"
  )
  stats::setNames(lapply(keys, function(k) input[[k]]), keys)
})

env_plot <- reactive({
  req(input$layer, input$layer %in% names(env()))
  style_plot(plot_env_layer(env()[[input$layer]]), plot_options())
})

output$env <- renderPlot(
  width = function() if (isTRUE(input$fig_size)) input$fig_width else "auto",
  height = function() if (isTRUE(input$fig_size)) input$fig_height else 400,
  {
    env_plot()
  }
)

output$down <- downloadHandler(
  filename = function() paste(input$layer, input$plot_type, sep = "."),
  content = function(file) save_plot(file, env_plot(), input$plot_type)
)

# Occurrences ---------------------------------------------------------------

selected_occ <- reactive({
  req(is.list(input$occ_file))
  path <- shinyFiles::parseFilePaths(file_roots, input$occ_file)$datapath
  req(length(path) == 1)
  list(path = path, type = occurrence_type(path))
})

occ_preview <- reactive({
  occ <- selected_occ()
  tryCatch(
    read_occurrences(occ$path, occ$type, sep = input$sep, dec = input$dec),
    error = function(e) e
  )
})

output$occ_error <- renderUI({
  x <- occ_preview()
  if (inherits(x, "error")) {
    p(
      class = "text-danger", "Reading the occurrence file failed:",
      conditionMessage(x)
    )
  }
})

output$occ_columns <- renderUI({
  x <- occ_preview()
  req(is.data.frame(x))
  cols <- names(x)
  tagList(
    selectInput("Xcol", "Longitude (X)", cols, selected = cols[1]),
    selectInput("Ycol", "Latitude (Y)", cols,
      selected = cols[min(2, length(cols))]
    ),
    selectInput("Pcol", "Species column (0 = absence, 1 = presence)", cols,
      selected = cols[min(3, length(cols))]
    )
  )
})

output$occ <- DT::renderDataTable({
  x <- occ_preview()
  req(is.data.frame(x))
  DT::datatable(x,
    rownames = FALSE, selection = "none", options = datatable_options
  )
})

observeEvent(input$load_occ, {
  if (is.null(env_state$env)) {
    showNotification("Load the environmental variables first.",
      type = "warning"
    )
    return()
  }
  x <- occ_preview()
  req(is.data.frame(x), input$Xcol, input$Ycol, input$Pcol)
  check <- tryCatch(
    occ_as_sf(x, input$Xcol, input$Ycol, input$Pcol, terra::crs(env())),
    error = function(e) e
  )
  if (inherits(check, "error")) {
    showNotification(conditionMessage(check), type = "error", duration = NULL)
    return()
  }
  occ_state$table <- x
  occ_state$path <- selected_occ()$path
  occ_state$lon <- input$Xcol
  occ_state$lat <- input$Ycol
  occ_state$species <- input$Pcol
  spatial_state$autocor <- NULL
  spatial_state$blocks <- NULL
  showNotification(
    sprintf(
      "Loaded %d occurrence points for '%s'.", nrow(check), input$Pcol
    ),
    type = "message"
  )
})

# UI ------------------------------------------------------------------------

aesthetics_panel <- tabsetPanel(
  tabPanel(
    "Text",
    checkboxInput("label_axes", strong("Change labels axes"), FALSE),
    conditionalPanel(
      "input.label_axes == true",
      textInput("lab_x", "X-axis:", "Longitude"),
      textInput("lab_y", "Y-axis:", "Latitude")
    ),
    checkboxInput("add_title", strong("Add title"), FALSE),
    conditionalPanel(
      "input.add_title == true",
      textInput("title", "Title:", "Title")
    ),
    checkboxInput("adj_fnt_sz", strong("Change font size"), FALSE),
    conditionalPanel(
      "input.adj_fnt_sz == true",
      numericInput("fnt_sz_ttl", "Size axis titles:", 12),
      numericInput("fnt_sz_ax", "Size axis labels:", 10)
    ),
    checkboxInput("rot_txt", strong("Rotate text x-axis"), FALSE),
    checkboxInput("adj_fnt", strong("Change font"), FALSE),
    conditionalPanel(
      "input.adj_fnt == true",
      selectInput("font", "Font", c("Courier", "Helvetica", "Times"),
        selected = "Helvetica"
      )
    )
  ),
  tabPanel(
    "Theme",
    checkboxInput("adj_grd", strong("Remove gridlines"), FALSE),
    conditionalPanel(
      "input.adj_grd",
      checkboxInput("grd_maj", strong("Remove major gridlines"), FALSE),
      checkboxInput("grd_min", strong("Remove minor gridlines"), FALSE)
    ),
    selectInput("theme", "Theme",
      c(
        bw = "bw", classic = "classic", dark = "dark", grey = "grey",
        light = "light", line_draw = "linedraw", minimal = "minimal"
      ),
      selected = "bw"
    )
  ),
  tabPanel(
    "Legend",
    radioButtons("adj_leg", NULL,
      c("Keep legend as it is", "Remove legend", "Change legend"),
      selected = "Keep legend as it is"
    ),
    conditionalPanel(
      "input.adj_leg == 'Change legend'",
      textInput("leg_ttl", "Title legend:", "title legend"),
      selectInput(
        "pos_leg", "Position legend",
        c("right", "left", "top", "bottom")
      )
    )
  ),
  tabPanel(
    "Size",
    checkboxInput("fig_size", strong("Adjust plot size on screen"), FALSE),
    conditionalPanel(
      "input.fig_size",
      numericInput("fig_height", "Plot height (# pixels):", 400),
      numericInput("fig_width", "Plot width (# pixels):", 480)
    )
  )
)

output$ui_import_data <- renderUI({
  tagList(
    fluidRow(
      column(12, h3("Uploading environmental variables and occurrence data"),
        class = "wb-header"
      ),
      column(12, p(
        "First load the raster files (environmental variables), then the",
        "species occurrence file. Example data are available under",
        "'Examples' in the file choosers."
      ), class = "wb-header-hint")
    ),
    fluidRow(
      sidebarPanel(
        width = 3,
        h4("Environmental variables"),
        uiOutput("env_error"),
        shinyFiles::shinyFilesButton("envfiles", "Raster selection",
          "Please select rasters",
          multiple = TRUE
        ),
        uiOutput("env_files"),
        selectInput(
          "categorical_var", "Categorical variable",
          c(No = "No categorical", Yes = "Categorical")
        ),
        conditionalPanel(
          "input.categorical_var == 'Categorical'",
          uiOutput("factors")
        ),
        actionButton("load_env", "Load data", class = "btn-primary")
      ),
      mainPanel(
        width = 6,
        tabsetPanel(
          type = "tabs",
          tabPanel("About", uiOutput("env_info")),
          tabPanel(
            "Plot",
            selectInput("layer", "Variable",
              choices = isolate(names(env_state$env))
            ),
            radioButtons("plot_type", "Select the file type", c("png", "pdf"),
              inline = TRUE
            ),
            downloadButton("down", "Download"),
            plotOutput("env")
          )
        )
      ),
      sidebarPanel(width = 3, h4("Change aesthetics"), aesthetics_panel)
    ),
    fluidRow(
      sidebarPanel(
        width = 3,
        h4("Occurrence data"),
        p(
          "Supported files: csv/txt, Excel (xlsx, xls), SPSS (sav, zsav,",
          "por), Stata (dta) and SAS (sas7bdat)."
        ),
        shinyFiles::shinyFilesButton("occ_file", "Occurrence selection",
          "Please select the occurrence file",
          multiple = FALSE
        ),
        uiOutput("occ_error"),
        radioButtons("sep", "Separator (text files)",
          c(Comma = ",", Semicolon = ";", Tab = "\t", "White space" = " "),
          selected = ";", inline = TRUE
        ),
        radioButtons("dec", "Decimal (text files)", c(Point = ".", Comma = ","),
          selected = ",", inline = TRUE
        ),
        uiOutput("occ_columns"),
        actionButton("load_occ", "Load data", class = "btn-primary")
      ),
      mainPanel(
        width = 9,
        tabsetPanel(
          type = "tabs",
          tabPanel("Preview", DT::dataTableOutput("occ"))
        )
      )
    )
  )
})
