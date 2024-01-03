# - - - - - - - - - - - - - - - - - - - - - - - 
# Concept for embedding match for semantic analysis
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
  spin_orbiter(), h4("Running semantic analysis...")
)


# Plotting and helper functions ------------------------------------------------------------------

# Load credentials
credential_load <- read.csv("data/credentials.csv")

# App UI ------------------------------------------------------------------

ui <- fluidPage(
  title = "Semantic matching",
  collapsible = TRUE,
  windowTitle = "Semantic matching",
  theme = shinytheme("flatly"),
  
  # Load libraries
  useShinyjs(),
  useWaiter(),
  
  # Define some additional CSS tags if required.
  
  # AI interface ----------------------------------------------------------

  div(
    id = "package-explorer", 
    style = "width: 600px; max-width: 100%; margin: 0 auto;",

    # Text input
    div(
      id="question-box",
      class = "well",#style = "height: 300px;",
      div(class = "text-center",
        textAreaInput( 
        inputId     = "question_text",
        label       = "What text would you like to analyse?",
        value = "If you dress as if you are the president of this country, some of these stakeholders will not even talk to you.
        They will say that these are the people that are eating the country’s money so we see no reason for us to listen to them. .. That’s why you need to put yourself in that moderate manner so that maybe when you go there they will think that all of us, we are equal. ",
        height = "250px"
      ),
      a(href="https://bmcpublichealth.biomedcentral.com/articles/10.1186/s12889-019-7978-4","Example quote above from Dada et al"),
      p(""),
      textAreaInput( 
        inputId     = "match_text",
        label       = "What phrases would you like to match to? Enter at least two, and separate by semi-colons:",
        value = "The CLT and SST ensured reciprocal communication between the trial team and the community. The CLT delivered key messages from the trial, whilst the SST completed ethnographic research in the field to uncover rumors and perceptions of the trial in the community. These ethnographic findings were shared with the CLT and addressed in targeted messaging to the community;
        Both the CLT and SST approached the communities in an egalitarian manner, by dressing modestly, speaking local dialects, and using relatable examples;
        Appreciation and understanding of the importance of interpersonal relationships and respect for the people, their customs, and traditions also played a large role in the CE program.",
        height = "250px"
      ),
      actionButton("question_button","Classify text",class="btn-primary")
      )
    )
  ),

  # Output package
  hidden(
    div(id = "output-response1",style = "width: 600px; max-width: 100%; margin: 0 auto;",
      div(
        hr(),
        tableOutput("match_quality")
      )
    )
  ),

  div(class = "text-center",
      br(),
      p(em("Output generated using the OpenAI embedding API."))
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
    
    # DEBUG: query_text <- "We are often ignored in policy discussions at higher levels"
    # match_text="community;trust;fairness;power"
    
    # Test with query
    query_text <-  input$question_text
    
    # Match text
    match_text <- input$match_text
    match_text <-  stringr::str_split(match_text,";")[[1]]

    query_embedding <- create_embedding(
      model = "text-embedding-ada-002",
      input = query_text,
      openai_api_key = credential_load$value,
    )
    
    match_embedding <- sapply(match_text,function(x){
      y <- create_embedding(
        model = "text-embedding-ada-002",
        input = x,
        openai_api_key = credential_load$value,
      );
      y$data$embedding[[1]]
      })
  
    
    # Define embedding vector for query
    query_vec <- query_embedding$data$embedding[[1]]
    match_vec <- t(match_embedding)
    
    # Match to closest resources
    cosine_sim <- apply(match_vec,1,function(x){lsa::cosine(x,query_vec)})
    sort_sim <- base::order(cosine_sim,decreasing=T)

    # Find top matches and choose top package (otherwise penalises by documentation volume):
    n_match <- length(match_text)

    
    # Match quality
    match_summary <- data.frame(rank=1:n_match,
                                match_text=match_text[sort_sim],
                                match_quality=signif(100*cosine_sim[sort_sim],3)
                                )
    
    output$match_quality <-  renderTable(match_summary)
    
    shinyjs::show("output-response1")

    waiter_hide()
    
  })
  
  
} # END SERVER



# Compile app -------------------------------------------------------------

shinyApp(ui = ui, server = server)


