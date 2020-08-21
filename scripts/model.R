
library(dplyr)
library(tibble)
library(ggplot2)
library(countrycode)
library(texreg)
library(MASS)
library(pscl)
library(fixest)

data <- read.csv("cache/data.csv")

data$name <- countrycode(data$cow,origin="cown",destination="country.name.en")
data$reg <- countrycode(data$cow,origin="cown",destination="region")
data$cont <- countrycode(data$cow,origin="cown",destination="continent")

data <- data[complete.cases(data),]

pois <- glm(fatalities~pts+year + as.factor(cow),family="poisson",data = data)
ols <- lm(fatalities~pts+year+as.factor(cow),data=data)
zi <- zeroinfl(fatalities ~ pts + year + as.factor(cow),data=data,dist="negbin")
nb <- fenegbin(fatalities ~ pts + year | reg, data = data)
#cnb <- glm.nb(fatalities ~ pts + year|as.factor(cow),data=data)

data$pois <- predict(pois,data,type="response")
data$ols <- predict(ols,data)
data$zi <- predict(zi,data,type="response")
data$nb <- predict(nb,type="response")
#data$cnb <- predict(cnb,type="response")

data$pdiff <- (data$fatalities-data$pois)
data$olsdiff <- (data$fatalities-data$ols)
data$zidiff <- (data$fatalities-data$zi)
data$nbdiff <- (data$fatalities-data$nb)
#data$cnbdiff <- (data$fatalities-data$cnb)

write.csv(data,"cache/predictions.csv")

ranked <- data %>%
   dplyr::select(year,name,fatalities,zi,zidiff) %>%
   arrange(zidiff)

write.csv(head(ranked,20),"cache/top20.csv")
write.csv(tail(ranked,20),"cache/bottom20.csv")
