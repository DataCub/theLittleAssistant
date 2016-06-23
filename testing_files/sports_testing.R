# sports testing 
#install.packages("twitteR")
library(twitteR)

consumer_key = "sY2XV0qqmOTZwgXkHXItldZ6H"
consumer_secret = "wssejZwvLfzfL5jdtMSGmThQrZDZ1tuCt4bdm3Bk2E00knF1h1"
access_token = "1959972582-VUX4RNZWy0UC8BcSXG1pfmpWN41bvLhR62Vnx48"
access_secret = "l2WOCkRVdFbdF18dhZ11lMyUCWxJA3gRVECaMtxGPt8nv"
setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

#rm(list=ls())
tweets <- userTimeline('espn', n=10)
