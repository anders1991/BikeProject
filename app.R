####################
### Bike project ###
####################

library(shiny)
library(shinydashboard)
library(googlesheets)
library(dplyr)
library(leaflet)
library(ggplot2)
library(scales)


# Load data from Google
bike <- gs_key("1lGbXMISTa2iBD5xEwufN6cj1BCoLpwTQazxouSBnM0s") # register googlesheet
data <- gs_read(bike, range="A1:S79") # load data from googlesheet; specific rows to avoid bug


# Format
data$time <- as.POSIXct(paste("1970-01-01", data$time), format="%Y-%m-%d %H:%M:%S", tz = "GMT")
data$date <- as.Date(data$date, format="%m/%d/%Y")
data$state <- as.factor(data$state)


shinyApp(
    ui <- dashboardPage(
        dashboardHeader(title="Cycling across America",
                        titleWidth=240),
        dashboardSidebar(
            sidebarMenu(
                dateRangeInput("cal",
                               label = "Select an interval of dates",
                               start = head(data$date, 1),
                               end = tail(data$date, 1),
                               min = head(data$date, 1),
                               max = tail(data$date, 1),
                               format = "dd/mm/yy",
                               weekstart = 1),
                menuItem("Map", tabName="map", icon=icon("globe")),
                menuItem("Charts", tabName="charts", icon=icon("area-chart")),
                menuItem("About", tabName="about", icon=icon("info"))
                )
        ),
        dashboardBody(
            tabItems(
                tabItem(tabName="map",
                        fluidRow(
                            box(width=12, 
                                leafletOutput("myMap", 
                                              width="100%", 
                                              height="500")
                            )
                        ),
                        fluidRow(
                            box(width=6, 
                                 title="Visualizing a long bicycle ride", 
                                 "In the summer of 2014, I bought a bicycle 
                                 and a flight ticket to Miami. Almost 7000 km 
                                 later, I rode across the Golden Gate Bridge 
                                 and over the steep hills of Lombard Street, 
                                 San Francisco.", 
                                 br(), br(), 
                                 "Every night along the way, when setting up 
                                 camp, I would mark down the numbers collected 
                                 on my bike computer during that day and estimate
                                 my position on the map.", 
                                 br(), br(), 
                                 "This is an initial, and very experimental 
                                 attempt at visualizing some of those numbers."),
                           box(width=6,
                               title="Navigating this website",
                               "The red dots in the map above indicate all the 
                               place places I've been staying for the night 
                               during the trip. You can click the points to see
                               the exact name of the place along with any brief 
                               notes for that day.",
                               br(), br(), 
                               "If you want to further explore some of the data 
                               connecting these points, the 'Charts'-tab on the 
                               sidebar to the left will allow you to do so. 
                               Finally, if you're more curious about this website 
                               or who I am, check out the 'About'-tab.",
                               br(), br(), 
                               "You can also 'zoom' in on a specific section of 
                               the trip by selecting a specific interval in the 
                               sidebar. It will adjust both the map and the charts.")
                           )
                        ),
                tabItem(tabName="charts",
                        tags$h2("Charts"),
                        selectInput(inputId="yvar", 
                                    label = "Choose a variable to plot",
                                    choices=c("Total distance" = "Total distance (km)",
                                              "Total altitude up" = "Total altitude up (km)",
                                              "Total altitude down" = "Total altitude down (km)",
                                              "Time" = "Time",
                                              "Distance" = "Distance (km)",
                                              "Average speed" = "Average speed (km/h)",
                                              "Top speed" = "Top speed (km/h)",
                                              "Altitude up" = "Altitude up (m)",
                                              "Altitude down" = "Altitude down (m)",
                                              "Average climb" = "Average climb (%)",
                                              "Average descent" = "Average descent (%)",
                                              "Max climb" = "Max climb (%)",
                                              "Max descent" = "Max descent (%)")
                                    ),
                        box(width=12, 
                            plotOutput(outputId = "dayplot", 
                                       width="100%",
                                       height="400")),
                        fluidRow(box(width = 12,
                                     title = "Variables",
                                     "- Total distance measures the aggregated daily
                                     distances since the start.",
                                     br(),
                                     "- Total altitude up and total altitude down 
                                     measures the aggregated vertical distance.",
                                     br(),
                                     "- Time indicates the amount of active hours on
                                     the bike (breaks are excluded).",
                                     br(),
                                     "- Distance indicates the daily distance travelled.",
                                     br(),
                                     "- Average speed measures the average daily speed.",
                                     br(),
                                     "- Top speed indicates the highest daily speed achieved.",
                                     br(),
                                     "- Altitude up and altitude down tracks the 
                                     daily vertical distance travelled.",
                                     br(),
                                     "- Average climb and average descent displays
                                     the average daily gradients up and down.",
                                     br(),
                                     "- Max climb and max descent indicates the highest
                                     daily gradients achieved (the last day is not a bug,
                                     but the result of crossing Lombard Street in 
                                     San Francisco!).",
                                     br(), br(),
                                     "Also note that some days may appear missing.
                                     This is either due to restdays or exploration
                                     off the bike."))
                        ),
                tabItem(tabName="about",
                        fluidRow(
                            box(width=6, 
                                title="About me", 
                                "My name is Anders, and when I'm not riding a bicycle
                                around the world, I'm a political science student
                                at Aarhus University, Denmark.",
                                br(), br(),
                                "Lately, I've been very engaged in the world of 
                                data science and learning R. In fact, this website
                                is part of my course project for the 
                                'Data Products'-class in the Data Science
                                Specialization offered by Johns Hopkins University 
                                through Coursera.",
                                br(), br(),
                                "My intention is to gradually expand on this basic website
                                framework, so it may be used as a statistical platform 
                                for my future bicycle trips."
                                ),
                            box(width=6,
                                title="About this website",
                                "This entire web app was built with the statistical
                                programming software R using Shiny. The data is 
                                loaded directly from a Google spreadsheet, which 
                                can be filled in even without internet access.",
                                br(), br(),
                                "The driving idea behind this is that I
                                - during future trips - can just type
                                the daily data into a Google spreadsheet on my iPad, 
                                and have it automatically update the website 
                                with the more current information, whenever 
                                the iPad next gains access to the internet.")
                            )
                        )
                )
            )
    ),

    
    
    server <- function(input, output) {
        
        mydata <- reactive({
            caldates <- seq(input$cal[1], input$cal[2], by="day")  # user-selected dates
            caldata <- filter(data, date %in% caldates)  # user-selected data
        })
            
        myplotdata <- reactive({
             if (input$yvar == "Time") {
                 plotdata <- data.frame(day = mydata()$day, var = mydata()$time, State=mydata()$state)
             } else if (input$yvar == "Distance (km)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$distance, State=mydata()$state)
            } else if (input$yvar == "Average speed (km/h)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$avg_speed, State=mydata()$state)
            } else if (input$yvar == "Top speed (km/h)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$top_speed, State=mydata()$state)
            } else if (input$yvar == "Altitude up (m)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$alt_up, State=mydata()$state)
            } else if (input$yvar == "Altitude down (m)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$alt_down, State=mydata()$state)
            } else if (input$yvar == "Average climb (%)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$avg_climb, State=mydata()$state)
            } else if (input$yvar == "Average descent (%)") {
                plotdata <- data.frame(day = mydata()$day, var = abs(mydata()$avg_descent), State=mydata()$state)
            } else if (input$yvar == "Max climb (%)") {
                plotdata <- data.frame(day = mydata()$day, var = mydata()$max_climb, State=mydata()$state)
            } else if (input$yvar == "Max descent (%)") {
                plotdata <- data.frame(day = mydata()$day, var = abs(mydata()$max_descent), State=mydata()$state)
            } else if (input$yvar == "Total distance (km)") {
                plotdata <- data.frame(day = mydata()$day, var = cumsum(ifelse(is.na(mydata()$distance), 0, mydata()$distance)), State=mydata()$state)
            } else if (input$yvar == "Total altitude up (km)") {
                plotdata <- data.frame(day = mydata()$day, var = cumsum(ifelse(is.na(mydata()$alt_up), 0, mydata()$alt_up/1000)), State=mydata()$state)
            } else if (input$yvar == "Total altitude down (km)") {
                plotdata <- data.frame(day = mydata()$day, var = cumsum(ifelse(is.na(mydata()$alt_down), 0, mydata()$alt_down/1000)), State=mydata()$state)
            }
        })
        
        mygeodata <- reactive({
            geodata <- subset(mydata(), complete.cases(mydata()[,18:19]))
            geodata$popup <- ifelse(is.na(geodata$description)==TRUE, 
                                    yes=paste0("Day", " ", geodata$day, " ", "(", geodata$date, ")", "<br>",
                                               geodata$place, ", ", geodata$state), 
                                    no=paste0("Day", " ", geodata$day, " ", "(", geodata$date, ")", "<br>",
                                              geodata$place, ", ", geodata$state, "<br>",
                                              geodata$description))
            return(geodata)
        })
        
        
        map <- leaflet() %>% 
            addProviderTiles("Thunderforest.Outdoors",
                             options=providerTileOptions(noWrap=TRUE)) %>% 
            setView(lng = "-98",
                    lat = "36",
                    zoom = 4)

        observe({
            leafletProxy("myMap") %>% 
                clearMarkers() %>% 
                addCircleMarkers(lng = mygeodata()$longitude,
                                 lat = mygeodata()$latitude,
                                 radius=2,
                                 color="red",
                                 opacity=1,
                                 popup = mygeodata()$popup)
        })
        
        output$myMap <- renderLeaflet(map)
        
        output$dayplot <- renderPlot({
            if (input$yvar == "Time") {
                p <- ggplot(myplotdata(), aes(day, var, fill=State, color=State)) +
                    geom_bar(stat="identity") +
                    xlab("Day") +
                    ylab(input$yvar) +
                    scale_x_continuous(breaks=pretty_breaks(10)) +
                    scale_y_datetime(breaks = date_breaks("1 hour"),
                                     labels = date_format("%H:%M")) +
                    scale_fill_brewer(palette="Paired", type="qual") +
                    scale_color_brewer(palette="Paired", type="qual")
                print(p)
            } else {
            p <- ggplot(myplotdata(), aes(day, var, fill=State, color=State)) +
                geom_bar(stat="identity") +
                xlab("Day") +
                ylab(input$yvar) +
                scale_x_continuous(breaks=pretty_breaks(10)) +
                scale_y_continuous(breaks=pretty_breaks(10)) +
                scale_fill_brewer(palette="Paired", type="qual") +
                scale_color_brewer(palette="Paired", type="qual")
            print(p)
            }
        })
    }
)



