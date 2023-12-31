# - - - - - - - - - - - - - - - - - - - - - - - 
# Concept for LLM interface to Epiverse tools
# Author: Adam Kucharski
# - - - - - - - - - - - - - - - - - - - - - - -

# Load paths ------------------------------------------------------------------

library(shinyjs) 
library(dplyr)
library(stringr)
library(shinyWidgets)
library(openai)
library(readr)
library(waiter)
library(shinythemes)
library(lsa) 
library(markdown)

wait_screen1 <- tagList(
  spin_orbiter(), h4("Generating suggestion...")
)

wait_screen2 <- tagList(
  spin_orbiter() #, h4("Generating code...")
)

# Plotting and helper functions ------------------------------------------------------------------

# Load credentials
credential_load <- read.csv("data/credentials.csv")

# Load package list and descriptions
# package_list <- read.csv("data/package_list.csv") # deprecatex
package_descriptions <- read.csv("data/package_descriptions.csv")

# Load prompt intro
intro_prompt_sys <- read_file("data/intro_prompt_sys.txt")
intro_prompt <- read_file("data/intro_prompt_answer.txt")

# Load pre-prepped embeddings and text chunks
package_names <- read_rds("data/chunked_text/package_names.rds")
package_functions <- read_rds("data/chunked_text/package_functions.rds")
package_chunks <- read_rds("data/chunked_text/package_chunks.rds") |> unlist()
package_embeddings <- read_rds("data/embeddings/package_chunk_embeddings.rds")

# App UI ------------------------------------------------------------------

ui <- fluidPage(
  title = "Package explorer",
  collapsible = TRUE,
  windowTitle = "Package explorer",
  theme = shinytheme("flatly"),
  
  # Load libraries
  useShinyjs(),
  useWaiter(),
  
  # Define some additional CSS tags if required.
  
  # AI interface ----------------------------------------------------------

  div(
    id = "package-explorer", 
    style = "width: 600px; max-width: 100%; margin: 0 auto;",
  
    # Header
    # div(
    #   class = "well",
    #   div(class = "text-center",
    #       h3("Suggest relevant packages and functions for outbreak analytics tasks"),
    #       br(),
    #       p(strong("Note: this dashboard is under development, so generated outputs are likely to have errors"))
    #   )
    # ),

    # Text input
    div(
      id="question-box",
      class = "well",style = "height: 300px;",
      div(class = "text-center",
        textAreaInput( 
        inputId     = "question_text",
        label       = "What task would you like to do?",
        placeholder = "Enter text",
        height = "100px"
      ),
      actionButton("question_button","Search packages",class="btn-primary"),
      checkboxInput("code_generate","Generate code as well as suggest function/vignette (note: this is slower)",value=F)
      )
    )
  ),

    # Output package
    hidden(
      div(id = "output-response1",style = "width: 600px; max-width: 100%; margin: 0 auto;",
        div(
          class = "well",#style = "height: 300px;",
          strong(textOutput("user_question")),
          br(),
          textOutput("api_response_name"),
          br(),
          textOutput("api_response_description"),
          br(),
          fluidRow(
            column(width = 6, uiOutput("api_response_link")),
            column(width = 6, 
                   div(style = "text-align: right;",
                       actionButton("return_button","< Search again",class="btn-primary"))
            )
          )
        )
      )
    ),
  
  # Output response
  hidden(
    div(id = "output-response2",style = "width: 600px; max-width: 100%; margin: 0 auto;",
        div(
          class = "well",
          p(strong("Suggested functions:")),
          #textOutput("generated_answer")
          uiOutput("generated_answer")
        )
    )
  ),

  div(class = "text-center",
      br(),
      p(em("Output generated using the OpenAI API."))
  )
  # 

    
  
) # END UI

# App server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Store text
  package_name <- reactiveVal("")
  package_text <- reactiveVal("")
  package_link <- reactiveVal("")
  

  # Output LLM completion
  observeEvent(input$question_button,{

    waiter_show(html = wait_screen1,color="#b7c9e2") #) #id="question-box",
    
    # Test with query
    query_text <-  input$question_text
    
    # DEBUG: query_text <- "Calculate the reproduction number"
    
    query_embedding <- create_embedding(
      model = "text-embedding-ada-002",
      input = query_text,
      openai_api_key = credential_load$value,
    )
    
    cosine(query_embedding$data$embedding[[1]],query_embedding2$data$embedding[[1]])
  
    
    # Define embedding vector for query
    query_vec <- query_embedding$data$embedding[[1]]

    # Match to closest resources
    cosine_sim <- apply(package_embeddings,1,function(x){lsa::cosine(x,query_vec)})
    sort_sim <- base::order(cosine_sim,decreasing=T)

    # Find top matches and choose top package (otherwise penalises by documentation volume):
    n_match <- 5
    top_pick <- sort_sim[1:n_match]
    top_packages <- package_names[top_pick]
    pick_package <- top_packages[1] #names(which.max(table(top_packages))) 
    pick_function <- package_functions[top_pick][1]
    
    # Get file type
    if(substr(pick_function,nchar(pick_function),nchar(pick_function))=="R"){
      ftype <- "function"
      fname <- paste0(substr(pick_function,1,nchar(pick_function)-2),"()")
    }else{
      ftype <- "vignette"
      fname <- substr(pick_function,1,nchar(pick_function)-4)
    }
    
    # Extract top entries from best matching packages
    package_match <- which(package_names==pick_package)


    # Extract top matches in order, and select this number (or maximum, whichever smaller)
    match_to_ranking <- match(sort_sim,package_match); match_to_ranking <- match_to_ranking[!is.na(match_to_ranking)]
    n_match_2 <- min(length(match_to_ranking),n_match)
    best_entries_for_package <- package_match[match_to_ranking[1:n_match_2]]
    
    context_text <- paste(package_chunks[sort(best_entries_for_package)],collapse="\n")

    
    # Render response for package
    best_match <- package_descriptions |> dplyr::filter(value==pick_package)

    # package_name(pick_package)
    # package_text()
    # package_link()
    
    output$user_question <- renderText({ paste0("You wrote: \"", query_text,"\".") })
    
    output$api_response_name <- renderText({ paste0("Have a look at the \"",fname,"\" ",ftype," from the {",pick_package,"} package.") })
    
    output$api_response_description <- renderText({ best_match$description})
    
    output$api_response_link <- renderUI({
      tags$a(href = best_match$link, "Go to package website", target = "_blank")
    })
    
    # Switch to second waiter

    
    #waiter_show(id="output-response2",html=wait_screen2,color="#80a0cc")
    # GPT 4 generation code
    
    if(input$code_generate==T){
      # Generate answer
      llm_completion_med <- create_chat_completion(
        model = "gpt-4", #"gpt-4", # "text-davinci-003", #gpt-3.5-turbo
        messages = list(list("role"="system","content" = intro_prompt_sys),
                        list("role"="user","content" = paste0(intro_prompt,
                                                              "Context: ",context_text,
                                                              "Question: ",query_text,
                                                              "Answer:"))
        ),
        temperature = 0,
        openai_api_key = credential_load$value,
        max_tokens = 1000
      )
  
      # Extract response
      generated_a <- llm_completion_med$choices$message.content
  
      # Generate UI object with includeMarkdown

      output$generated_answer <- renderUI({
        HTML(markdownToHTML(text = generated_a, fragment.only = TRUE))
      })
    
      shinyjs::show("output-response2")
    }


    shinyjs::show("output-response1")
    shinyjs::hide("package-explorer")

    waiter_hide()
    
  })
  
  # Revert to question
  observeEvent(input$return_button,{
    
    shinyjs::hide("output-response1")
    shinyjs::hide("output-response2")
    shinyjs::show("package-explorer")
    
  })
    
  
  
} # END SERVER



# Compile app -------------------------------------------------------------

shinyApp(ui = ui, server = server)


