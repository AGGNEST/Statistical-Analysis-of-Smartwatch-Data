# Statistical-Analysis-of-Smartwatch-Data

# Overview
This project focuses on preparing and preprocessing the **Smartwatch Health Data (Uncleaned)** dataset obtained from Kaggle. The dataset contains health and activity-related measurements collected from smartwatch devices.
The project identifies and addresses common data quality issues, including **missing values, outliers, inconsistent values, typos, and invalid entries**, using SAS.

# Dataset

* 10,000 observations
* 7 variables
* Health and activity metrics including:
  * Heart Rate (BPM)
  * Blood Oxygen Level (%)
  * Step Count
  * Sleep Duration (hours)
  * Activity Level
  * Stress Level
  * User ID

# Objectives

* Explore the structure and quality of the dataset.
* Identify missing values, inconsistencies, and data entry errors.
* Detect and evaluate outliers using the (IQR method)
* Clean and preprocess the dataset.
* Impute missing numerical values using (FCS REG) and (Predictive Mean Matching (PMM)).
* Handle missing categorical and ordinal values using appropriate imputation methods.
* Evaluate the performance of a logistic regression model for predicting missing Activity Level values.

# Methods
## Data Exploration
* Dataset structure and variable types
* Summary statistics
* Missing value detection
* Frequency analysis
* Distribution analysis

## Data Cleaning
* Removal of records with missing User IDs
* Correction of typos and inconsistent categories
* Conversion of invalid values to missing values
* Detection and removal of implausible outliers

## Missing Value Imputation
* (FCS REG) for Sleep Duration
* (FCS REGPMM) (Predictive Mean Matching) for Heart Rate, Blood Oxygen Level, and Step Count
* (Median imputation by Activity Level) for Stress Level
* (Mode imputation) for missing Activity Level values after evaluating logistic regression performance

## Tools
* SAS
* PROC UNIVARIATE
* PROC MEANS
* PROC FREQ
* PROC SGPLOT
* PROC SQL
* PROC MI
* PROC LOGISTIC

# Key Results
* Identified and addressed multiple data quality issues.
* Removed records with missing User IDs.
* Removed implausible Sleep Duration and Heart Rate observations.
* Retained statistically detected Blood Oxygen outliers when they were considered physiologically plausible.
* Imputed missing numerical values while maintaining similar statistical distributions.
* Evaluated logistic regression for predicting missing Activity Level values; the model showed limited classification performance.
* Mode imputation using (Sedentary), the most frequent category, was therefore applied to remaining missing Activity Level values.

# Project Report
For the complete methodology, SAS code, statistical outputs, visualizations, and detailed analysis:

**[View Full Project Report (PDF)](Statistical_Analysis_of_Smartwatch_Report.pdf)**

# Author

**Abdullah A. Alghamdi**
