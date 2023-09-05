library(tidyverse)
library(readxl)
library(sf)
library(arrow)
library(lubridate)

# --------------------------  Reading Global datasets ----
stringency <- readRDS("owid_covid_data.rds") %>% 
  filter(location == "United Kingdom") %>% 
  select(date, stringency_index) %>% 
  mutate(date = format(date, "%Y-%m")) %>% 
  group_by(date) %>% summarise(StringencyIndex = mean(stringency_index)) %>% 
  mutate(StringencyIndex = ifelse(is.na(StringencyIndex), 0, StringencyIndex)) %>% 
  filter(date <= "2023-05")

# data can be downloaded from:
# https://geoportal.statistics.gov.uk/datasets/196d1a072aaa4882a50be333679d4f63/explore?location=32.483421%2C-48.094640%2C3.86
shapefile <- st_read("Local_Authority_Districts/LAD_MAY_2022_UK_BFE_V3.shp") %>% 
  rename(la_code = LAD22CD) %>% 
  select(la_code, LAD22NM, geometry) %>%
  filter(grepl("^[WE]", la_code))


la_street_data_all <- readRDS("la_street_without_manchester.rds") %>% 
  rename(crime_type = `Crime type`) %>% 
  mutate(la_code = case_when(la_code == 'E07000004' ~ 'E06000060', #some local authorities has been merged recently
                             la_code == 'E07000005' ~ 'E06000060', #and they are not in the crime data
                             la_code == 'E07000006' ~ 'E06000060', #to fix this problem we used the correct la_codes from: https://findthatpostcode.uk/
                             la_code == 'E07000007' ~ 'E06000060',
                             la_code == 'E07000150' ~ 'E06000061',
                             la_code == 'E07000151' ~ 'E06000062',
                             la_code == 'E07000152' ~ 'E06000061' ,
                             la_code == 'E07000153' ~ 'E06000061',
                             la_code == 'E07000154' ~ 'E06000062',
                             la_code == 'E07000155' ~ 'E06000062',
                             la_code == 'E07000156' ~ 'E06000061',
                             T ~ la_code)) %>% 
  group_by(la_code, Month, crime_type) %>% 
  summarise(count = sum(count)) %>% 
  ungroup()

# Transforming universal datasets
df_str = data.frame(id.month = seq(1, 101, 1), stringency = c(rep(0, 60), stringency$StringencyIndex))
df_time = data.frame(Month = unique(la_street_data_all$Month), 
                     id.month = seq(1, length(unique(la_street_data_all$Month)), 1)) %>% 
  mutate(month = month(ym(Month)),
         quarter = quarter(month)) %>% 
  select(-month)

# -------------------------- Global Useful functions: ----
df_cleaner = function(df, anomalies = c()){
  # Filters the anomalies from the crime dataset
  
  #-Args: 
  #     df (DataFrame): Dataframe containing crime data of a specific city
  #     anomalies (numeric): The msoa code of the anomalous regions detected with the checking_map function
  #-Returns:
  #     A cleaned DataFrame without anomalous polygons 
  
  ls = list()
  correct_polygones = shapefile %>% 
    filter(la_code %in% df[['la_code']]) %>% 
    mutate(id.area = seq(1,nrow(.),1)) %>% 
    filter(!id.area %in% anomalies)
  
  filtering_list = correct_polygones$la_code
  
  ls[[1]] = df %>% 
    filter(la_code %in% filtering_list)
  ls[[2]] = correct_polygones
  
  return(ls)
}

create_inla_df = function(crime_df, df_msoa){
  # It creates a suitable modeling dataset for the INLA package 
  # It builds the dataset suitable for the following model:
  # formula <- value ~ f(id.area, model = "bym", graph = g) + 
  #   f(id.area1, id.month, model = "iid") + 
  #   f(id.area2, strigency, model = "iid") +
  #   f(id.month, model = 'rw1', constr=FALSE)
  #   id.month
  
  #-Args:
  #   crime_df (DataFrame): An aggregated crime dataset (output of the aggregator function)
  #   df_msoa (DataFrame): A dataframe containing polygones of the target city to be joined with the crime dataset
  
  #-Retruns:
  #   DataFrame
  
  
  df_inla <- list(crime_df, df_msoa, df_time) %>% 
    reduce(left_join) %>% 
    ungroup() %>% 
    select(id.month, quarter, id.area, count, la_code)
  
  # Adding Stringency index
  df_inla = df_inla %>% 
    left_join(.,df_str) %>% # Attaching strigency index %>% 
    mutate(id.space.time = as.numeric(rownames(.))) #add space time indicator 
  
  # Creating variable ids to be used by INLA
  df_inla$id.area1 = df_inla$id.area # INLA requires different inputs of the same variable! 
  df_inla$id.area2 = df_inla$id.area 
  df_inla$id.month2 = df_inla$id.month
  return(df_inla)
  
}

# ------------------------------------ Prep: uk data -------------------------------------
# Put zero if a crime is not present for a location-time in the dataset
unique_crimes = unique(la_street_data_all$crime_type)
unique_space = unique(la_street_data_all$la_code)
unique_time = unique(la_street_data_all$Month)

space_time_crime = crossing(unique_space, unique_time, unique_crimes)
names(space_time_crime) = names(la_street_data_all)[1:3]
uk_all_crimes = left_join(space_time_crime, la_street_data_all)
uk_all_crimes = uk_all_crimes %>% mutate(count = ifelse(is.na(count),0,count))

# These area ids should be removed: NONE
clean_df_and_polygones = df_cleaner(uk_all_crimes)
uk_cleaned = clean_df_and_polygones[[1]]

# [1] "Anti-social behaviour"       
# [2] "Bicycle theft"               
# [3] "Burglary"                    
# [4] "Criminal damage and arson"   
# [5] "Drugs"                       
# [6] "Other crime"                 
# [7] "Other theft"                 
# [8] "Possession of weapons"       
# [9] "Public order"                
# [10] "Robbery"                     
# [11] "Shoplifting"                 
# [12] "Theft from the person"       
# [13] "Vehicle crime"               
# [14] "Violence and sexual offences"


df_uk <- uk_cleaned %>% filter(crime_type == "Violence and sexual offences")

#joining msoa geography to the crime dataset + population_uk dataset
la_uk = clean_df_and_polygones[[2]] %>% mutate(id.area = seq(1,nrow(.),1))

df_inla = create_inla_df(df_uk, la_uk)


