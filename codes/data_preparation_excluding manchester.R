library(tidyverse)
library(readxl)
library(sf)
library(arrow)
library(data.table) #for reducing the data size of data

################################################################################
# ~~~~~~~~~~~~~~~~~.  GREATER MANCHESTER
################################################################################
# reading all street crime datasets for greater manchester
temp_st <- list.files(path = paste0(getwd(), "/Archived data/all crimes"), pattern = "*-greater-manchester-street.csv")
temp_st <- paste0(getwd(), "/Archived data/all crimes/", temp_st)
street <- lapply(temp_st, read_csv)

df_street_manchester <- street %>% reduce(rbind)

# extracting the unique lsoa codes from greater manchester
manchester_lsoas <- df_street_manchester %>% 
  distinct(`LSOA code`) %>% 
  rename(lsoa_code = `LSOA code`)


# read the lsoa-msoa-la dataset of uk
lsoa_msoa_uk <- read.csv(gzfile("lsoa_msoa_uk.csv.gz")) %>%
  select(lsoa11cd, ladcd) %>% rename(la_code = ladcd, lsoa_code = lsoa11cd)


# to get the la codes of the greater manchester lsoa codes
manchester_las <- left_join(manchester_lsoas, lsoa_msoa_uk) %>% 
  pull(la_code) %>%
  unique()

# reading the all street crime data since 2015
la_street_data_all <- arrow::read_parquet("la_street_data_all.parquet")

# filter out the rows that are in the greater manchester province 
la_street_without_manchester <- la_street_data_all %>% 
  filter(!la_code %in% manchester_las)

saveRDS(la_street_without_manchester, "la_street_without_manchester.rds")


