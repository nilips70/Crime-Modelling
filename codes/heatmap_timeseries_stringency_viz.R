library(tidyverse)
library(readxl)
library(sf)
library(rgdal)
library(spdplyr)
library(tigris)
library(lubridate)
library(reshape2)
library(gplots)

###################################################################
#                   STRINGENCY TIMESERIES PLOT
###################################################################
# reading the stringency dataset 
owid_covid_data <- readRDS("owid_covid_data.rds")

# filtering the data to only include United Kingdom and aggregate over the month 
stringency_uk <- owid_covid_data %>% 
  filter(location == "United Kingdom") %>% 
  select(date, stringency_index) %>% 
  mutate(date = format(date, "%Y-%m")) %>% 
  group_by(date) %>% summarise(StringencyIndex = mean(stringency_index)) %>% 
  mutate(StringencyIndex = ifelse(is.na(StringencyIndex), 0, StringencyIndex)) %>% 
  filter(date < "2022-12-31") 

# time series of the stringency index in the UK
stringency_uk %>% 
  add_row(date = '2019-12', StringencyIndex = 0) %>% 
  mutate(date = ym(date)) %>%
  ggplot(aes(date, StringencyIndex)) + 
  geom_line() + 
  geom_point() + 
  scale_x_date(date_breaks = "2 month",
               date_labels = "%Y %b") +
  scale_y_continuous(limits = c(0, 100), breaks = c(0, 10, 20, 30, 40, 50, 60, 70 , 80, 90,100)) +
  labs(x = 'Date', y = 'Stringency Index') + 
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 45, margin = margin(t = 12), size = 10),
        axis.title.x = element_text(face = 'bold'),
        axis.title.y = element_text(face = 'bold', size = 10))



###################################################################
#                   CRIME TIMESERIES AND HEATMAPS
###################################################################
# reading the all street crime data
la_street_data_all <- arrow::read_parquet("la_street_data_all.parquet")

df <- la_street_data_all %>%
  mutate(la_id = as.numeric(as.factor(la_code)))

# We want to check the presence of all possible combinations of locations and months within the dataset;
#if any are missing, we will consider them as having a value of zero.

la_id = na.omit(unique(df$la_id))
Month = na.omit(unique(df$Month))

locs_months = crossing(la_id, Month)

# [1] Anti-social behaviour        Burglary                     Other crime                  Robbery                      Vehicle crime                          
# [7] Criminal damage and arson    Drugs                        Other theft                    Shoplifting                  Bicycle theft               
# [13] Possession of weapons        Public order                 Theft from the person        Violence and sexual offences

# you can change the crime category here
target_crime = "Anti-social behaviour"

test_bulgary = left_join(locs_months, df %>% filter(`Crime type` == {target_crime})) %>% 
  mutate(count = ifelse(is.na(count), 0, count)) %>% 
  group_by(la_id) %>% 
  mutate(variance = var(count, na.rm = T)) %>% 
  filter(variance > 0) %>% 
  mutate(z_value = (count - mean(count, na.rm = T))/sd(count, na.rm = T),
         Month = lubridate::ym(Month))

# visualization
p1 = test_bulgary %>% 
  ggplot() + geom_tile(aes(x = Month, y = la_id, fill = z_value)) +
  scale_fill_gradient2(midpoint = 0, low = "darkgreen", mid = "white", high = "red") + 
  geom_vline(xintercept = as.Date("2020-03-01"), linetype = 'dashed') +
  geom_vline(xintercept = as.Date("2022-05-22"), linetype = 'dashed') +
  theme_classic() + #ggtitle(paste0({target_crime})) + 
  labs( x = "Date",y = "Local Authorities", caption = "(b)") +
  theme(legend.position = "top", 
        axis.text.x = element_text(angle = 45, vjust = 0.5),
        plot.caption = element_text(hjust = 0.5)) 
  #scale_y_continuous(breaks = seq(0, 339, by = 10))

p2 = test_bulgary %>% 
  group_by(Month) %>% 
  summarise(count = sum(count)) %>% 
  ungroup() %>% 
  ggplot(aes(x = Month, y = count)) + geom_point() + geom_line() +
  geom_vline(xintercept = as.Date("2020-03-01"), linetype = 'dashed') + 
  geom_vline(xintercept = as.Date("2022-05-22"), linetype = 'dashed') +
  labs( x = "Date", y = "Total Crime Count", caption = "(a)") +
  theme_classic() + #ggtitle({target_crime}) + 
  theme(axis.text.x   = element_text(angle = 45, vjust = 0.5),
                                                    plot.caption = element_text(hjust = 0.5)) 


#ggpubr::ggarrange(p2, p1,  ncol = 1, nrow = 2)


###################################################################
#                   to check valididty of the shapefile
# whether it has all the local authorities and boundries of the study region
###################################################################
# to check whether the shapefile has no problem
# it can be downloaded from:
# https://geoportal.statistics.gov.uk/datasets/196d1a072aaa4882a50be333679d4f63/explore?location=32.483421%2C-48.094640%2C3.86
shapefile <- st_read("Local_Authority_Districts/LAD_MAY_2022_UK_BFE_V3.shp") %>% 
  rename(la_code = LAD22CD)

geometry_uk <- shapefile %>% 
  select(la_code, LAD22NM, geometry)

# df o dast nakhorde bekhun
la_england_wales <- arrow::read_parquet("la_street_data_all.parquet") %>%
  select(la_code) %>% distinct()

test <- left_join(la_england_wales, geometry_uk)
test <- st_as_sf(test)

ggplot() + geom_sf(data = shapefile)
