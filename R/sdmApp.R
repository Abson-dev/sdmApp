#' Start the sdmApp graphical user interface
#'
#' Launches the 'shiny' application that lets non-expert R users model
#' species distribution through a reproducible, point-and-click workflow.
#'
#' The interface works on \pkg{terra} rasters and \pkg{sf} points and
#' relies on a number of modelling engines (\pkg{dismo},
#' \pkg{randomForest}, \pkg{kernlab}, \pkg{blockCV} and \pkg{CENFA}).
#' Those packages are listed under `Suggests` to keep the installation
#' footprint small; [sdmApp()] checks that they are available and returns an
#' informative error listing anything missing. \pkg{rJava} (and Java) is
#' only needed for the MaxEnt model.
#'
#' @param maxRequestSize Numeric. Maximum allowed size, in megabytes, for
#'   uploaded files. Must be a single positive number. Defaults to 50.
#' @param debug Logical. If `TRUE`, enable 'shiny' debugging options
#'   (full stack trace and trace).
#' @param theme Character. Style sheet for the interface. One of
#'   `"IHSN"` (default), `"yeti"`, `"journal"` or `"flatly"`.
#' @param ... Further options (for example `host`, `port` or
#'   `launch.browser`) passed to the `options` argument of
#'   [shiny::shinyApp()]. By default the app opens in a web browser.
#' @param shiny.server Logical. If `TRUE`, return the application as a
#'   [shiny::shinyApp()] object instead of launching it. Useful for
#'   deploying `sdmApp` behind shiny-server.
#'
#' @return If `shiny.server = TRUE`, a [shiny::shinyApp()] object.
#'   Otherwise the function is called for its side effect of starting the
#'   interactive interface and returns the value of [shiny::runApp()]
#'   invisibly. The global [options()] that `sdmApp()` sets
#'   (`shiny.maxRequestSize`, `shiny.fullstacktrace`, `shiny.trace`) are
#'   restored when the app stops.
#'
#' @author Aboubacar HEMA
#'
#' @importFrom shiny runApp shinyApp shinyOptions
#' @export
#'
#' @examples
#' if (interactive()) {
#'   library(sdmApp)
#'   sdmApp()
#' }
sdmApp <- function(maxRequestSize = 50, debug = FALSE, theme = "IHSN",
                   ..., shiny.server = FALSE) {

  size_ok <- is.numeric(maxRequestSize) && length(maxRequestSize) == 1L &&
    !is.na(maxRequestSize) && maxRequestSize > 0
  if (!size_ok) {
    stop("argument 'maxRequestSize' must be a single positive numeric ",
         "value (in megabytes).", call. = FALSE)
  }
  if (!is.logical(debug) || length(debug) != 1L || is.na(debug)) {
    stop("argument 'debug' must be TRUE or FALSE.", call. = FALSE)
  }
  valid_themes <- c("yeti", "journal", "flatly", "IHSN")
  theme_ok <- is.character(theme) && length(theme) == 1L &&
    theme %in% valid_themes
  if (!theme_ok) {
    stop("Invalid value for argument 'theme'. Use one of: ",
         paste(valid_themes, collapse = ", "), ".", call. = FALSE)
  }

  .sdmApp_check_deps()

  appDir <- system.file("shiny", "sdmApp", package = "sdmApp")
  if (identical(appDir, "")) {
    stop("Could not find the sdmApp Shiny directory. ",
         "Try re-installing the 'sdmApp' package.", call. = FALSE)
  }

  old_opts <- options(
    shiny.maxRequestSize = ceiling(maxRequestSize) * 1024^2,
    shiny.fullstacktrace = debug,
    shiny.trace = debug
  )
  # When the app is returned for deployment the options must stay in place;
  # otherwise put the user's options back once the app stops.
  if (!shiny.server) {
    on.exit(options(old_opts), add = TRUE)
  }

  shiny::shinyOptions(.startdir = getwd())
  shiny::shinyOptions(.appDir = appDir)

  guitheme <- switch(
    theme,
    yeti    = "bootswatch_yeti.css",
    journal = "bootswatch_journal.css",
    flatly  = "bootswatch_flatly.css",
    IHSN    = "ihsn-root.css"
  )
  shiny::shinyOptions(.guitheme = guitheme)
  shiny::shinyOptions(.guijsfile = NULL)

  source_from_appdir <- function(filename) {
    source(file.path(appDir, filename), local = parent.frame(),
           chdir = TRUE)$value
  }

  # global.R checks this flag to know it is being sourced by sdmApp() and
  # must not overwrite the theme chosen above with its deployment defaults.
  shiny::shinyOptions(sdmAppInvoked = TRUE)
  source_from_appdir("global.R")
  shiny::shinyOptions(sdmAppInvoked = NULL)

  app_options <- utils::modifyList(list(launch.browser = TRUE), list(...))
  app <- shiny::shinyApp(
    ui     = source_from_appdir("ui.R"),
    server = source_from_appdir("server.R"),
    options = app_options
  )

  if (shiny.server) {
    return(app)
  }
  invisible(shiny::runApp(app))
}

# Internal: verify that the suggested packages needed by the interface are
# installed, and stop with an actionable message otherwise.
.sdmApp_check_deps <- function() {
  # rJava is deliberately not listed: it is only needed by MaxEnt, which
  # reports a clear error in the interface when Java is unavailable.
  needed <- c(
    "shinyFiles", "DT", "ggcorrplot", "haven", "readxl", "highr", "terra",
    "sp", "blockCV", "automap", "CENFA", "dismo", "randomForest", "kernlab"
  )
  installed <- vapply(needed, requireNamespace, logical(1), quietly = TRUE)
  missing <- needed[!installed]
  if (length(missing) > 0L) {
    stop(
      "The sdmApp interface needs the following package",
      if (length(missing) > 1L) "s" else "",
      " which ",
      if (length(missing) > 1L) "are" else "is",
      " not installed:\n  ",
      paste(missing, collapse = ", "),
      "\n\nInstall with:\n  install.packages(c(",
      paste(sprintf('"%s"', missing), collapse = ", "),
      "))",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
