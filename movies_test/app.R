library(httr)
library(shiny)
library(dplyr)
library(magrittr)
library(jsonlite)
library(lubridate)
library(shinythemes)

source("carouselPanel.R")

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

