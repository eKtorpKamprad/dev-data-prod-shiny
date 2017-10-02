#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(nycflights13)
library(dplyr)
library(ggplot2)
library(gridExtra)

flt_df <- as.data.frame(nycflights13::flights)
apt_df <- as.data.frame(nycflights13::airports)
aln_df <- as.data.frame(nycflights13::airlines)
colnames(apt_df) <- paste("origin", colnames(apt_df), sep = "_")
tmp_df <- flt_df %>%
    inner_join(apt_df[,c(1:5)], by=c("origin" = "origin_faa")) 
colnames(apt_df) <- gsub("origin", "dest", colnames(apt_df))
tmp_df <- tmp_df %>%
    inner_join(apt_df[,c(1:5)], by=c("dest" = "dest_faa"))
tmp_df <- tmp_df %>%
    inner_join(aln_df) %>% rename(carrier_name = name)
origin_name <- as.character(sort(unique(tmp_df$origin_name)))
carriers    <- as.character(sort(unique(tmp_df$carrier_name)))
carriers    <- c("Clear All","Select All",carriers)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    
    updateSelectInput(session, "carriers", choices = carriers, selected = "Select All")
    observe({
        if ("Select All" %in% input$carriers) {
            # choose all the carriers _except_ "Select All" & "Clear All"
            selected_carriers  <- setdiff(carriers, c("Select All","Clear All"))
            selectable_choices <- setdiff(carriers,c("Select All"))
            updateSelectInput(session, "carriers",  
                              choices = selectable_choices, selected = selected_carriers)
        }else if ("Clear All" %in% input$carriers) {
            # remove all carriers from selected
            selected_carriers  <- c("")
            selectable_choices <- setdiff(carriers,"Clear All")
            updateSelectInput(session, "carriers", 
                              choices = selectable_choices, selected = selected_carriers)
        }else if (length(input$carriers) == 1){
            # As long as there is one option selected, include the "Clear All" option in Choices
            selected_carriers  <- input$carriers
            selectable_choices <- carriers
            updateSelectInput(session, "carriers", 
                              choices = selectable_choices, selected = selected_carriers)
        }
    })
    
    # Define and initialize reactive values
    values <- reactiveValues()
    values$origin_name <- origin_name
    
    # Create event type checkbox
    output$originNamesControls <- renderUI({
        checkboxGroupInput('origin_name', 'NYC departure airports:', origin_name, selected=values$origin_name)
    })
    
    # Add observers on clear and select all buttons
    observe({
        if(input$clear_all == 0) return()
        values$origin_name <- c()
    })
    
    observe({
        if(input$select_all == 0) return()
        values$origin_name <- origin_name
    })
    
    # Create plot data
    plot_data <- reactive({
        filter(tmp_df, 
               origin_name == input$origin_name,
               distance >= input$distance[1], distance <= input$distance[2],
               carrier_name == input$carriers) %>%
        mutate(gain = dep_delay - arr_delay) %>%    
        select(origin_name, dest_name, distance, carrier_name, dep_delay, arr_delay, gain)
    })
    
    plot_byCarrier <- reactive({
        plot_data() %>%
        group_by(carrier_name) %>%
        summarize(avg_gain = mean(gain, na.rm=TRUE), flights = n())
    })  
    
    plot_byDestAirpot <- reactive({
        plot_data() %>%
        group_by(dest_name) %>%
        summarize(avg_gain = mean(gain, na.rm=TRUE), flights = n())
    })
    
    output$byCarrier <- renderPlot({
        ggplot(plot_byCarrier(), aes(reorder(factor(carrier_name),avg_gain), avg_gain)) +
            geom_bar(stat = "identity", fill = '#428bca') + coord_flip() +
            labs(x = "Carrier", y = "Time Gained (in minutes)") 
    })
    
    output$byDestAirpot <- renderPlot({
        p1 <- ggplot(plot_byDestAirpot() %>% top_n(10, avg_gain), 
                aes(reorder(factor(dest_name),avg_gain), avg_gain)) +
                geom_bar(stat = "identity", fill = '#428bca') + coord_flip() +
                labs(x = "Destination Airpot", y = "Time Gained (in minutes)") +
                labs(title = "Top-10 Destination Airports") 
        
        p2 <- ggplot(plot_byDestAirpot() %>% top_n(10, -avg_gain), 
                aes(reorder(factor(dest_name),-avg_gain), avg_gain)) +
                geom_bar(stat = "identity", fill = '#428bca') + coord_flip() +
                labs(x = "Destination Airpot", y = "Time Gained (in minutes)") +
                labs(title = "Worst-10 Destination Airports") 
        
        grid.arrange(p1,p2, ncol=2)
    })
    
    # Preapre datasets
    flightsR <- reactive({
        filter(tmp_df, 
               #origin_name == input$depAirport, 
               origin_name == input$origin_name,
               distance >= input$distance[1], distance <= input$distance[2],
               carrier_name == input$carriers)
    })
    
    output$dTable <- renderDataTable(plot_data() %>%
                                         select(origin = origin_name, destination = dest_name,
                                                distance, carrier = carrier_name, dep_delay, arr_delay, 
                                                gain),
                                     options = list(lengthMenu = c(5,10), pageLength = 10,  escape = FALSE))
})
