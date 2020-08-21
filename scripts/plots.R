
library(ggplot2)
library(dplyr)
library(reshape)
library(forcats)

data <- read.csv("cache/predictions.csv")

countryRanking <- data %>%
   group_by(name) %>%
   summarize(diff = mean(nbdiff,na.rm = T)) %>%
   arrange(diff)

countryRanking <- countryRanking[complete.cases(countryRanking),]

print(head(countryRanking,3))
print(tail(countryRanking,3))

varCountryPlot <- function(data,selector){
   ranking <- selector(countryRanking)

   melted <- data %>%
      #filter(name %in% ranking$name) %>%
      select(year,name,nbdiff,olsdiff,zidiff) %>%
      melt(id.vars = c("year","name")) %>%
      mutate(variable = fct_recode(variable,
         `Negative Binomial` = "nbdiff",
         `Zero Inflated Neg. Bin.`= "zidiff",
         OLS = "olsdiff"
         ))

   mse <- melted %>%
      group_by(variable) %>%
      summarize(mse = mean(abs(value),na.rm = T))

   melted <- filter(melted,name %in% ranking$name)
   melted <- merge(melted,ranking,by="name")
   melted <- merge(melted,mse,by="variable")
   print(head(melted))

   #melted$name <- ordered(melted$name)
   #levels(melted$name) <- rev(ranking$name)
   #print(ranking)
   #print(melted$name)

   ggplot(melted,aes(x = year, y = value,color = fct_reorder(name,-diff),linetype=fct_reorder(variable,mse))) +
      geom_line() +
      labs(
           x = "Year", 
           y = "Actual - Predicted",
           linetype = "Model",
           color = "Country"
        )

}

topN <- function(data,n){
   varCountryPlot(data,function(d){head(d,n)})
}

bottomN <- function(data,n){
   varCountryPlot(data,function(d){tail(d,n)})
}

ggsave("plots/tf.png",topN(data,6),height=6,width=14)
ggsave("plots/bf.png",bottomN(data,6),height=6,width=14)
writeLines("done")
