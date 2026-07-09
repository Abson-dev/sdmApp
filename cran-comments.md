## Test environments

* local install, R release
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1),
  windows-latest (release), macos-latest (release)
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes for the maintainer

* This release removes the archived `rgdal` and `rgeos` dependencies and
  moves runtime dependencies of the exported functions into `Imports`.
* The shiny interface uses several modelling engines that are declared in
  `Suggests`; `sdmApp()` checks for them at launch and fails gracefully
  when they are absent, so examples and tests run without them.
