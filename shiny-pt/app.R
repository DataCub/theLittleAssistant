# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com/

library(shiny)

library(httr)
library(knitr)
library(dplyr)
library(ggplot2)
library(timeline)
library(tidyjson)
library(data.table)

# rm(list = ls())

times.key <- "fb6186a7c44a4a8086ec99fa0b09566b"

get_most_viewed <- (function(section = "all-sections", time_period = 1, iterations = 1, debug = FALSE) {
  
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
})

# Define UI for application
ui <- shinyUI(fluidPage(
  titlePanel("Little Assistant"),
  hr(),
  fluidRow(
    column(12, h4("How long's it been since you've been away?"),
      selectInput("select", label = h5("Please select an option from the list below."),
                  choices = list("1 day" = 1, "1 week" = 7, "1 month" = 30),
                  selected = 1))
  ),
  hr(),
  mainPanel(
    textOutput("text1"),
    plotlyOutput('plot', width="900px", height = "500px")
  )
  
))

# Define server logic
server <- shinyServer(function(input, output) {
  
  output$text1 <- renderText({ 
    input$select
  })
  
  tmp=sample(1,c(1,7,30))
  tmp=3
  
  if(tmp == 1) {
    articles <- get_most_viewed("all-sections",1,5) %>% 
      select(section, title, by, url, keywords, abstract, published_date, views) %>%
        data.frame
    articles$published_date <- as.Date(articles$published_date)
    date.diff <- as.numeric(as.Date(Sys.Date()) - articles$published_date)
    articles <- filter(articles, date.diff <= 3 & date.diff >= -1)
  } else if(tmp == 7) {
    articles <- get_most_viewed("all-sections",7,5) %>% 
      select(section, title, by, url, keywords, abstract, published_date, views) %>%
        data.frame
    articles$published_date <- as.Date(articles$published_date)
    date.diff <- as.numeric(as.Date(Sys.Date()) - articles$published_date)
    articles <- filter(articles, date.diff <= 10 & date.diff >= -1)
  } else {
    articles <- get_most_viewed("all-sections",30,5) %>% 
      select(section, title, by, url, keywords, abstract, published_date, views) %>%
        data.frame
    articles$published_date <- as.Date(articles$published_date)
    date.diff <- as.numeric(as.Date(Sys.Date()) - articles$published_date)
    articles <- filter(articles, date.diff <= 30 & date.diff >= -1)
  }
  x <- list(
    title = "Published (Date)"  
  )
  y <- list(
    title = "",
    showticklabels = FALSE
  )
  s <- rep(1,100)
  #s <- seq(1,5,.1)
  my.plot <- plot_ly(articles, x = published_date, y = jitter(s), 
                     text = title, 
                     mode="markers", color = section, size = s) %>% 
                        layout(xaxis = x, yaxis = y)
  output$plot = renderPlotly(my.plot)
    
})

# Run the application 
shinyApp(ui, server)

