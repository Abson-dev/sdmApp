#' Start the sdmApp graphical user interface
#'
#' Launches the 'shiny' application that lets non-expert R users model
#' species distribution through a reproducible, point-and-click workflow.
#'
#' The interface relies on a number of modelling engines (for example
#' \pkg{SSDM}, \pkg{dismo}, \pkg{randomForest}, \pkg{kernlab} and
#' \pkg{CENFA}). Those packages are listed under `Suggests` to keep the
#' installation footprint small; [sdmApp()] checks that they are available
#' and returns an informative error listing anything missing.
#'
#' @param maxRequestSize Numeric. Maximum allowed size, in megabytes, for
#'   uploaded files. Defaults to 50.
#' @param debug Logical. If `TRUE`, enable 'shiny' debugging options
#'   (full stack trace and trace).
#' @param theme Character. Style sheet for the interface. One of
#'   `"IHSN"` (default), `"yeti"`, `"journal"` or `"flatly"`.
#' @param ... Further arguments (for example `host` or `port`) passed to
#'   [shiny::runApp()] when the application is launched.
#' @param shiny.server Logical. If `TRUE`, return the application as a
#'   [shiny::shinyApp()] object instead of launching it. Useful for
#'   deploying `sdmApp` behind shiny-server.
#'
#' @return If `shiny.server = TRUE`, a [shiny::shinyApp()] object.
#'   Otherwise the function is called for its side effect of starting the
#'   interactive interface and returns the value of [shiny::runApp()]
#'   invisibly.
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

  if (!is.numeric(maxRequestSize)) {
    stop("argument 'maxRequestSize' must be numeric.", call. = FALSE)
  }
  if (maxRequestSize < 1) {
    maxRequestSize <- 10
  }
  valid_themes <- c("yeti", "journal", "flatly", "IHSN")
  if (!theme %in% valid_themes) {
    stop("Invalid value for argument 'theme'. Use one of: ",
         paste(valid_themes, collapse = ", "), ".", call. = FALSE)
  }

  .sdmApp_check_deps()

  appDir <- system.file("shiny", "sdmApp", package = "sdmApp")
  if (identical(appDir, "")) {
    stop("Could not find the sdmApp Shiny directory. ",
         "Try re-installing the 'sdmApp' package.", call. = FALSE)
  }

  options(shiny.maxRequestSize = ceiling(maxRequestSize) * 1024^2)
  options(shiny.fullstacktrace = debug)
  options(shiny.trace = debug)

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

  shiny::shinyOptions(sdcAppInvoked = TRUE)
  source_from_appdir("global.R")
  shiny::shinyOptions(sdcAppInvoked = NULL)

  app <- shiny::shinyApp(
    ui     = source_from_appdir("ui.R"),
    server = source_from_appdir("server.R"),
    options = list(launch.browser = TRUE, ...)
  )

  if (shiny.server) {
    return(app)
  }
  invisible(shiny::runApp(app))
}

# Internal: verify that the suggested packages needed by the interface are
# installed, and stop with an actionable message otherwise.
.sdmApp_check_deps <- function() {
  needed <- c(
    "shinydashboard", "shinyBS", "shinyFiles", "rhandsontable", "DT",
    "ggcorrplot", "data.table", "dplyr", "tidyr", "haven", "readxl",
    "blockCV", "CENFA", "dismo", "SSDM", "randomForest", "kernlab",
    "automap", "rJava"
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
