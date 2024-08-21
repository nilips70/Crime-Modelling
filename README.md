# Effects of pandemic response measures on crime counts in English and Welsh local authorities
This repository contains the code for the paper, "Effects of pandemic response measures on crime counts in English and Welsh local authorities". 

# Overview 
This paper delves into the changes in crime trends in England and Wales from 2015 to 2023. Our aim was to explore how the stringency index and the pandemic affected different crime types across various regions in England and Wales. We utilized the Bayesian spatiotemporal model to discern the effects of the stringency index on crime. For accounting for spatial and temporal dependencies, the Conditional Auto-regressive (CAR) model was implemented using INLA in R.

**Authors:** Niloufar Pourshir Sefidi, Amin Shoari Nejad, Peter Mooney

## Repository Structure

### 1) DATA:
This folder contains the datasets used for this study. Some datasets are sizeable and thus have not been included directly due to GitHub's size constraints. However, links for downloading these datasets have been provided:

#### Crime Data:
Raw historical street crime data from the UK can be retrieved from the UK POLICE archive from the below link. This dataset is not included in the repository because it exceeds GitHub's size limit. However, a summarized and final version is included under the name `la_street_data_all.parquet`.
https://data.police.uk/data/archive/[year]-[month].zip

#### LSOA to LA Code Converter Data:
A table containing the LSOA codes in the UK and their corresponding LA codes is available in the `lasoa_la_uk.csv` file.


#### Stringency Index Data:
This dataset contains the stringency index values specifically for the 'United Kingdom'. [Download the dataset here](https://ourworldindata.org/explorers/coronavirus-data-explorer?uniformYAxis=0&country=~GBR&hideControls=true&Interval=7-day+rolling+average&Relative+to+Population=true&Color+by+test+positivity=false&Metric=Stringency+index).
This data is also available in the repo under the name `owid-covid-data.csv`.

#### UK Local Authorities Boundaries Shapefile:
The shapefile detailing the boundaries of local authorities in the UK can be found [here](https://geoportal.statistics.gov.uk/datasets/196d1a072aaa4882a50be333679d4f63/explore?location=32.483421%2C-48.094640%2C3.86).

### 2) CODE:
This section comprises the codebase employed for preprocessing, analysis, and visualization.

- **attaching_crime_data.ipynb**: This Python script merges all crime data, attaching the relevant local authority codes to the LSOA codes present in the crime dataset.
  
- **data_preparation_excluding_manchester.R**: Given the unavailability of data for Greater Manchester Police post-July 2019, this file contains the R script responsible for excluding the Manchester data from the generated dataset.
  
- **heatmap_timeseries_stringency_viz.R**: Contains the code to create a time series plot showcasing the stringency index for the UK, spanning 2020 to 2022. It also provides visualizations in the form of heatmaps and time series for different crime types mentioned in the paper.


## Contact

If you have any questions or need further assistance, please contact the corresponding author, Pourshir Sefidi, at niloufar.pourshirsefidi.2022@mumail.ie
