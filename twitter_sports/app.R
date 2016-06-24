library(shiny)
library(httr)
library(dplyr)
library(magrittr)
library(jsonlite)
library(lubridate)
library(shiny)
library(plotly)
library(knitr)
library(dplyr)
library(ggplot2)
library(tidyjson)
library(data.table)
library(shinythemes)
library(DT)
library(stringr)
library(rvest)


source("carouselPanel.R")

nice.date <- function(date) {
  m <- lubridate::month(date, label=TRUE)
  d <- lubridate::wday(date)
  paste(m,d)
}

getTopX <- function(x) {
  nodes <- read_html("http://www.billboard.com/charts/hot-100") %>%
    html_nodes(css = "#main > div:nth-child(4) > div > div:nth-child(1)")
  song.names <- c()
  artist.names <- c()
  vec <- as.character(seq(1,x,1))
  for(v in vec) {
    entry.css = paste("article.chart-row.chart-row--",v,".js-chart-row > div.chart-row__primary > div.chart-row__main-display > div.chart-row__container > div",sep="")
    entry.node = html_nodes(nodes, css=entry.css)
    song.name = html_nodes(entry.node, css="h2") %>% html_text
    song.artist = html_nodes(entry.node, css="a") %>% html_text %>% str_trim
    song.names <- c(song.names, song.name)
    artist.names <-c(artist.names, song.artist)
    #print(log.entry)
  }
  #print(song.names)
  #print(artist.names)
  df <- data.frame(song.names, artist.names)
  colnames(df) <- c("Song","Artist")
  df
}

g <- getTopX(25)

nyt_most_popular_api <- "a1001f5ad4ae4e07946c944b19f2ea01"
get_most_viewed <- function(section = "all-sections", time_period = 1, iterations = 1, debug = FALSE) {
  
  for (i in 1:iterations) {
    
    offset <- i * 20
    
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

<<<<<<< HEAD
ids <- tmp$items$id
ids <- paste0(ids, '"')

urls <- as.character(sapply(ids, function(x) {paste0('"https://www.youtube.com/embed/', x)})) # all the urls 
urls <- str_replace_all(urls, "https:", "")



iframes <- paste('<iframe width=\"400\" height=\"200\" src=', urls,' frameborder=\"0\" allowfullscreen></iframe>', sep="")
iframes
=======
#titles <- tmp$items$snippet$title # all the video titles 
#ids <- tmp$items$id
#ids
#ids <- paste0(ids, '"')
#ids

#urls <- as.character(sapply(ids, function(x) {paste0('"https://www.youtube.com/watch?v=', x)})) # all the urls 
#urls
#iframes <- paste('<iframe width=\"400\" height=\"200\" src=', urls,' frameborder=\"0\" allowfullscreen></iframe>', sep="")
#iframes
>>>>>>> 36113e903cc15b0ce52d6fb4920df621997244e6

#'<iframe width=\"395\" height=\"200\" src=\"//www.youtube.com/embed/dQw4w9WgXcQ\" frameborder=\"0\" allowfullscreen></iframe>'

runApp(list(ui = fluidPage(
  theme = "bootstrap.css",
  tags$head(tags$script('!function(d,s,id){var js,fjs=d.getElementsByTagName(s)    [0],p=/^http:/.test(d.location)?\'http\':\'https\';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");')),
  tags$head(tags$link(rel="shortcut icon", href="http://coghillcartooning.com/images/art/cartooning/character-design/news-hound-cartoon-character.jpg")),
  
  titlePanel(h1("Little Assistant")),
  fluidRow(
    column(3, selectInput(inputId = "time", label = "How long have you been away from the world?",
                          c("one day" = 1, "one week" = 7, "one month" = 30))),
    column(3, offset = 2, selectInput(inputId = "section", label = "What would you like to catch up on?\n",
                                      c("all-sections" = "all-sections", "World" = "World", 
                                        "U.S." = "U.S.", "Travel" = "Travel", "The Upshot" = "The Upshot",
                                        "Technology" = "Technology", "Style" = "Style", "Sports" = "Sports", 
                                        "Science" = "Science", "Opinion" = "Opinion", "N.Y. / Region" = "N.Y. / Region",
                                        "Movies" = "Movies", "Magazine" = "Magazine", "Health" = "Health", 
                                        "Business Day" = "Business Day", "Books" = "Books", "Art" = "Art")))
  ),
  sidebarLayout(
    sidebarPanel(
                 h2("YouTube"),
                 HTML('<iframe width=\"395\" height=\"200\" src=\"//www.youtube.com/embed/Ockhq8E2FrA\" frameborder=\"0\" allowfullscreen></iframe>'),
                 h2("Sports"),
                 a("@Complex_Sports", class="twitter-timeline",
                   href = "https://twitter.com/Complex_Sports",
                   height = "750px"),
                 hr()
    ), 
    mainPanel(h2("News"),
      DT::dataTableOutput('tbl'),
      hr(),
      h2("Hot Movies & Even Hotter Songs"),
      carouselPanel(auto.advance=TRUE,
                    dataTableOutput("top"),
                    #dataTableOutput("upcoming"),
                    dataTableOutput("music")
      )
      
    ),
    position = "right"
  )
), 
server = function(input, output, session){
  
  #MOVIES
  top <- GET("http://api.themoviedb.org/3/movie/now_playing?api_key=bc430e79d5377e1028b278f358f45b68")
  upcoming <- GET("http://api.themoviedb.org/3/movie/upcoming?api_key=bc430e79d5377e1028b278f358f45b68")
  
  top.content <- content(top, as='text', encoding='UTF-8') %>% prettify %>% fromJSON
  upcoming.content <- content(upcoming, as='text', encoding='UTF-8') %>% prettify %>% fromJSON
  
  top.movies <- top.content$results %>% na.omit %>% filter(original_language=='en') %>%
    select(title,release_date,backdrop_path,popularity) %>%
    transmute(`Hot Movies`=title, 
              Released=nice.date(as.Date(release_date)),
              Popularity=1:length(popularity))
  
  upcoming.movies <- upcoming.content$results %>% na.omit %>%
    select(title,release_date,backdrop_path,popularity) %>%
    transmute(`Upcoming Movies`=title, 
              Coming=nice.date(as.Date(release_date)),
              Popularity=1:length(popularity))
  
  #MUSIC
  songs <- getTopX(50)
  output$music <- renderDataTable(songs[1:10,], options = list(
    searching=FALSE,
    info=FALSE,
    paging=FALSE))
  
  #YOUTUBE
  tmp <- fromJSON(paste0("https://www.googleapis.com/youtube/v3/videos?", #everything after '?' is parameters being passed, '&' separates the argument
                         "part=snippet&chart=mostPopular&key=AIzaSyARX7-F4xQnLrSgUQi6MjAcpPcLtZwhkZY"))
  
  titles <- tmp$items$snippet$title # all the video titles 
  ids <- tmp$items$id
  
  urls <- as.character(sapply(ids, function(x) {paste0("https://www.youtube.com/watch?v=", x)})) # all the urls 
  urls

  iframes <- paste0("<iframe width=\"395\" height=\"200\" src=", urls ," frameborder=\"0\" allowfullscreen></iframe>")
  iframes
  
  output$top <- renderDataTable(top.movies[1:10,], options = list(
    searching=FALSE,
    info=FALSE,
    paging=FALSE))
  
  output$upcoming <- renderDataTable(upcoming.movies[1:10,], options = list(
    searching=FALSE,
    info=FALSE,
    paging=FALSE))
  
  output$tbl = DT::renderDataTable(get_most_viewed(
    section = input$section, time_period = input$time) %>% 
      select(section, title_link, abstract, published_date), escape = FALSE, options = list(lengthChange = FALSE,
                                                                                            pageLength = 5))
  
    }
  )
)