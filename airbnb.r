data <- read.csv("~/coding/text.csv", header = TRUE, sep=",")
View(data)

library(dplyr)

uid = 0:45
colnames(data)
airbdata = data.frame("uid" = uid, "date" = data$Respondents, "text" = data$Response.Date)
fix(airbdata)

library(ggplot2)
library(ggthemes)
library(stringr)
#install.packages(c('tm', 'SnowballC', 'wordcloud', 'topicmodels'))

L = str_length(airbdata$text)
airb2 <- airbdata %>% mutate("text.length" = L) %>% mutate("text.wordcount" = sapply(gregexpr("\\W+", airbdata$text), length))


g <- ggplot(airb2, aes(x=uid))
g + geom_point(aes(x=airb2$uid, y=airb2$text.length, color = text.length)) +
  geom_point(aes(y=text.wordcount, color = text.wordcount)) + xlab("Unique ID") + ylab("Count") + ggtitle("AirBnb Survey Text:\ncharacter count and word count") +
  theme_tufte()

#L
#WC <- sapply(gregexpr("\\W+", airbdata$text), length) + 1 #gets wordcount)
#hist(WC)
library(tm)
library(SnowballC)
library(wordcloud)
library(topicmodels)
library(ggthemes)

fix(airb2)

corpus <-  Corpus(VectorSource(airb2$text)) %>% # creates corpus
  tm_map(tolower) %>%
  tm_map(removePunctuation) %>%
  tm_map(removeNumbers)  %>%
  tm_map(stripWhitespace) %>%
  tm_map(removeWords, c(stopwords('english'),'like'))  #removes list of stop words and like

inspect(corpus)

dictCorpus <- corpus
corpus <- tm_map(corpus,stemDocument, language='english') #removes word endings, forming stems
corpus <- tm_map(corpus, stemCompletion  #introduces generic word endings to stems

stemCompletion_mod <- function(x,dict=dictCorpus) {
  PlainTextDocument(stripWhitespace(paste(stemCompletion(unlist(strsplit(as.character(x)," ")),dictionary=dict, type="shortest"),sep="", collapse=" ")))
}

stemCompletion2 <- function(x, dictionary) {

   x <- unlist(strsplit(as.character(x), " "))

   x <- x[x != ""]

   x <- stemCompletion(x, dictionary=dictionary)

   x <- paste(x, sep="", collapse=" ")

   PlainTextDocument(stripWhitespace(x))

 }



myCorpus <- lapply(corpus, stemCompletion2, dictionary=dictCorpus)

myCorpus <- Corpus(VectorSource(corpus))
#generate word cloud
h <- TermDocumentMatrix(myCorpus)
m <- as.matrix(h)
v <- sort(rowSums(m),decreasing = TRUE)
d <- data.frame(word=names(v),freq=v)
inspect(corpus)

wordcloud(d$word, d$freq, min.freq = 3,
          max.words=80, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(6, "Spectral"))

wordcloud(d$word, d$freq, max.words = 50, colors=brewer.pal(1, "Dark2"))

colnames(d)
wordcloud(d$word, d$freq, max.words = 50, colors=brewer.pal(1, "Dark2"))

p2 <- ggplot(d %>% filter(freq >=8), aes(x = reorder(word, freq), y = freq, fill=word))
p2 + geom_bar(stat = 'identity') + coord_flip() + ggtitle("Airbnb") + ylab("Frequency") + xlab("Word")+ scale_fill_brewer(palette = "Spectral")

