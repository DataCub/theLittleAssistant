library(httr)
library(shiny)
library(dplyr)
library(magrittr)
library(jsonlite)
library(lubridate)
library(shinythemes)

source("carouselPanel.R")

nyt_most_popular_api <- "a1001f5ad4ae4e07946c944b19f2ea01"
get_most_viewed <- function(section = "all-sections", time_period = 1, iterations = 1, debug = FALSE) {
  
  for (i in 1:iterations) {
    
    offset <- i * 10
    
    # construct the URI
    uri_base <- paste0("http://api.nytimes.com/svc/mostpopular/v2/mostviewed/",section, "/", time_period)
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
  results <- as.data.frame(results_json)
  results$title_link <- paste0('<a target="_blank" href="',results$url,'">', results$title,"</a>")
  
  return (results)
}


# Define UI for application that draws a histogram
ui <- shinyUI(fluidPage(
  
  theme = "Flatly",
   
  # Application title
  titlePanel("Movies"),
  
  # Show a plot of the generated distribution
  mainPanel(
    carouselPanel(auto.advance=TRUE,
                  dataTableOutput("top"),
                  dataTableOutput("upcoming")
    )
  )
   
))

# Define server logic required to draw a histogram
server <- shinyServer(function(input, output) {
  
  top <- GET("http://api.themoviedb.org/3/movie/now_playing?api_key=bc430e79d5377e1028b278f358f45b68")
  upcoming <- GET("http://api.themoviedb.org/3/movie/upcoming?api_key=bc430e79d5377e1028b278f358f45b68")
  
  top.content <- content(top, as='text', encoding='UTF-8') %>% prettify %>% fromJSON
  upcoming.content <- content(upcoming, as='text', encoding='UTF-8') %>% prettify %>% fromJSON
  
  top.movies <- top.content$results %>% na.omit %>% filter(original_language=='en') %>%
    select(title,release_date,backdrop_path,popularity) %>%
      transmute(`Hot Movies`=title, 
                Released=release_date, 
                Popularity=1:length(popularity))
  
  upcoming.movies <- upcoming.content$results %>% na.omit %>%
    select(title,release_date,backdrop_path,popularity) %>%
      transmute(`Upcoming Movies`=title, 
                Coming=release_date, 
                Popularity=1:length(popularity))
  
  output$top <- renderDataTable(top.movies[1:8,], options = list(
                                    searching=FALSE,
                                    info=FALSE,
                                    paging=FALSE))
  output$upcoming <- renderDataTable(upcoming.movies[1:8,], options = list(
                                    searching=FALSE,
                                    info=FALSE,
                                    paging=FALSE))
  
})

# Run the application 
shinyApp(ui = ui, server = server)

