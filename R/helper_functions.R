# Chunk string into given lengths -----------------------------------------
# Default is chunks 2000 characters long

split_string <- function(input_string, max_length = 2000) {
  
  string_length <- nchar(input_string)
  num_chunks <- ceiling(string_length / max_length)
  
  indices <- seq(1, string_length, by = max_length)
  
  # Use lapply to apply str_sub to each index
  result <- lapply(indices, function(i) str_sub(input_string, i, min(i + max_length - 1, string_length)))
  
  return(result)
}

# Load text from package locally -----------------------------------------

load_text_from_package_local <- function(package_name="finalsize",package_type="trace",chunk_length=4000){
  
  #DEBUG package_name="finalsize"; package_type="trace"; base_path="~/Documents/GitHub/epiverse-trace/"
  
  if(package_type=="trace"){
    base_path="~/Documents/GitHub/epiverse-trace/"
  }else{
    base_path="~/Documents/GitHub/"
  }
  
  # Define file path
  file_path <- paste0(base_path,package_name,"/")
  
  # Set up text vector and storage of specific functions
  store_text <- NULL
  store_name <- NULL
  store_chunks <- list()
  
  # Load text from vignettes (if available)
  if(file.exists(paste0(file_path,"vignettes")) ){
    
    files_vignette <- list.files(paste0(file_path,"vignettes"))
    files_vignette <- files_vignette[file_ext(files_vignette)=="Rmd"] # remove non-Rmd
    
    for(ii in files_vignette){
      text_ii <- read_file(paste0(file_path,"vignettes/",ii))
      
      # Get number of chunks
      chunk_text <- split_string(text_ii,chunk_length)
      store_chunks <- c(store_chunks,chunk_text)
      n_chunk <- length(chunk_text)
      
      #store_text <- paste(store_text,rep(text_ii,n_chunk) )
      store_name <- c(store_name,rep(ii,n_chunk))
    }
    
  }
  
  # Load text from function files if available
  files_R <- list.files(paste0(file_path,"R"))
  files_R <- files_R[file_ext(files_R)=="R"]
  
  if(file.exists(paste0(file_path,"R")) ){
    
    for(ii in files_R){
      text_ii <- read_file(paste0(file_path,"R/",ii))

      
      chunk_text <- split_string(text_ii,chunk_length)
      store_chunks <- c(store_chunks,chunk_text)
      n_chunk <- length(chunk_text)
      
      #store_text <- paste(store_text,text_ii)
      store_name <- c(store_name,rep(ii,n_chunk))
    }
    
  }

  list(package = package_name, name_out = store_name, text_out = store_chunks)
  
}


# Load text from package URL -----------------------------------------

load_text_from_package <- function(input_url="https://github.com/epiverse-trace/finalsize",
                                   folder_type="R",
                                   chunk_length=4000){
  
  # DEBUG: input_url="https://github.com/epiverse-trace/finalsize"; folder_type="R"; chunk_length=4000

  # Input GitHub URL
  github_url <- input_url
  
  # GitHub API URL for the content of the folder
  api_url <- gsub("https://github.com", "https://api.github.com/repos", github_url)
  api_url <- paste0(api_url, "/contents/",folder_type)
  
  # Make an API request to get the list of files in the directory
  response <- GET(api_url,add_headers(Authorization = paste("token", github_pat)))
  files_info <- fromJSON(rawToChar(response$content))
  
  # Extract the relevant files from the folder
  if(folder_type=="R"){r_files_urls <- files_info$download_url[grepl(paste0("\\.R$"), files_info$name)]}
  if(folder_type=="vignettes"){r_files_urls <- files_info$download_url[grepl(paste0("\\.Rmd$"), files_info$name)]}
  
  # Download and read the contents of each R file
  r_files_contents <- lapply(r_files_urls, function(url) {
    read_lines(url)
  })

  # Set up text vector and storage of specific functions
  store_text <- NULL
  store_name <- NULL
  store_chunks <- list()

  for(ii in 1:length(r_files_contents)){
    text_ii <- r_files_contents[ii]
    
    # Get number of chunks
    chunk_text <- split_string(paste(text_ii[[1]],collapse=""),chunk_length)[[1]]
    store_chunks <- c(store_chunks,chunk_text)
    n_chunk <- length(chunk_text)
    
    #store_text <- paste(store_text,rep(text_ii,n_chunk) )
    store_name <- c(store_name,rep(files_info$name[ii],n_chunk))
  }

  package_name <- sub(".*/", "", input_url)
  
  print(paste0("Completed extraction for ",package_name," ",folder_type," files"))

  list(package = package_name, name_out = store_name, text_out = store_chunks)
  
}

# Load iterate over packages and chunk -----------------------------------------

load_and_chunk <- function(package_list,chunk_length=4000){
  
  # DEBUG: package_list <- package_descriptions_trace
  
  list_names <- NULL
  list_functions <- NULL
  list_chunks <- list()

  # Iterate over packages
  for(ii in 1:nrow(package_list)){

    #get_text <- load_text_from_package(package_list[ii,"value"],package_list[ii,"trace_external"],chunk_length)
    
    # Load R and vignettes
    get_text1 <- load_text_from_package(input_url=package_list[ii,"link"],folder_type="R",chunk_length)
    get_text2 <- load_text_from_package(input_url=package_list[ii,"link"],folder_type="vignettes",chunk_length)
    
    if(!is.null(get_text1$text_out)){
      # Store package names and chunks
      list_names <- c(list_names,rep(get_text1$package,length(get_text1$name_out)),rep(get_text2$package,length(get_text2$name_out)))
      list_functions <- c(list_functions,get_text1$name_out,get_text2$name_out)
      list_chunks <- append(list_chunks,get_text1$text_out); list_chunks <- append(list_chunks,get_text2$text_out)
    }
    
  }
  
  # Check lengths
  if(length(list_names)!=length(list_functions) | length(list_names)!=length(list_chunks)){print("mismatch in lengths")}
  
  
  write_rds(list_names,paste0("data/chunked_text/package_names.rds"))
  write_rds(list_functions,paste0("data/chunked_text/package_functions.rds"))
  write_rds(list_chunks,paste0("data/chunked_text/package_chunks.rds"))

  
}


# Run embeddings -----------------------------------------

generate_embeddings <- function(file_path="data/chunked_text/"){

  # Load files
  list_chunks <- read_rds(paste0(file_path,"package_chunks.rds"))
  
  # Define OpenAI embedding vector size
  total_chunks <- length(list_chunks)
  
  embed_size <- 1536 # Based on OpenAI embedding vector length
  store_embeddings <- matrix(NA,nrow=total_chunks,embed_size)
  pb <- txtProgressBar(1,total_chunks,style=3,title="Embedding:")
  
  for(ii in 1:total_chunks){
    
    input_text <- list_chunks[[ii]]
    
    output_embedding <- create_embedding(
      model = "text-embedding-ada-002",
      input = input_text,
      openai_api_key = credential_load$value,
    )
    
    output_vec <- output_embedding$data$embedding[[1]]
    
    store_embeddings[ii,] <- output_vec
    
    # Display progress
    setTxtProgressBar(pb, ii)
    
  }
  
  close(pb) # Close bar
  
  write_rds(store_embeddings,paste0("data/embeddings/package_chunk_embeddings.rds"))
  
  
  
}



# Run embeddings -----------------------------------------

generate_embeddings_tags <- function(){
  
  embed_size <- 1536 # Based on OpenAI embedding vector length
  
  # Embed tags

  tags_list <- c("model","data","walkthrough","tutorial","statistics","not relevant")
  total_n1 <- length(tags_list)
  store_embeddings_tag <- matrix(NA,nrow=total_n1,embed_size)
  
  for(ii in 1:total_n1){
    
    input_text_tag <- tags_list[ii]
 
    output_embedding_tag <- create_embedding(
      model = "text-embedding-ada-002",
      input = input_text_tag,
      openai_api_key = openai_key,
    )
    
    output_vec_tag <- output_embedding_tag$data$embedding[[1]]
    
    store_embeddings_tag[ii,] <- output_vec_tag
    
  }
  

  text_list <- c("case dataset","outbreak line list with cases and deaths and onset dates","case study of Ebola","learning R epidemics","inference for Poisson")
  total_n2 <- length(text_list)
  store_embeddings_text <- matrix(NA,nrow=total_n2,embed_size)
  
  for(ii in 1:total_n2){

    input_text_text <- text_list[ii]
    
    output_embedding_text <- create_embedding(
      model = "text-embedding-ada-002",
      input = input_text_text,
      openai_api_key = credential_load$value,
    )
    
    output_vec_text <- output_embedding_text$data$embedding[[1]]
    
    store_embeddings_text[ii,] <- output_vec_text

  }
  
  # Find the best tag for a given text entry in the above string vector
  text_ii <- 2
  cosine_sim <- apply(store_embeddings_tag,1,function(x){lsa::cosine(x,store_embeddings_text[text_ii,])})
  sort_sim <- base::order(cosine_sim,decreasing=T)
  
  c(text_list[text_ii],tags_list[sort_sim[1]])
  

  
  
}

