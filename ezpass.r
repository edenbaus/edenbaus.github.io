
library(dplyr)
library(ggplot2)
library(plotly)
library(zoo)
#install.packages('zoo')
ez <- read.csv("ezpass_july.csv",stringsAsFactors = FALSE)
head(ez)

# note: values of $AMOUNT and $BALANCE are nested vectors: [[x1]],[[x2]],[[x3]],...,[[xn]]
# added x <- x[[1]] in func to address issue
# alternative: sapply(ez$AMOUNT, "[[",1) - pretty amazing trick
clean.dollar.fields <- function(x) {
  cleaned_amount <- gsub("\\(","-",(gsub("\\)","",(gsub("\\$","",x)))))
  formatted_amount <- as.double(sprintf(x, fmt = "%#.2s"))
  return (cleaned_amount)
}

ez <- within(ez,{
  POSTING.DATE          = as.Date(POSTING.DATE,"%m/%d/%Y")
  TRANSACTION.DATE      = as.Date(TRANSACTION.DATE,"%m/%d/%Y")
  TRANSACTION.MONTH     = sapply(TRANSACTION.DATE, function(x) format(x,"%B"))
  TRANSACTION.INTMONTH  = sapply(TRANSACTION.DATE, function(x) format(x,"%m"))
  TRANSACTION.YEAR      = sapply(TRANSACTION.DATE, function(x) format(x,"%G"))
  TRANSACTION.DOW       = sapply(TRANSACTION.DATE, function(x) format(x,"%A"))
  BALANCE               = sapply(BALANCE,"[[",1)
  AMOUNT                = sapply(AMOUNT,"[")
  BALANCE               = sapply(BALANCE,clean.dollar.fields )
  AMOUNT                = sapply(AMOUNT,clean.dollar.fields)
})
getwd()
write.csv(ez,'cleaned_ezpass_july.csv')
# Aggregate amounts by year and month

month_tolls <- ez %>% select( TRANSACTION.DATE, amount = AMOUNT) %>% 
  mutate(Period = as.factor(as.yearmon(TRANSACTION.DATE,"%Y/%m"))) %>%
  filter(amount < 0) %>% 
  group_by(Period) %>% 
  summarize(Frequency = n()) %>%
  arrange(desc(Period)) %>%
  select(Period, Frequency)

# ggplot
ggplot(month_tolls, aes(Period,Frequency)) + 
  geom_bar(aes(fill=c('red','blue'),alpha = 0.7),stat='identity') + 
  theme_minimal() + 
  theme(legend.position='none') +
  ggtitle("EZ Pass Tolls by Month") + xlab("") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
       panel.background = element_blank(), axis.line = element_line(colour = "black"))

# plotly
plot_ly(
  x = month_tolls$Period,
  y = month_tolls$Frequency,
  name = "EZ Pass",
  type = "bar",
  opacity = 0.7,
  marker = list(color = c('red','green','blue'),
                opacity = 0.7,
                line = list(color = 'black',
                            width = 1.5))
) %>%
  layout(title = "EZ Pass Tolls by Month",
         xaxis = list(title = "",
                      showgridlines = FALSE),
         yaxis = list(title = "Frequency",
                      showgridlines = FALSE))

ggplot(ez %>% mutate (BALANCE = as.double(BALANCE)), aes(TRANSACTION.DATE,BALANCE)) + geom_point()
ez_timesort <- ez %>% mutate(BALANCE = as.double(BALANCE)) %>% select(TRANSACTION.DATE, ENTRY.TIME, BALANCE) %>% arrange(TRANSACTION.DATE,ENTRY.TIME)

ggplot(ez_timesort, aes(TRANSACTION.DATE,BALANCE)) + geom_point()


plot_ly(
  x = ez_timesort$TRANSACTION.DATE ,
  y = ez_timesort$BALANCE ,
  name = "EZ Pass",
  type = "scatter",
  opacity = 0.7,
  mode='markers+lines'
) %>%
  layout(title = "EZ Pass Account Balance",
         xaxis = list(title = "",
                      showgridlines = FALSE),
         yaxis = list(title = "Account Balance in USD",
                      showgridlines = FALSE))

agg1 <- ez %>% mutate(BALANCE = as.double(BALANCE),
              AMOUNT = -1.0* as.double(AMOUNT),
              Period = as.factor(as.yearmon(TRANSACTION.DATE,"%Y/%m"))) %>%
  select(Day = TRANSACTION.DOW,
         Balance = BALANCE,
         Amount = AMOUNT,
         Period = Period) %>%
  filter (Amount > 0) %>% 
  group_by(Period,Day) %>%
  summarize(Frequency=n(), Min=min(Amount),Max=max(Amount,na.rm = TRUE), total=sum(Amount,na.rm=TRUE))

agg2 <- ez %>% mutate(BALANCE = as.double(BALANCE),
                      AMOUNT = -1.0* as.double(AMOUNT),
                      Period = as.factor(as.yearmon(TRANSACTION.DATE,"%Y/%m"))) %>%
  select(Day = TRANSACTION.DOW,
         Balance = BALANCE,
         Amount = AMOUNT,
         Period = Period) %>%
  filter (Amount > 0) %>% 
  group_by(Period) %>%
  summarize(Frequency=n(), Min=min(Amount),Max=max(Amount,na.rm = TRUE), total=sum(Amount,na.rm=TRUE))

with(agg1,
plot_ly(
  x = paste(Period," ",Day) ,
  y = total,
  text = sapply(total,function(x) sprintf(as.double(x), fmt = "<b>$%#.2f")),
  name = "Total Daily Tolls",
  type = "bar",
  textposition = 'outside',
  opacity = 0.7,
  width = 1000,
  height = 600
) %>%
  add_trace(y=Frequency,
            text=Frequency,
            name="Toll Count",
            textposition='inside',
            type= "scatter",
            mode = 'markers+text',
            marker = list(size=7*Frequency)) %>%
  add_trace(y=Max,
            text = sapply(Max,function(x) sprintf(as.double(x), fmt = "<b>$%#.2f")),
            name="Largest Daily Toll") %>%
  layout(autosize = FALSE,

         title = "<b>EZ Pass Account Aggregate Amounts",
         xaxis = list(title = "",
                      showgridlines = FALSE,
                      tickangle = 80),
         yaxis = list(title = "EZ Pass Toll Amounts in USD",
                      showgridlines = FALSE))
)

with(agg2,
     plot_ly(
       x = Period,
       y = total,
       text = sapply(total,function(x) sprintf(as.double(x), fmt = "<b>$%#.2f Total")),
       name = "Totals",
       type = "bar",
       textposition = 'outside',
       opacity = 0.7,
       width = 1000,
       height = 600
     ) %>%
       add_trace(y=Frequency,
                 text=sapply(Frequency,function(x) paste("<b>",x, "<br>Toll Charges Incurred")),
                 name="Largest Toll",
                 textposition='top center',
                 type= "scatter",
                 mode = 'markers+text',
                 marker = list(size=7*Frequency)) %>%
       layout(autosize = FALSE,
              showlegend=FALSE,
              title = "EZ Pass Account Aggregate Amounts",
              xaxis = list(title = "",
                           showgridlines = FALSE,
                           tickangle = 40),
              yaxis = list(title = "<b>EZ Pass Toll Amounts in USD",
                           showgridlines = FALSE))
)
