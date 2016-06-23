# Load the necessary packages
library(curl)
library(jsonlite)
library(httr)

tmp <- fromJSON(paste0("https://www.googleapis.com/youtube/v3/videos?", #everything after '?' is parameters being passed, '&' separates the argument
                       "part=snippet&chart=mostPopular&key=AIzaSyARX7-F4xQnLrSgUQi6MjAcpPcLtZwhkZY"))

titles <- tmp$items$snippet$title # all the video titles 
ids <- tmp$items$id

urls <- as.character(sapply(ids, function(x) {paste0("https://www.youtube.com/watch?v=", x)})) # all the urls 


