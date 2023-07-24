# - - - - - - - - - - - - - - - - - - - - - - - 
# Run loop to generate embeddings for packages
# - - - - - - - - - - - - - - - - - - - - - - -

# Load credentials and libraries
library(openai)
library(stringr)
library(readr)
library(tools)

setwd("~/Documents/GitHub/epiverse-llm/")

credential_load <- read.csv("data/credentials.csv")

# Load helper functions
source("R_not_run/helper_functions.R")

# Load prompt for question generation
intro_prompt <- read_file("data/intro_prompt_answer.txt")

# Load list of packages and descriptions
package_descriptions <- read.csv("data/package_descriptions.csv")
package_descriptions_trace <- package_descriptions |> dplyr::filter(trace_external=="trace")

# Generate embeddings -----------------------------------------------------

# Load files and chunk

load_and_chunk(package_descriptions_trace$value)

generate_embeddings()


# Old code for answer generation -----------------------------------------------------

# Number of questions and answers to generate:
# n_questions <- 10
# 
# llm_completion_med <- create_chat_completion(
#   model = "gpt-3.5-turbo", # "text-davinci-003",
#   messages = list(list("role"="system","content" = paste0(intro_prompt,n_questions,intro_prompt_2)),
#                   list("role"="user","content" = questions_01_md)
#   ),
#   temperature = 0,
#   openai_api_key = credential_load$value
#   #max_tokens = 1000
# )
# 
# # Render response
# generated_q <- str_split(llm_completion_med$choices$message.content,"\n")[[1]]
# 
# 
# 

