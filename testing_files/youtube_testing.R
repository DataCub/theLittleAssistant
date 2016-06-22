# Load the necessary packages
library(curl)
library(jsonlite)
library(httr)


# Your API key obtained via https://console.developers.google.com/ 
API_key='AIzaSyARX7-F4xQnLrSgUQi6MjAcpPcLtZwhkZY'

# Base URL for Google API's services and YouTube specific API's
Base_URL='https://www.googleapis.com/youtube/v3'

# YouTube Web Services
# Note that we have replaced the %2C with "," so sprintf works correctly with it
# as an alternative we can add an extra % in front of %2C to make it %%2C
YT_Service <- c( 'search?part=snippet&q=%s&type=%s&key=%s',                         # search API
                 'subscriptions?part=snippet,contentDetails&channelId=%s&key=%s'    # subscriptions API
)

# Form request URL
# channelId=UCAuUUnT6oDeKwE6v1NGQxug is the TED channel, used here as an example
url <- paste0(Base_URL, "/", sprintf(YT_Service[2], 'UCAuUUnT6oDeKwE6v1NGQxug', API_key))

# Perform query
result <- fromJSON(txt=url)

# Print the title of the channels this channel has subscribed to
result$items$snippet$title

# Print the Id's of the channels this channel has subscribed to
result$items$snippet$resourceId$channelId