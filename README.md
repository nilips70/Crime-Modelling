# Unmasking Lockdown Effects: Crime Rates Across England and Wales' Local Authorities
This GitHub repository is for the research project titled "Unmasking Lockdown Effects: Crime Rates Across England and Wales' Local Authorities". This repository contains the necessary data and codes to reproduce the findings presented in the associated paper.

# Overview 
This paper delves into the changes in crime trends in England and Wales from 2015 to 2023. Our aim was to explore how the stringency index and the pandemic affected different crime types across various regions in England and Wales. We utilized the Bayesian spatiotemporal model to discern the effects of the stringency index on crime. For accounting for spatial and temporal dependencies, the Conditional Auto-regressive (CAR) model was implemented using INLA in R.

**Authors:** Niloufar Pourshir Sefidi, Amin Shoari Nejad, Peter Mooney



# Steps & Details
**Step 1: Data Retrieval**


Retrieve the historical data on street crime in the UK from the UK POLICE archive.

Link to UK POLICE Archive

**Step 2: Data Consolidation**


After downloading the street crime data, which is organized by month and year in compressed zip files, consolidate all the CSV files into a singular folder within the specified directory.

**Step 3: Data Linking**


Use the Python script named attaching_crime_data.ipynb to merge all the crime data and associate the local authority codes with the LSOA codes present in the crime dataset.

**Step 4: Data Cleaning**


Due to the absence of data for Greater Manchester Police since July 2019, this police force has been excluded from our study. To remove the Manchester data from the aggregated crime dataset (from Step 3), utilize the code in the data_preparation_excluding_manchester.R file.

**Step 5: Stringency Index Data Retrieval**


Fetch the dataset containing the stringency index values and filter it to only encompass data related to the 'United Kingdom'.

Link to Stringency Index Data

For generating a time series plot depicting the stringency index for the UK for the years 2020 to 2022, refer to the stringency_plot.R file.

**Step 6: Visualization**


For the creation of a time series plot illustrating the stringency index for the UK (from 2020 to 2022) and the heatmap plus time series visualizations for different crime types, refer to the code in heatmap_timeseries_stringency_viz.R.

**Step 7: Geospatial Data**


The shapefile for the boundaries of the local authorities in the UK can be accessed from the link provided:

Local Authorities Boundaries Shapefile

