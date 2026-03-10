# install_packages.R
# Run this script once to install all packages required by the Uber Dashboard.

packages <- c(
  "shiny",
  "shinydashboard",
  "plotly",
  "leaflet",
  "DT",
  "dplyr",
  "lubridate"
)

to_install <- packages[!packages %in% rownames(installed.packages())]

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install)
} else {
  message("All required packages are already installed.")
}
