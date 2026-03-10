# Uber Dashboard – R Shiny

An interactive Uber trip-data dashboard built entirely in **R** using [Shiny](https://shiny.posit.co/) and [shinydashboard](https://rstudio.github.io/shinydashboard/).

---

## Features

| Tab | What you see |
|-----|--------------|
| **Overview** | KPI value-boxes (total trips, total revenue, average fare, average duration) plus bar charts by month, payment-type pie, trips-by-base, and fare distribution |
| **Trips Analysis** | Trips by hour of day, trips by day of week, distance-vs-fare scatter |
| **Map View** | Interactive Leaflet map of pickup locations across New York City |
| **Time Analysis** | Hour × weekday heatmap, average fare by hour, average duration by weekday |
| **Data Table** | Paginated, searchable DT table of individual trip records |

Sidebar **filters** (Month and Base) apply instantly to every chart and table on all tabs.

---

## Dataset

The app ships with a **synthetic** NYC-style Uber dataset (5 000 trips, calendar year 2014) generated with a fixed random seed, so results are fully reproducible without any external data files.

---

## Requirements

- R ≥ 4.1
- The following CRAN packages:

| Package | Purpose |
|---------|---------|
| `shiny` | App framework |
| `shinydashboard` | Dashboard layout |
| `plotly` | Interactive charts |
| `leaflet` | Interactive map |
| `DT` | Interactive data table |
| `dplyr` | Data manipulation |
| `lubridate` | Date helpers |

---

## Quick Start

```r
# 1. Install dependencies (only needed once)
source("install_packages.R")

# 2. Launch the dashboard
shiny::runApp()
```

Or directly from the R console:

```r
shiny::runApp("/path/to/Uber_Dashboard_R")
```

---

## Project Structure

```
Uber_Dashboard_R/
├── app.R               # Main Shiny UI + server
├── global.R            # Dataset generation (sourced automatically by Shiny)
├── install_packages.R  # One-time package installer
└── README.md
```

---

## Screenshots

> _Run the app locally to see the interactive dashboard._

---

## License

[MIT](LICENSE)