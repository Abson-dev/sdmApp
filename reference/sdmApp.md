# Start the sdmApp graphical user interface

Launches the 'shiny' application that lets non-expert R users model
species distribution through a reproducible, point-and-click workflow.

## Usage

``` r
sdmApp(
  maxRequestSize = 50,
  debug = FALSE,
  theme = "IHSN",
  ...,
  shiny.server = FALSE
)
```

## Arguments

- maxRequestSize:

  Numeric. Maximum allowed size, in megabytes, for uploaded files.
  Defaults to 50.

- debug:

  Logical. If `TRUE`, enable 'shiny' debugging options (full stack trace
  and trace).

- theme:

  Character. Style sheet for the interface. One of `"IHSN"` (default),
  `"yeti"`, `"journal"` or `"flatly"`.

- ...:

  Further arguments (for example `host` or `port`) passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) when
  the application is launched.

- shiny.server:

  Logical. If `TRUE`, return the application as a
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html)
  object instead of launching it. Useful for deploying `sdmApp` behind
  shiny-server.

## Value

If `shiny.server = TRUE`, a
[`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html)
object. Otherwise the function is called for its side effect of starting
the interactive interface and returns the value of
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html)
invisibly.

## Details

The interface relies on a number of modelling engines (for example SSDM,
dismo, randomForest, kernlab and CENFA). Those packages are listed under
`Suggests` to keep the installation footprint small; `sdmApp()` checks
that they are available and returns an informative error listing
anything missing.

## Author

Aboubacar HEMA

## Examples

``` r
if (interactive()) {
  library(sdmApp)
  sdmApp()
}
```
