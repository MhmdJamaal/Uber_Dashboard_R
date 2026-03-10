# app.R – Uber Dashboard built with R Shiny
# Run with: shiny::runApp()

library(shiny)
library(shinydashboard)
library(plotly)
library(leaflet)
library(DT)
library(dplyr)

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- dashboardPage(
  skin = "black",

  # Header
  dashboardHeader(
    title = tags$span(
      tags$strong("Uber", style = "color: #ffffff; font-size: 20px;"),
      tags$span(" Dashboard", style = "color: #cccccc; font-size: 18px;")
    ),
    titleWidth = 260
  ),

  # Sidebar
  dashboardSidebar(
    width = 260,
    sidebarMenu(
      id = "sidebar",
      menuItem("Overview",       tabName = "overview", icon = icon("gauge-high")),
      menuItem("Trips Analysis", tabName = "trips",    icon = icon("car")),
      menuItem("Map View",       tabName = "map",      icon = icon("map-location-dot")),
      menuItem("Time Analysis",  tabName = "time",     icon = icon("clock")),
      menuItem("Data Table",     tabName = "data",     icon = icon("table"))
    ),
    hr(),
    div(
      style = "padding: 0 15px;",
      tags$p("Filters", style = "color: #aaaaaa; font-weight: bold; margin-bottom: 8px;"),
      selectInput("month_filter", "Month:",
                  choices  = c("All", month_order),
                  selected = "All"),
      selectInput("base_filter", "Base:",
                  choices  = c("All", sort(unique(uber_data$base))),
                  selected = "All")
    )
  ),

  # Body
  dashboardBody(
    tags$head(tags$style(HTML("
      /* header & sidebar colours */
      .skin-black .main-header .logo,
      .skin-black .main-header .navbar          { background-color: #000000; }
      .skin-black .main-sidebar                 { background-color: #111111; }
      .skin-black .main-sidebar .sidebar-menu>li.active>a,
      .skin-black .main-sidebar .sidebar-menu>li>a:hover { background-color: #222222; }

      /* card / box tweaks */
      .box-header { border-bottom: 1px solid #e0e0e0; }
      .small-box h3 { font-size: 30px; }
      .small-box .icon-large { font-size: 55px; }

      /* content background */
      .content-wrapper, .right-side { background-color: #f5f5f5; }
    "))),

    tabItems(

      # ── Overview ────────────────────────────────────────────────────────────
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("vb_trips",    width = 3),
          valueBoxOutput("vb_revenue",  width = 3),
          valueBoxOutput("vb_avg_fare", width = 3),
          valueBoxOutput("vb_avg_dur",  width = 3)
        ),
        fluidRow(
          box(title = "Trips per Month",   status = "primary", solidHeader = TRUE,
              width = 6, plotlyOutput("plt_trips_month")),
          box(title = "Revenue per Month", status = "success", solidHeader = TRUE,
              width = 6, plotlyOutput("plt_rev_month"))
        ),
        fluidRow(
          box(title = "Payment Type",   status = "warning", solidHeader = TRUE,
              width = 4, plotlyOutput("plt_payment")),
          box(title = "Trips by Base",  status = "info",    solidHeader = TRUE,
              width = 4, plotlyOutput("plt_base")),
          box(title = "Fare Distribution", status = "danger", solidHeader = TRUE,
              width = 4, plotlyOutput("plt_fare_dist"))
        )
      ),

      # ── Trips Analysis ──────────────────────────────────────────────────────
      tabItem(tabName = "trips",
        fluidRow(
          box(title = "Trips by Hour of Day", status = "primary", solidHeader = TRUE,
              width = 12, plotlyOutput("plt_hour", height = "350px"))
        ),
        fluidRow(
          box(title = "Trips by Day of Week", status = "info", solidHeader = TRUE,
              width = 6, plotlyOutput("plt_weekday")),
          box(title = "Distance vs Fare",     status = "success", solidHeader = TRUE,
              width = 6, plotlyOutput("plt_dist_fare"))
        )
      ),

      # ── Map View ────────────────────────────────────────────────────────────
      tabItem(tabName = "map",
        fluidRow(
          box(title = "Pickup Locations – New York City",
              status = "primary", solidHeader = TRUE, width = 12,
              leafletOutput("pickup_map", height = "560px"),
              footer = "Displaying a random sample of up to 1 000 pickup points.")
        )
      ),

      # ── Time Analysis ───────────────────────────────────────────────────────
      tabItem(tabName = "time",
        fluidRow(
          box(title = "Trips Heatmap: Hour × Day", status = "primary", solidHeader = TRUE,
              width = 12, plotlyOutput("plt_heatmap", height = "400px"))
        ),
        fluidRow(
          box(title = "Average Fare by Hour",       status = "warning", solidHeader = TRUE,
              width = 6, plotlyOutput("plt_fare_hour")),
          box(title = "Average Duration by Weekday", status = "info",   solidHeader = TRUE,
              width = 6, plotlyOutput("plt_dur_day"))
        )
      ),

      # ── Data Table ──────────────────────────────────────────────────────────
      tabItem(tabName = "data",
        fluidRow(
          box(title = "Trip Records (up to 500 rows)", status = "primary",
              solidHeader = TRUE, width = 12,
              DTOutput("tbl_trips"))
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Reactive filtered dataset
  fdata <- reactive({
    d <- uber_data
    if (input$month_filter != "All") d <- d[as.character(d$month) == input$month_filter, ]
    if (input$base_filter  != "All") d <- d[d$base  == input$base_filter,  ]
    d
  })

  # ── Value boxes ────────────────────────────────────────────────────────────

  output$vb_trips <- renderValueBox({
    valueBox(format(nrow(fdata()), big.mark = ","),
             "Total Trips", icon = icon("car"), color = "black")
  })

  output$vb_revenue <- renderValueBox({
    valueBox(paste0("$", format(round(sum(fdata()$fare)), big.mark = ",")),
             "Total Revenue", icon = icon("dollar-sign"), color = "green")
  })

  output$vb_avg_fare <- renderValueBox({
    valueBox(paste0("$", round(mean(fdata()$fare), 2)),
             "Avg Fare", icon = icon("receipt"), color = "yellow")
  })

  output$vb_avg_dur <- renderValueBox({
    valueBox(paste0(round(mean(fdata()$trip_duration), 1), " min"),
             "Avg Trip Duration", icon = icon("clock"), color = "blue")
  })

  # ── Overview charts ────────────────────────────────────────────────────────

  output$plt_trips_month <- renderPlotly({
    d <- fdata() %>% count(month, .drop = FALSE) %>% arrange(month)
    plot_ly(d, x = ~month, y = ~n, type = "bar",
            marker = list(color = "#000000")) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "Trips"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_rev_month <- renderPlotly({
    d <- fdata() %>% group_by(month) %>%
      summarise(revenue = sum(fare), .groups = "drop") %>% arrange(month)
    plot_ly(d, x = ~month, y = ~revenue, type = "bar",
            marker = list(color = "#28a745")) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "Revenue ($)"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_payment <- renderPlotly({
    d <- fdata() %>% count(payment_type)
    plot_ly(d, labels = ~payment_type, values = ~n, type = "pie",
            marker = list(colors = c("#000000", "#555555", "#999999"))) %>%
      layout(showlegend = TRUE,
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_base <- renderPlotly({
    d <- fdata() %>% count(base) %>% arrange(desc(n))
    plot_ly(d, x = ~base, y = ~n, type = "bar",
            marker = list(color = "#17a2b8")) %>%
      layout(xaxis = list(title = "Base"),
             yaxis = list(title = "Trips"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_fare_dist <- renderPlotly({
    plot_ly(fdata(), x = ~fare, type = "histogram",
            marker = list(color = "#dc3545")) %>%
      layout(xaxis = list(title = "Fare ($)"),
             yaxis = list(title = "Count"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  # ── Trips Analysis charts ──────────────────────────────────────────────────

  output$plt_hour <- renderPlotly({
    d <- fdata() %>% count(hour)
    plot_ly(d, x = ~hour, y = ~n, type = "bar",
            marker = list(color = "#000000")) %>%
      layout(xaxis = list(title = "Hour of Day", dtick = 1),
             yaxis = list(title = "Trips"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_weekday <- renderPlotly({
    d <- fdata() %>%
      count(weekday) %>%
      mutate(weekday = factor(weekday, levels = day_order)) %>%
      arrange(weekday)
    plot_ly(d, x = ~weekday, y = ~n, type = "bar",
            marker = list(color = "#17a2b8")) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "Trips"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_dist_fare <- renderPlotly({
    s <- fdata() %>% slice_sample(n = min(500, nrow(fdata())))
    plot_ly(s, x = ~distance, y = ~fare, type = "scatter", mode = "markers",
            marker = list(color = "#28a745", opacity = 0.5, size = 5)) %>%
      layout(xaxis = list(title = "Distance (miles)"),
             yaxis = list(title = "Fare ($)"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  # ── Map ────────────────────────────────────────────────────────────────────

  output$pickup_map <- renderLeaflet({
    s <- fdata() %>% slice_sample(n = min(1000, nrow(fdata())))
    leaflet(s) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~pickup_lon, lat = ~pickup_lat,
        radius      = 4,
        color       = "#000000",
        fillOpacity = 0.45,
        stroke      = FALSE,
        popup       = ~paste0(
          "<b>Base:</b> ", base, "<br>",
          "<b>Fare:</b> $", fare, "<br>",
          "<b>Duration:</b> ", trip_duration, " min<br>",
          "<b>Distance:</b> ", distance, " mi"
        )
      ) %>%
      setView(lng = -73.95, lat = 40.75, zoom = 11)
  })

  # ── Time Analysis charts ───────────────────────────────────────────────────

  output$plt_heatmap <- renderPlotly({
    d <- fdata() %>%
      count(weekday, hour) %>%
      mutate(weekday = factor(weekday, levels = rev(day_order)))
    plot_ly(d, x = ~hour, y = ~weekday, z = ~n, type = "heatmap",
            colorscale = list(c(0, "#ffffff"), c(1, "#000000")),
            showscale   = TRUE) %>%
      layout(xaxis = list(title = "Hour", dtick = 1),
             yaxis = list(title = ""),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_fare_hour <- renderPlotly({
    d <- fdata() %>% group_by(hour) %>%
      summarise(avg_fare = mean(fare), .groups = "drop")
    plot_ly(d, x = ~hour, y = ~avg_fare, type = "scatter", mode = "lines+markers",
            line   = list(color = "#ffc107"),
            marker = list(color = "#ffc107", size = 7)) %>%
      layout(xaxis = list(title = "Hour", dtick = 1),
             yaxis = list(title = "Avg Fare ($)"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  output$plt_dur_day <- renderPlotly({
    d <- fdata() %>%
      group_by(weekday) %>%
      summarise(avg_dur = mean(trip_duration), .groups = "drop") %>%
      mutate(weekday = factor(weekday, levels = day_order)) %>%
      arrange(weekday)
    plot_ly(d, x = ~weekday, y = ~avg_dur, type = "scatter", mode = "lines+markers",
            line   = list(color = "#17a2b8"),
            marker = list(color = "#17a2b8", size = 7)) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "Avg Duration (min)"),
             plot_bgcolor  = "transparent",
             paper_bgcolor = "transparent")
  })

  # ── Data Table ─────────────────────────────────────────────────────────────

  output$tbl_trips <- renderDT({
    fdata() %>%
      select(trip_id, date, hour, base, fare, distance, trip_duration, payment_type) %>%
      head(500) %>%
      datatable(
        options  = list(pageLength = 15, scrollX = TRUE, dom = "Bfrtip"),
        rownames = FALSE,
        colnames = c("ID", "Date", "Hour", "Base", "Fare ($)", "Distance (mi)",
                     "Duration (min)", "Payment")
      )
  })
}

# ── Launch ────────────────────────────────────────────────────────────────────

shinyApp(ui = ui, server = server)
