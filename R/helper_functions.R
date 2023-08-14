# Code to generate token by token - not currently working

install.packages("httr")
install.packages("jsonlite")

library(httr)
library(jsonlite)

generate_token_by_token <- function(prompt, max_tokens = 1, model="text-davinci-002") {
  url <- "https://api.openai.com/v1/engines/text-davinci-002/completions"
  headers <- add_headers(
    "Authorization" = paste("Bearer", credential_load$value),
    "Content-Type" = "application/json",
    "Accept" = "application/json"
  )
  
  response <- POST(
    url = url,
    headers,
    body = toJSON(list(prompt = prompt, max_tokens = max_tokens, model = model)),
    encode = "json"
  )
  
  content <- fromJSON(content(response, "text", encoding="UTF-8"))
  return(content$choices[[1]]$text)
}

prompt <- "Once upon a time"
token_count <- 10  # Generate 10 tokens
output <- ""

for(i in 1:token_count) {
  new_token <- generate_token_by_token(prompt, 1)
  output <- paste0(output, new_token)
  #prompt <- output
  Sys.sleep(1)  # Add delay if needed to respect rate limits or allow better visualization
}

cat("Final Output:", output)