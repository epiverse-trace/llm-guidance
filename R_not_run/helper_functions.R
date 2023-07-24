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

# Load text from package -----------------------------------------

load_text_from_package <- function(package_name="finalsize",base_path="~/Documents/GitHub/epiverse-trace/"){
  
  #DEBUG package_name="datadelay"
  
  # Define file path
  file_path <- paste0(base_path,package_name,"/")
  
  # Set up text vector
  store_text <- NULL
  
  # Load text from function files if available
  files_R <- list.files(paste0(file_path,"R"))
  files_R <- files_R[file_ext(files_R)=="R"]
  
  if(file.exists(paste0(file_path,"R")) ){
  
    for(ii in files_R){
      store_text <- paste(store_text,read_file(paste0(file_path,"R/",ii)))
    }
    
  }
  
  # Load text from vignettes (if available)
  if(file.exists(paste0(file_path,"vignettes")) ){
    
    files_vignette <- list.files(paste0(file_path,"vignettes"))
    files_vignette <- files_vignette[file_ext(files_vignette)=="Rmd"] # remove non-Rmd
    
    for(ii in files_vignette){
      store_text <- paste(store_text,read_file(paste0(file_path,"vignettes/",ii)))
    }
    
  }
  
  list(package = package_name, text_out = store_text)
  
}

# Load iterate over packages and chunk -----------------------------------------

load_and_chunk <- function(package_list){
  
  # DEBUG: package_list <- package_descriptions_trace$value
  
  list_names <- NULL
  list_chunks <- list()

  # Iterate over packages
  for(ii in package_list){
    
    get_text <- load_text_from_package(ii)
    
    if(!is.null(get_text$text_out)){
      # Chunk text
      chunk_text <- split_string(get_text$text_out)
    
      # Store package names and chunks
      list_names <- c(list_names,rep(ii,length(chunk_text)))
      list_chunks <- append(list_chunks,chunk_text)
    }
    
  }
  
  
  write_rds(list_names,paste0("data/chunked_text/package_names.rds"))
  write_rds(list_chunks,paste0("data/chunked_text/package_chunks.rds"))
  
  
}


# Run embeddings -----------------------------------------

generate_embeddings <- function(){
  
  # Load files
  list_names <- read_rds("data/chunked_text/package_names.rds")
  list_chunks <- read_rds("data/chunked_text/package_chunks.rds")
  
  # Define Open AI embedding vector size
  total_chunks <- length(list_chunks)
  
  embed_size <- 1536
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
