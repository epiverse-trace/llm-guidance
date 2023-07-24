
<!-- README.md is generated from README.Rmd. Please edit that file. -->
<!-- The code to render this README is stored in .github/workflows/render-readme.yaml -->
<!-- Variables marked with double curly braces will be transformed beforehand: -->
<!-- `packagename` is extracted from the DESCRIPTION file -->
<!-- `gh_repo` is extracted via a special environment variable in GitHub Actions -->
<!-- # {{ packagename }} <img src="man/figures/logo.svg" align="right" width="120" /> -->
<!-- badges: start -->

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/license/mit/)
[![R-CMD-check](https://github.com/%7B%7B%20gh_repo%20%7D%7D/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/%7B%7B%20gh_repo%20%7D%7D/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/%7B%7B%20gh_repo%20%7D%7D/branch/main/graph/badge.svg)](https://app.codecov.io/gh/%7B%7B%20gh_repo%20%7D%7D?branch=main)
[![lifecycle-concept](https://raw.githubusercontent.com/reconverse/reconverse.github.io/master/images/badge-concept.svg)](https://www.reconverse.org/lifecycle.html#concept)
<!-- badges: end -->

This repository provides a concept of a Shiny application to explore use
of LLMs to provide guidance on packages and documentation. See the
[discussion
board](https://github.com/orgs/epiverse-trace/discussions/75) for more
information on the concept, as well as the issues page for current
design ideas.

## Installation

You can run a local version of the Shiny app (stored as `app.R`) with
the following code:

``` r
library(shiny); library(rsconnect)
setwd("~/Documents/GitHub/epiverse-trace/llm-guidance/R")
runApp()
```

You will need an [OpenAI API account](https://platform.openai.com/) to
run the app. The app sources your stored local credentials from
`data/credentials.csv`, where the `value` column defines the API key.

## Example

The `R_not_run/generate_doc_embeddings.R` script runs LLM embeddings for
local repositories (currently this points to:
`~/Documents/GitHub/epiverse-trace/` ).

## Development

### Lifecycle

This package is currently a *concept*, as defined by the [RECON software
lifecycle](https://www.reconverse.org/lifecycle.html). This means that
essential features and mechanisms are still being developed, and the
package is not ready for use outside of the development team.

### Contributions

Contributions are welcome via [pull
requests](https://github.com/%7B%7B%20gh_repo%20%7D%7D/pulls).

### Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/epiverse-trace/.github/blob/main/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
