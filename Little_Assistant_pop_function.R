library(httr)
library(ggplot2)
library(dplyr)
library(tidyjson)
library(data.table)
library(knitr)

nyt_most_popular_api <- "a1001f5ad4ae4e07946c944b19f2ea01"
get_most_viewed <- function(section = "all-sections", time_period = 1, iterations = 1, debug = FALSE) {
  
  for (i in 1:iterations) {
    
    offset <- i * 20
    
    # construct the URI
    uri_base <- paste0("http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/", time_period)
    uri_base <- paste0(uri_base, ".json?offset=", offset)
    uri      <- paste0(uri_base,"&api-key=", nyt_most_popular_api)
    
    if (debug) {print(uri)}
    
    # Get the first batch of 20 using the the API
    raw_contents <- GET(url = uri)
    
    # store the json
    json_raw <- httr::content(raw_contents, type = "text", encoding = "UTF-8")
    
    
    ## get status
    json_raw %>% enter_object("status") %>%
      append_values_string("status") %>% select(status)
    
    ## get the number of resultes
    results <- 
      json_raw %>% 
      enter_object("num_results") %>%
      append_values_string("num_results") %>% 
      select(num_results)
    
    if (debug) {print(status)}
    if (debug) {print(results)}
    
    nyt_most_popular_json <- json_raw %>% as.tbl_json
    
    results <-
      nyt_most_popular_json %>%
      enter_object("results") %>%
      gather_array %>%
      spread_values(
        id = jnumber("id"),
        type = jstring("type"),
        section = jstring("section"),
        title = jstring("title"),
        by = jstring("byline"),
        url = jstring("url"),
        keywords = jstring("adx_keywords"),
        abstract = jstring("abstract"),
        published_date = jstring("published_date"),
        source = jstring("source"),
        views = jnumber("views")
      )
    
    # rowbind the results to create one tbl_json object containing the 100 Most Viewed articles
    # rbindlist requires the data.table package
    
    if (i == 1) { 
      results_json <- results
    } 
    else {
      results_json <- rbindlist(list(results_json, results))
    }
    
    
  }
  
  return (results_json)
}