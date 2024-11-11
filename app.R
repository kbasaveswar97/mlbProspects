library(shiny)
library(dplyr)
library(DT) 
library(ggplot2)
library(lubridate)
library(viridis)
library(grid)  # Load the grid package
library(png)
library(readxl)
library(shinydashboard)
library(reshape2)
library(tidyverse)
library(gridExtra) 


data <- read_excel("data.xlsx")

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-image: url('i1.jpg'); /* Add your image path here */
        background-size: cover; /* Cover the entire page */
        background-attachment: fixed; /* Fix the background image */
      }
      .shiny-text-output {
        white-space: pre-wrap; /* CSS property to make text wrap */
      }
      .footer {
        margin-top: 20px;
        padding: 10px 0;
        color: #555;
        text-align: center;
        border-top: 1px solid #ddd;
        font-size: 0.8em;
      }
    "))
  ),
    fluidRow(
      wellPanel(
        h3("MLB Prospects: Comparative Analysis Tool (2014-2020)"), # Center the title
        div(class = "select-with-image", style = "display: flex; align-items: center; justify-content: start;",
            div(
              selectInput("category", "Category:", choices = unique(data$Category)),
              style = "width: 700px; margin-right: 20px;"  
            ),
            div(
              img(src = "t1.png", style = "max-height: 100px; object-fit: cover; flex-grow: 1;"), # Object-fit cover for proper scaling
              style = "flex: 1; display: flex; justify-content: flex-end; width: auto; min-width: 150px; overflow: hidden;"  # Flex grow to take remaining space
            )
        )
      ),
    column(6,
           wellPanel(
             selectInput("position1", "Position", choices = NULL),
             selectInput("player1", "Player", choices = NULL),
             selectInput("year1", "Year", choices = NULL)
           ),
           wellPanel(
             h4("Stats and Insights"),
             verbatimTextOutput("player1_info")
           ),
           plotOutput("player1_plot")  # Ensure plotOutput for Player 1 is here
    ),
    column(6,
           wellPanel(
             selectInput("position2", "Position", choices = NULL),
             selectInput("player2", "Player", choices = NULL),
             selectInput("year2", "Year", choices = NULL)
           ),
           wellPanel(
             h4("Stats and Insights"),
             verbatimTextOutput("player2_info")
           ),
           plotOutput("player2_plot")  # Ensure plotOutput for Player 2 is here
    )
  ),
  # Footer
  tags$div(
    class = "footer",
    HTML("Data source: MLB.com via Chris Russo<br/>by Eshwar Konda"),
    style = "color: white; text-align: left; font-size: larger;"
  )
)



server <- function(input, output, session) {
  
  # Reactively update position dropdowns based on the category selection
  observe({
    # Get unique positions for the selected category
    unique_positions <- unique(data$Pos[data$Category == input$category])
    updateSelectInput(session, "position1", choices = unique_positions)
    updateSelectInput(session, "position2", choices = unique_positions)
  })
  
  # Update player dropdowns based on selected position from respective dropdown
  observe({
    updateSelectInput(session, "player1", choices = unique(data$Name[data$Pos == input$position1]))
  })
  
  observe({
    updateSelectInput(session, "player2", choices = unique(data$Name[data$Pos == input$position2]))
  })
  
  # Update year dropdowns based on selected position and player from respective dropdowns
  observe({
    updateSelectInput(session, "year1", choices = unique(data$Year[data$Pos == input$position1 & data$Name == input$player1]))
  })
  
  observe({
    updateSelectInput(session, "year2", choices = unique(data$Year[data$Pos == input$position2 & data$Name == input$player2]))
  })
  
  # Ordered attributes
  attributes  <- c("Hit", "Power", "Run", "Arm", "Field", "Fastball", "Curveball", 
                          "Slider", "Changeup", "Cutter", "Splitter", "Screwball", 
                          "Knuckleball", "Palmball", "Control", "Overall_B", "Overall_P")
  
  # Custom color palette
  attribute_colors <- c("Hit" = "forestgreen", "Power" = "goldenrod1", "Run" = "#1f77b4", 
                        "Arm" = "salmon", "Field" = "springgreen1", "Fastball" = "tomato1", 
                        "Curveball" = "peru", "Slider" = "powderblue", "Changeup" = "slategray4", 
                        "Cutter" = "rosybrown", "Splitter" = "slateblue1", "Screwball" = "lightsteelblue3", 
                        "Knuckleball" = "lightseagreen", "Palmball" = "tan3", 
                        "Control" = "darkseagreen1", "Overall_B" = "royalblue4", "Overall_P" = "red3")
  
  
  
  # Reactive expression to fetch and store info for Player 1
  player1_info <- reactive({
    req(input$player1, input$year1)
    selected_data <- data %>%
      filter(Name == input$player1, Year == input$year1) %>%
      select(-Name, -Year) %>%
      t() %>%
      as.data.frame() %>%
      na.omit()
    selected_data
  })
  
  # Reactive expression to fetch and store info for Player 2
  player2_info <- reactive({
    req(input$player2, input$year2)
    selected_data <- data %>%
      filter(Name == input$player2, Year == input$year2) %>%
      select(-Name, -Year) %>%
      t() %>%
      as.data.frame() %>%
      na.omit()
    selected_data
  })
  
  # Display all available information for Player 1, excluding NA values
  output$player1_info <- renderText({
    info_data <- player1_info()  # Get the reactive value for player 1
    names <- rownames(info_data)
    values <- info_data$V1
    info_text <- paste(names, ":", values)
    paste(info_text, collapse = "\n")
  })
  
  # Similar logic for Player 2, excluding NA values
  output$player2_info <- renderText({
    info_data <- player2_info()  # Get the reactive value for player 2
    names <- rownames(info_data)
    values <- info_data$V1
    info_text <- paste(names, ":", values)
    paste(info_text, collapse = "\n")
  })
  
  
##########################
  # Render plot for Player 1
  output$player1_plot <- renderPlot({
    req(player1_info())  # Ensure data for Player 1 is available
    
    # Convert row names to a column and then filter out unwanted stats
    player1_data <- player1_info() %>%
      tibble::rownames_to_column(var = "Stat") %>%
      filter(!Stat %in% c("Team", "Id", "Pos", "DOB", "Text", "Category")) 

    ggplot(player1_data, aes(x = factor(Stat, levels = attributes), y = V1, fill = factor(Stat, levels = attributes))) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = attribute_colors) +  # Use predefined color scheme
      theme_minimal() +
      labs(title = paste("Attributes of", input$player1), 
           x = "",  
           y = "Value") +
      theme(
      legend.position = "none")
  })
  
  # Render plot for Player 2
  output$player2_plot <- renderPlot({
    req(player2_info())  # Ensure data for Player 2 is available
    
    # Convert row names to a column and then filter out unwanted stats
    player2_data <- player2_info() %>%
      tibble::rownames_to_column(var = "Stat") %>%
      filter(!Stat %in% c("Team", "Id", "Pos", "DOB", "Text", "Category")) 
    

    # Plot code for Player 2
    ggplot(player2_data, aes(x = factor(Stat, levels = attributes), y = V1, fill = factor(Stat, levels = attributes))) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = attribute_colors) +  # Use predefined color scheme
      theme_minimal() +
      labs(title = paste("Attributes of", input$player2), 
           x = "",  # If you want to remove the x-axis label
           y = "Value") +
      theme(
    legend.position = "none")
  })
  

}
shinyApp(ui = ui, server = server)