# BUSINESS SCIENCE UNIVERSITY
# DS4B 103-R: TIME SERIES FORECASTING FOR BUSINESS
# MODULE: FEATURE ENGINEERING

# GOAL ----
# - FIND ENGINEERED FEATURES BEFORE MODELING

# OBJECTIVES:
# - Time-Based Features - Trend-Based & Seasonal Features
# - Interactions
# - Fourier Series
# - Autocorrelated Lags
# - Special Events
# - External Regressor Lags

# LIBRARIES & DATA ----

# Core
library(tidyverse)
library(lubridate)
library(timetk)
library(plotly)

# Data
google_analytics_summary_tbl <- read_rds("00_data/google_analytics_summary_hourly.rds")

learning_labs_tbl <- read_rds("00_data/learning_labs.rds") 

subscribers_tbl   <- read_rds("00_data/mailchimp_users.rds")


# DATA PREPARATION ----
# - Apply Preprocessing to Target
data_prepared_tbl <- subscribers_tbl %>%
    summarize_by_time(optin_time, "day", optins = n()) %>%
    pad_by_time(optin_time, .pad_value = 0) %>%
    
    # pre-processing
    mutate(optins_trans = log_interval_vec(optins, limit_lower = 0, offset = 1)) %>%
    mutate(optins_trans = standardize_vec(optins_trans)) %>%
    
    # fix missing values
    filter_by_time(.start_date = "2018-07-03") %>%
    
    # cleaning
    mutate(optins_trans_cleaned = ts_clean_vec(optins_trans, period = 7)) %>%
    mutate(optins_trans = ifelse(optin_time %>% between_time("2018-11-18", "2018-11-20"), optins_trans_cleaned, optins_trans)) %>%
    select(-optins, -optins_trans_cleaned)
    

data_prepared_tbl %>%
    select(-optins) %>%
    pivot_longer(-optin_time) %>%
    plot_time_series(optin_time, value, name)

# FEATURE INVESTIGATION ----

# 1.0 TIME-BASED FEATURES ----
# - tk_augment_timeseries_signature()

# * Time Series Signature ----
data_prep_signature_tbl <- data_prepared_tbl %>% 
    tk_augment_timeseries_signature() %>%
    select(-diff, 
           -contains(".iso"),
           -contains(".xts"), 
           -matches("(hour)|(minute)|(second)|(am.pm)"))

data_prep_signature_tbl %>% glimpse()

# * Trend-Based Features ----

# ** Linear Trend
data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = optins_trans ~ index.num
    )

# ** Nonlinear Trend - Basis Splines
data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = optins_trans ~splines::bs(index.num, degree = 3),
        .show_summary = T
    )

data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = optins_trans ~ splines::ns(index.num,
                                              knots = quantile(index.num, probs = c(0.25, 0.5, 0.75)))
        ,
        .show_summary = T
    )

# * Seasonal Features ----

# ** Weekly Seasonality
data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = optins_trans ~ wday.lbl
        ,
        .show_summary = T
    )

# ** Monthly Seasonality
data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = optins_trans ~ month.lbl,
        .show_summary = T
    )

# ** Together with Trend

model_formula_seasonality <- as.formula(
    optins_trans ~ splines::ns(index.num, knots = quantile(index.num, probs = c(0.25, 0.5))) +
        month.lbl + wday.lbl + .
)

data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = model_formula_seasonality,
        .show_summary = T
    )


# 2.0 INTERACTIONS ----

model_formula_interactions <- as.formula(
    optins_trans ~ splines::ns(index.num, knots = quantile(index.num, probs = c(0.25, 0.5))) +
        . +
         (as.factor(week2) * wday.lbl)
)

data_prep_signature_tbl %>%
    plot_time_series_regression(
        optin_time,
        .formula = model_formula_interactions,
        .show_summary = T
    )

# 3.0 FOURIER SERIES ----
# - tk_augment_fourier

# Data Prep


# Model


# Visualize


# 4.0 LAGS ----
# - tk_augment_lags()

# Data Prep


# Model


# Visualize


# 5.0 SPECIAL EVENTS ----

# Data Prep


# Model


# Visualize

# 6.0 EXTERNAL LAGGED REGRESSORS ----
# - xregs

# Data Prep


# Model


# Visualize

# 7.0 RECOMMENDATION ----
# - Best model: 
# - Best Model Formula:
