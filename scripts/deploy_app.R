# - - - - - - - - - - - - - - - - - - - - - - - 
# Test app outputs
# - - - - - - - - - - - - - - - - - - - - - - -

# Load credentials and libraries
library(shiny); library(rsconnect)

setwd("~/Documents/GitHub/epiverse-trace/llm-guidance/demo/package_app")
#setwd("~/Documents/GitHub/epiverse-trace/llm-guidance/demo/embedding_app")

# Run app locally
runApp()

# Deploy test app
deployApp(account = "kucharski", appName = "embedding_app",lint=F)
