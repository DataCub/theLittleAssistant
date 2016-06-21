library(httr)
library(knitr)
library(dplyr)
library(plotly)
library(ggplot2)
library(tidyjson)
library(timeline)
library(data.table)

# rm(list = ls())

times.key <- "fb6186a7c44a4a8086ec99fa0b09566b"

get_most_viewed <- function(section = "all-sections", time_period = 1, iterations = 1, debug = FALSE) {
  
  for (i in 1:iterations) {
    
    offset <- i * 20
    
    # construct the url
    url_base <- paste0("http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/", time_period)
    url_base <- paste0(url_base, ".json?offset=", offset)
    url      <- paste0(url_base,"&api-key=", times.key)
    
    if (debug) {print(url)}
    
    # Get the first batch of 20 using the API
    raw_contents <- GET(url)
    
    # store the json
    json_raw <- httr::content(raw_contents, type = "text", encoding = "UTF-8")
    
    ## get status
    json_raw %>% enter_object("status") %>%
      append_values_string("status") %>% select(status)
    
    ## get the number of results
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

articles <- get_most_viewed("all-sections",1,5) %>% 
  select(section, title, by, url, keywords, abstract, published_date, views) %>%
    data.frame

articles$published_date <- as.Date(articles$published_date)
date.diff <- as.numeric(as.Date(Sys.Date()) - articles$published_date)
articles <- filter(articles, date.diff <= 30 & date.diff >= 0)

x <- list(title = "Published (Date)")
s <- rep(1,100)
plot_ly(articles, type='histogram', options = (orientation='v', published_date, text = title,
        color = section, size=s) %>% 
  layout(xaxis = x)
