tagList(
  navbarPage(
    theme = bslib::bs_theme(version = 5, bootswatch = "lux"),
    id = 'tabs',
    collapsible = TRUE,
    
    # Describes the top header bar with tabs
    header = tagList(
      tags$head(tags$link(href = "css/style_blank_II.css", rel = "stylesheet"),
                tags$style(HTML(".navbar-nav {margin-left: 40px;}"))
      ), 
      tags$div(
        style = "position: absolute; right: 20px; top: 10px;",
        actionButton(
          "reload_btn",
          label = "Reload",
          icon = icon("refresh"),
          style = "color: white; background-color: rgb(30, 80, 85); border: none; font-size: 16px; margin-top: 8px;"
        ),
        style = "position: absolute; right: 20px; top: 10px;" # adjust position
      )
    ),
    title = HTML('<div style="margin-top: 0px;"><a href="https://github.com/alberta-conservation" target="_blank"><img src="abc-program-logo.png" height="80px"></a></div>'),
    windowTitle = "OSR Biodiversity Assessment tool",
    tabPanel("Welcome", value = 'intro'),
    tabPanel("Vulnerability assessment", value = 'vulnerability'),
    tabPanel("Risk Assessment", value = 'risk'),
    tabPanel("Recommendations", value = 'recommendations'), 
    navbarMenu("Species of Special Concern", 
               tabPanel("Overview", value = "soc"), 
               tabPanel("Pileated Woodpecker", value = "piwo"), 
               tabPanel("Yellow Rail", value = "yera"), 
#                tabPanel("Rusty Blackbird", value = "rubl"), 
#                tabPanel("Canadian Toad", value = "cato"), 
#                tabPanel("Sharp-tailed Grouse", value = "stgr"), 
               tabPanel("Whooping Crane", value = "whcr"), 
    )
  ),
  
  tags$div(
    
    useShinyjs(),
    
    conditionalPanel(
      condition="input.tabs == 'intro'",
      div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
          tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
      fluidRow(
        column(2, layout_sidebar(
          sidebar = sidebar(
            position = "left"
          )
        )),
        
        column(10, div(id = "markdown-content", includeMarkdown("Rmd/text_intro_tab.md")))
      )
    ), 
  
  
  # Layout for vulnerability and risk tabs
  conditionalPanel(
    condition = "input.tabs == 'vulnerability' || input.tabs == 'risk'", 
    fluidRow(
      column(3, 
             conditionalPanel(
               condition = "input.tabs == 'vulnerability'", 
               tabsetPanel(
                 tabPanel("Tool", 
                          selectInput(
                            inputId = "spp", 
                            label = "Select a species", 
                            choices = spp_tbl$CommonName, 
                            selected = "Black-throated Green Warbler"),
                          checkboxGroupInput(
                            inputId = "prod_field",
                            label = "Choose the Oil Sands Area:",
                            choices = c("Athabasca", "Cold Lake", "Peace River Area 1", "Peace River Area 2"),
                            selected = "Athabasca" # Optional: pre-select an item
                          ), 
                          selectInput(
                            inputId = "app_holder", 
                            label = "Select a lease holder:", 
                            choices = lease_holders$lease_holder, 
                            selected = "Suncor Energy Inc."
                          ), 
                          div(actionButton(inputId = "co_prodField", 
                                       label = "Show selected AOI and leases", 
                                       icon = icon(name = "fas fa-crow", lib = "font-awesome"), 
                                       style="width:200px;"
                          )), 
                          div(actionButton(inputId = "render_report", 
                                       label = "Create report", 
                                       style="margin-top: 20px; width: 200px;"
                          ))
                 ), 
                 tabPanel("Instructions", 
                          icon = icon("circle-info"), 
                          div(style = "color: white !important; font-size: 14px; font-family: 'Cormorant Garamond', serif;", 
                              includeMarkdown("./Rmd/gtext_exposure.Rmd")
                          )
                 )
               )
             ), 
             conditionalPanel(
               condition = "input.tabs == 'risk'", 
               tabsetPanel(
                 tabPanel("Tool",  
                          selectInput(
                            inputId = "risk_spp", 
                            label = "Select a species", 
                            choices = risk_species$CommonName, 
                            selected = "Ovenbird"),
                          selectInput(
                            inputId = "lease_name", 
                            label = "Select area for assessment:", 
                            choices = c("Full OSR", "All leases", risk_leases$lease_name), 
                            selected = "Suncor Energy Inc."
                          ), 
                          div(actionButton(inputId = "spp_lease", 
                                       label = "Show selected species and area", 
                                       icon = icon(name = "fas fa-crow", lib = "font-awesome"), 
                                       style="width:200px")), 
                          
                          div(actionButton(inputId = "render_risk_report", 
                                       label = "Create report", 
                                       style="margin-top: 20px; width: 200px;"
                          ))
                 ), 
                 tabPanel("Instructions", 
                          icon = icon("circle-info"), 
                          div(style = "color: white !important; font-size: 14px; font-family: 'Cormorant Garamond', serif;", 
                              includeMarkdown("./Rmd/gtext_risk.Rmd")
                          )
                 )
               )
             )
      ), 
      column(6, 
             conditionalPanel(
               condition = "input.tabs == 'vulnerability'", 
               tabsetPanel(id ="centerPanel",
                           tabPanel("Reference Exposure", 
                                    leafletOutput(outputId = "map", width = "100%", height = "400px"),
                                    br(),
                                    hr(),
                                    br(),
                                    uiOutput("vulnerability_report")
                           ),
                           tabPanel("Current Exposure",
                                    leafletOutput(outputId = "map_current", width = "100%", height = "400px")
                           ) 
               )
             ), 
             conditionalPanel(
               condition = "input.tabs == 'risk'", 
               tabsetPanel(
                 tabPanel("Density distributions", 
                          plotOutput("dens_plot")
                 ),
                 tabPanel("Risk estimates",
                          plotOutput("decline_plot")
                 )
               )
             )
      ), 
      column(3, 
             conditionalPanel(
               condition = "input.tabs == 'vulnerability'",
               div(id = "markdown-content", includeMarkdown("Rmd/data_download_tab.md")),
               uiOutput("download_data_ui"), 
               uiOutput("download_report_ui")
             ), 
             conditionalPanel(
               condition = "input.tabs == 'risk'",
               div(id = "markdown-content", includeMarkdown("Rmd/risk_download_tab.md")), 
               actionButton(inputId = "dwnld_dta", label = "Download Data", icon = icon(name = "fas fa-crow", lib = "font-awesome"), style="width:250px"), 
               
               downloadButton("dwnld_report", "Download report", style="margin-top: 20px;  width: 250px;")
             )
      ), 
      column(12,  
             conditionalPanel(
               condition = "input.tabs == 'vulnerability'", 
               
             ) # conditionalPanel(
      ) # column(12,
    )
  )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'recommendations'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/text_recommendations_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'soc'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_soc_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'piwo'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_piwo_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'yera'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_yera_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'rubl'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_rubl_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'cato'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_cato_temp_tab.md")))
    )
  ), 
  
  conditionalPanel(
    condition="input.tabs == 'stgr'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_stgr_temp_tab.md")))
    )
  ), 
  conditionalPanel(
    condition="input.tabs == 'whcr'",
    div(style = "background-color: white; width: 100vw; margin: 0; padding: 0; display: flex; justify-content: center;",
        tags$img(src = "osr.png", height = "300px",  style = "display: block; object-fit: contain; width: 100%; max-width: none;")),
    
    fluidRow(
      column(2, layout_sidebar(
        sidebar = sidebar(
          position = "left"
        )
      )),
      
      column(10, div(id = "markdown-content", includeMarkdown("Rmd/soc/text_whcr_temp_tab.md")))
    )
  ), 
  
  tags$head(
    tags$style(HTML("
    #shiny-notification-panel {
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      bottom: unset;
      right: unset;
      position: fixed;
    }
  "))
  )
  
)



