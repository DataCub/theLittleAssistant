# Load the necessary packages
library(curl)
library(jsonlite)
library(httr)

tmp <- fromJSON(paste0("https://www.googleapis.com/youtube/v3/videos?",
                       "part=snippet&chart=mostPopular&key=AIzaSyARX7-F4xQnLrSgUQi6MjAcpPcLtZwhkZY"))
titles <- tmp$items$snippet$title
etag <- tmp$items
class(tmp)
View(tmp)

