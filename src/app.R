library(shiny)
library(plotly)
library(dplyr)
library(readr)
library(lubridate)
library(rsconnect)


# ---------------- DATA ----------------
csv_path <- file.path("..", "data", "raw", "ncr_ride_bookings.csv")
uber <- read_csv(csv_path)

# Clean column names: replace spaces with underscores
names(uber) <- gsub(" ", "_", names(uber))

uber$Date <- as.Date(uber$Date)

# Combine cancellation reason columns into one
uber$Issue_Reason <- coalesce(
  uber$Reason_for_cancelling_by_Customer,
  uber$Driver_Cancellation_Reason,
  uber$Incomplete_Rides_Reason,
  ""
)

# ---------------- UI ----------------
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body { background: #f8f9fb; font-family: sans-serif; }
      .title { font-size: 18px; font-weight: 800; text-align: center; padding: 12px 0 4px; }
      .kpi-card {
        background: white;
        border-radius: 10px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        padding: 14px 10px;
        text-align: center;
        margin-bottom: 16px;
      }
      .kpi-label { font-size: 12px; font-weight: 600; color: #555; margin-bottom: 4px; }
      .kpi-value { font-size: 28px; font-weight: 700; color: #222; }
      .chart-card {
        background: white;
        border-radius: 10px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        padding: 12px;
      }
      .chart-title { font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #333; }
    "))
  ),

  div(class = "title", "Uber Data Visualization Dashboard"),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      sliderInput(
        inputId = "slider",
        label   = "Date Range",
        min     = min(uber$Date),
        max     = max(uber$Date),
        value   = c(min(uber$Date), max(uber$Date)),
        timeFormat = "%Y-%m-%d"
      ),
      actionButton("reset_btn", "Reset Filters", class = "btn btn-secondary btn-sm mt-2")
    ),

    mainPanel(
      width = 9,
      fluidRow(
        column(4,
          div(class = "kpi-card",
            div(class = "kpi-label", "Driver Cancellations"),
            div(class = "kpi-value", textOutput("driver_cancellations"))
          )
        ),
        column(4,
          div(class = "kpi-card",
            div(class = "kpi-label", "Customer Cancellations"),
            div(class = "kpi-value", textOutput("customer_cancellations"))
          )
        ),
        column(4,
          div(class = "kpi-card",
            div(class = "kpi-label", "Total Cancellations"),
            div(class = "kpi-value", textOutput("total_cancellations"))
          )
        )
      ),

      fluidRow(
        column(12,
          div(class = "chart-card",
            div(class = "chart-title", "Revenue Distribution by Vehicle Type"),
            plotlyOutput("pie_chart", height = "420px")
          )
        )
      )
    )
  )
)

# ---------------- SERVER ----------------
server <- function(input, output, session) {

  # Reset slider
  observeEvent(input$reset_btn, {
    updateSliderInput(session, "slider", value = c(min(uber$Date), max(uber$Date)))
  })

  # Reactive filtered data
  filtered_data <- reactive({
    uber %>%
      filter(Date >= input$slider[1], Date <= input$slider[2])
  })

  # Human-readable number formatting
  human_format <- function(num) {
    num <- as.numeric(num)
    if (abs(num) >= 1e9)      paste0(round(num / 1e9, 1), "B")
    else if (abs(num) >= 1e6) paste0(round(num / 1e6, 1), "M")
    else if (abs(num) >= 1e3) paste0(round(num / 1e3, 1), "K")
    else                      as.character(round(num))
  }

  # ---------------- KPIs ----------------
  output$driver_cancellations <- renderText({
    human_format(sum(filtered_data()$Cancelled_Rides_by_Driver == 1, na.rm = TRUE))
  })

  output$customer_cancellations <- renderText({
    human_format(sum(filtered_data()$Cancelled_Rides_by_Customer == 1, na.rm = TRUE))
  })

  output$total_cancellations <- renderText({
    df <- filtered_data()
    total <- sum(df$Cancelled_Rides_by_Driver == 1, na.rm = TRUE) +
              sum(df$Cancelled_Rides_by_Customer == 1, na.rm = TRUE)
    human_format(total)
  })

  # ---------------- PIE CHART ----------------
  output$pie_chart <- renderPlotly({
    revenue <- filtered_data() %>%
      group_by(Vehicle_Type) %>%
      summarise(Booking_Value = sum(Booking_Value, na.rm = TRUE), .groups = "drop")

    plot_ly(
      revenue,
      labels = ~Vehicle_Type,
      values = ~Booking_Value,
      type   = "pie",
      textinfo = "percent+label",
      textposition = "inside",
      marker = list(colors = RColorBrewer::brewer.pal(
        max(3, nrow(revenue)), "Set2")[1:nrow(revenue)])
    ) %>%
      layout(
        showlegend = FALSE,
        margin = list(l = 0, r = 0, t = 10, b = 0),
        paper_bgcolor = "white"
      )
  })
}

# ---------------- APP ----------------
shinyApp(ui = ui, server = server)