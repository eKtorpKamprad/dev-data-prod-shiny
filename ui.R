#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyjs)

shinyUI(
    navbarPage("NYCflights13 Time Gained in Flight",
        tabPanel("Plots",
                 sidebarPanel(
                     uiOutput("originNamesControls"),
                     actionButton(inputId = "clear_all", label = "Clear All", icon = icon("check-square")),
                     actionButton(inputId = "select_all", label = "Select all", icon = icon("check-square-o")),
                     h3(" "),
                     sliderInput(inputId = "distance",
                                 label = "Flight distance (miles):",
                                 min = 0, max = 5000,
                                 value = c(0,5000), step = 100,
                                 sep = "", ticks = TRUE),
                     selectInput(inputId = "carriers",
                                 label = "Carriers:",
                                 choices = list(),
                                 multiple = TRUE)
                 ),
                 
                 # Show a plot of the generated distribution
                 mainPanel(
                     tabsetPanel(
                         tabPanel("By Carrier", fluidRow(HTML('<br/>'),
                                                         plotOutput("byCarrier"))),
                         tabPanel("By Destination Airport", fluidRow(HTML('<br/>'),
                                                                     plotOutput("byDestAirpot"))),
                         tabPanel("Data", fluidRow(HTML('<br/>'),
                                                   tags$head(tags$style("#dTable {white-space: nowrap;}")),
                                                   dataTableOutput('dTable'))),
                         useShinyjs(),
                         inlineCSS(list("table" = "font-size: 11px"))
                     )
                 )
        ),
        tabPanel("About",
                 mainPanel(
                     includeMarkdown("about.md")
                 )     
        )
    )
)
