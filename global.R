# global.R – data generation for Uber Dashboard
# This script creates a synthetic Uber-like NYC trip dataset used by app.R.

library(dplyr)
library(lubridate)

set.seed(42)
n <- 5000

# NYC approximate bounding box
lat_range <- c(40.62, 40.88)
lon_range <- c(-74.05, -73.76)

# Hour-of-day probability weights (morning/evening peaks)
hour_weights <- c(
  0.020, 0.012, 0.010, 0.010, 0.015, 0.025,   # 00–05
  0.040, 0.065, 0.060, 0.050, 0.040, 0.040,   # 06–11
  0.040, 0.040, 0.040, 0.050, 0.060, 0.070,   # 12–17
  0.070, 0.065, 0.055, 0.050, 0.040, 0.032    # 18–23
)

uber_data <- data.frame(
  trip_id        = 1:n,
  date           = sample(seq(as.Date("2014-01-01"), as.Date("2014-12-31"), by = "day"),
                          n, replace = TRUE),
  hour           = sample(0:23, n, replace = TRUE, prob = hour_weights),
  pickup_lat     = runif(n, lat_range[1], lat_range[2]),
  pickup_lon     = runif(n, lon_range[1], lon_range[2]),
  fare           = round(pmax(rnorm(n, mean = 15, sd = 7), 2.50), 2),
  trip_duration  = round(pmax(rnorm(n, mean = 15, sd = 8), 1.0),  1),
  distance       = round(pmax(rnorm(n, mean = 3.5, sd = 2.0), 0.1), 1),
  base           = sample(c("B02512", "B02598", "B02617", "B02682", "B02764"),
                          n, replace = TRUE),
  payment_type   = sample(c("Credit Card", "Cash", "No Charge"),
                          n, replace = TRUE, prob = c(0.70, 0.25, 0.05)),
  stringsAsFactors = FALSE
)

uber_data <- uber_data %>%
  mutate(
    weekday = weekdays(date),
    month   = factor(months(date),
                     levels = c("January","February","March","April","May","June",
                                "July","August","September","October","November","December"),
                     ordered = TRUE)
  )

day_order   <- c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
month_order <- levels(uber_data$month)
