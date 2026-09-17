# Define server logic
server <- function(input, output, session){
  
  # Add this at the beginning of your app script
  if (Sys.getenv("R_CONFIG_ACTIVE") == "shinyapps" || identical(Sys.getenv("CONNECT_CLOUD"), "true") || TRUE) {
    options(chromote.args = c("--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"))
  }
  
  
  exp_ref <- reactiveVal(NULL)
  exp_current <- reactiveVal(NULL)
  spp_code <- reactiveVal(NULL)
  exp_bcr <- reactiveVal(NULL)
  report_version <- reactiveVal(FALSE)
  report_ready <- reactiveVal(FALSE)
  risk_area <- reactiveVal(NULL)
  ################################################################################################
  # RELOAD
  observeEvent(input$reload_btn, {
    showModal(
      modalDialog(
        title = "Confirm reload",
        tagList(
          p("You are about to reload the application."),
          p("Any unsaved work or pending downloads may be lost."),
          p("Do you want to reload the app?")
        ),
        footer = tagList(
          modalButton("No"),
          actionButton("confirm_reload", "Yes", class = "btn-danger")
        ),
        easyClose = FALSE
      )
    )
  })
  
  observeEvent(input$confirm_reload, {
    removeModal()
    session$reload()
  })
  
  # Get the pathway to Rmd file for the selected species account
  # spp_file <- reactive({paste0("Rmd/spp_accounts/text_spp_", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, ".md")}) 
  
  # Filter the exposure data to the selected species (bcr and osr), production field, and lease holder (osr) for the reference and current conditions
  observe({
    exp_bcr(bcr_exp |> 
      filter(spp_code == spp_tbl[spp_tbl$CommonName == input$spp, ]$speciesCode) |> 
      mutate(osr_pct = round(osr_pct*100, 2), osr_index = round(osr_index, 2))
    )
  })
  
  observeEvent(input$prod_field, {
    holders <- lease_osa_matrix |>
      dplyr::filter(osa == toupper(input$prod_field)) |>
      dplyr::pull(lease_holder) |>
      unique()
    
    updateSelectInput(session, "app_holder", choices = holders, selected = holders[1])
  })
  
  observeEvent(input$spp, {
    report_ready(FALSE)
  })
  
  # Create the reference exposure map for the BCR using the BAM map
  output$map <- renderLeaflet({
    r <- rast(paste0("www/bam_v5_4326/", spp_tbl[spp_tbl$CommonName == input$spp, ]$speciesCode, "_can61_2020.tif"))
    eb <- exp_bcr()
    labels_bcr6s <- sprintf(
      "<strong>BCR 6S pop: %s</strong><br/>OSR pop: %s<strong><br/>OSR pct: %s</strong><br/>OSR index: %s",
      eb$bcr_pop, eb$osr_pop, eb$osr_pct, eb$osr_index
    ) %>% lapply(htmltools::HTML)
    
    pal <- colorNumeric(palette = "Spectral", domain = values(r), na.color = "transparent")
    map <- leaflet() %>%
      addMapPane(name = "ground", zIndex=380) %>%
      addProviderTiles("Esri.WorldGrayCanvas", group="baseMap")|> 
      # Fit bounds to BCR 6S extent and add the osr area polygons
      fitBounds(lng1 = -116.0, lat1 = 50, lng2 = -105.0, lat2 = 58) |> 
      addRasterImage(r$mean, colors = "viridis", opacity = 0.8) |> 
      addPolygons(
        data = eb, 
        fillColor = NA, 
        fillOpacity = 0, 
        weight = 1, 
        color = "black", 
        label = ~labels_bcr6s
      ) |> 
      addPolygons(
        data = osr, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 2, 
        color = "red", 
        dashArray = "3", 
        highlightOptions = highlightOptions(weight = 5, color = "white", bringToFront = TRUE),
        label = ~Area_Name
      )
    
    if(!is.null(input$prod_field)){
      osr_selected <- osr |>
        dplyr::filter(Area_Name %in% input$prod_field)
      map <- map |>
        addPolygons(data = osr_selected,  fillColor = NA, fillOpacity = 0, weight = 4, color = "red", group = "selected_osr")
    }
    map
  })
  
  
  
  
  # Create the current exposure map for the OSR using the ABMI prediction map
  output$map_current <- renderLeaflet({
    rc <- rast(paste0("www/spp_pred_current/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_osr_current.tif"))
    pal <- colorNumeric(palette = "Spectral", domain = values(rc), na.color = "transparent")
    leaflet() %>%
      addMapPane(name = "ground", zIndex=380) %>%
      addProviderTiles("CartoDB.Positron", group="baseMap") %>%
      # Fit bounds to BCR 6S extent
      fitBounds(lng1 = -117.91614, lat1 = 53.54062, -110.00558, lat2 = 57.99188) |> 
      addRasterImage(rc$Species, colors = "viridis", opacity = 0.8) |> 
      addPolygons(
        data = osr, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 4, 
        color = "red", 
        dashArray = "3", 
        highlightOptions = highlightOptions(weight = 5, color = "white", bringToFront = TRUE),
        label = ~Area_Name
      )
  })
  
  
  # Create the updated OSR maps with selected species, production field, and lease holder
  observeEvent(input$co_prodField, {
    
    cop <- lease_exp_ref |> filter(osa == input$prod_field & lease_holder == input$app_holder)
    if(isTRUE(nrow(cop) == 0)){
      showModal(modalDialog(
        title = "The selected lease holders do not occur within the selected Oil Sands Area",
        "Prior to generating the data, you must confirm that the selected OSA contains leases belonging to the selected lease holder.",
        easyClose = TRUE,
        footer =  "Click anywhere on the screen to close this message.")
      )
    }
    req(isTRUE(nrow(cop) > 0))
    
    r1 <- rast(paste0("www/spp_pred_reference/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_osr_reference.tif"))
    rc <- rast(paste0("www/spp_pred_current/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_osr_current.tif"))
    pf <- osr |> filter(Area_Name == input$prod_field)
    
    exp_ref(lease_exp_ref |> filter(spp == spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID & osa == input$prod_field & lease_holder == input$app_holder) |> 
              mutate(common_name = input$spp))
    exp_current(lease_exp_current |> filter(spp == spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID & osa == input$prod_field & lease_holder == input$app_holder) |> 
                  mutate(common_name = input$spp))
    b <- st_bbox(osr)
    
    cf <- exp_ref()
    cf_pt <- st_centroid(st_make_valid(exp_ref()))
    cfc <- exp_current()
    cfc_pt <- st_centroid(st_make_valid(exp_current()))
    
    # Create the labels for the leases from the data files
    labels <- sprintf(
      "<strong>Lease holder: %s</strong><br/>Lease no: %s<strong><br/>Lease pop: %s</strong><br/>OSR pct: %s</strong><br/>OSR index: %s",
      cf_pt$lease_holder, cfc_pt$lease, cfc_pt$lease_pop, cfc_pt$lease_pct, cfc_pt$lease_index
    ) %>% lapply(htmltools::HTML)
    
    labels_current <- sprintf(
      "<strong>Lease holder: %s</strong><br/>Lease no: %s<strong><br/>Lease pop: %s</strong><br/>OSR pct: %s</strong><br/>OSR index: %s",
      cfc_pt$lease_holder, cf_pt$lease, cf_pt$lease_pop, cf_pt$lease_pct, cf$lease_index
    ) %>% lapply(htmltools::HTML)
    
    # Create the maps for the reference exposure
    leafletProxy("map") |> 
      clearMarkers() |> 
      clearShapes() |> 
      addMapPane(name = "ground", zIndex=380) |> 
      addProviderTiles("Esri.WorldGrayCanvas", group="baseMap") |> 
      fitBounds(lng1 = -117.91614, lat1 = 53.54062, -110.00558, lat2 = 57.99188) |> 
      addRasterImage(r1$Species, colors = "viridis", opacity = 0.8) |> 
      addPolygons(
        data = pf, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 4, 
        color = "red", 
        dashArray = "3"
      )  |> 
      addPolygons(
        data = cf, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 2, 
        color = "yellow", 
        dashArray = "3", 
        label = ~lease
      ) |> 
      addMarkers(
        data = cf_pt, 
        label = ~labels
      )
    
    # Create the maps for the current exposure
    leafletProxy("map_current") |> 
      clearMarkers() |> 
      clearShapes() |> 
      addMapPane(name = "ground", zIndex=380) |> 
      addProviderTiles("Esri.WorldGrayCanvas", group="baseMap") |> 
      fitBounds(lng1 = -117.91614, lat1 = 53.54062, -110.00558, lat2 = 57.99188) |> 
      addRasterImage(r1$Species, colors = "viridis", opacity = 0.8) |> 
      addPolygons(
        data = pf, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 4, 
        color = "red", 
        dashArray = "3"
      )  |> 
      addPolygons(
        data = cfc, 
        fillColor = NA, 
        fillOpacity = 0,
        weight = 2, 
        color = "yellow", 
        dashArray = "3", 
        label = ~lease
      ) |> 
      addMarkers(
        data = cfc_pt, 
        label = ~labels_current
      )
  })
  
  
  observeEvent(input$render_report, {
    
    if(isTRUE(input$co_prodField == 0)){
      showModal(modalDialog(
        title = "Please confirm selected AOI and lease",
        "Prior to generating the report, you must confirm selected AOI and leases.",
        easyClose = TRUE,
        footer = NULL)
      )
    }
    req(isTRUE(input$co_prodField > 0))
    
    showNotification("Processing data for your report...", type = "message")
    
    # Get rasters and datasets for report (exp_ref and r1 are repeated from above)
    r1 <- rast(paste0("www/spp_pred_reference/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_osr_reference.tif"))
    r2 <- rast(paste0("www/exposure_maps/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_grid_exposure.tif"))
    dat <- reactive({
      vulnerability_table |> filter(SpeciesID == spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID)
    })
    sector_sensitivity <- reactive({sector_eff |> filter(Common_Name == input$spp)})
    linear_sensitivity <- reactive({linear_eff |> filter(Common_Name == input$spp)})
    vuln_dat <- reactive({vulnerability_data |> filter(CommonName == input$spp)})
    
    params <- list(
      bird = input$spp,
      SpeciesID = spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID,
      osa = input$prod_field,
      lease_holder = input$app_holder,
      reference_rast = r1,
      exposure_rast = r2,
      current_sf = exp_current(),
      reference_sf = exp_ref(),
      production_field = osr |> filter(Area_Name == input$prod_field), 
      sector_sens = sector_sensitivity(), 
      linear_sens = linear_sensitivity(),
      vuln_data = vuln_dat()
    )
    
    rmarkdown::render(
      input = "www/vulnerability_report.Rmd",
      output_format = "html_document",
      output_file = "vulnerability.html",
      output_dir = "www",
      params = params,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
    report_ready(TRUE)
    report_version(report_version() + 1)
  })
  
  
  output$vulnerability_report <- renderUI({
    
    req(report_ready())
    
    tags$iframe(
      src = paste0(
        "vulnerability.html?v=",
        report_version()
      ),
      width = "100%",
      height = "1000px",
      frameborder = 0
    )
  })
  
  observeEvent(input$spp_lease, {
    showNotification("Processing data for your report...", type = "message")
    
    spp_code(vulnerability_table$SpeciesID[which(vulnerability_table$CommonName == input$risk_spp)]) 
    risk_results <- risk_results_list[which(names(risk_results_list) == spp_code())][[1]] 
    osr_risk <- osr_risk_data[which(names(osr_risk_data) == spp_code())][[1]]
    risk_area(input$lease_name) 
    
    if(risk_area() == "Full OSR"){
      risk_stats <- osr_risk
    }else if(risk_area() == "All leases"){
      risk_stats <- risk_results |> 
        group_by(scenario, iter) |> 
        summarise(pop_size = sum(pop_size))
    }else{
      risk_stats <- risk_results |> 
        filter(lease_name == risk_area())
    }
    
    output$dens_plot <- renderPlot({
      ggplot(data = risk_stats) + geom_density(aes(x = pop_size/1e6, fill = scenario), alpha = 0.4) + 
        theme_classic() + 
        scale_fill_manual(values = cbbPalette[1:4], name = "Scenario", labels = c("Baseline, non-OS", "Baseline, OS", "Climate change, non-OS", "Climate change, OS")) + 
        xlab("\nPopulation size (millions)") + ylab("Probability density\n") + theme(axis.title.x = element_text(size = 20), axis.title.y = element_text(size = 20), 
                                                                                     axis.text = element_text(size = 15), legend.text = element_text(size = 15), 
                                                                                     legend.title = element_text(size = 20), 
                                                                                     plot.title = element_text(size = 20)) + 
        ggtitle("Density distributions of future population size estimates under uncertainty.")
    })
    
    dectab <- do.call(cbind, lapply(2:length(scenario_names), function(i){
      sapply(1:length(decline_list), function(j){
        pctDecline_fxn_sim(spp = risk_stats, baseline_scenario = scenario_names[1], comp_scenario = scenario_names[i], prop_decline = decline_list[j], num.sim = 1000)
      })
    }))
    
    output$decline_plot <- renderPlot({
      d <- dectab
      colnames(d) <- scenario_names[2:4] 
      
      decline <- data.frame(decline = decline_list*100, d)
      spp_decline <- decline %>% 
        gather(scenario, response, baseline_OS:climate_OS, factor_key = TRUE)
      
      ggplot(data = spp_decline, aes(x = decline, y = response, group = scenario)) + 
        geom_line(aes(colour = scenario), linewidth = 1) + 
        scale_colour_manual(values = cbbPalette[2:4], name = "Comparison \nscenario", labels = c("Baseline, OS", "Climate change", "Climate change, OS")) + 
        theme_classic() + xlab("% Population loss relative to historic \nclimate with no Oil Sands development") + ylab("Probability\n") + 
        theme(axis.title.x = element_text(size = 20), axis.title.y = element_text(size = 20), 
              axis.text = element_text(size = 15), legend.text = element_text(size = 15), 
              legend.title = element_text(size = 20)) + ylim(c(0, 1))
    }) 
    
  })
  
  output$download_data_ui <- renderUI({
    req(report_ready())
    downloadButton("dwd_data", "Download data", style="margin-top: 20px;  width: 250px;")
  })
  
  output$dwd_data <- downloadHandler(
    filename = function() {
      paste0("vulnerability-", input$spp, "-", input$prod_field, "-", input$app_holder, "-", Sys.Date(), ".zip")
    },
    
    content = function(file) {
      
      showModal(modalDialog("Preparing download...", footer = NULL))
      on.exit(removeModal(), add = TRUE)
      
      #set temp folder
      tmpdir <- tempfile("vulnerability_")
      dir.create(tmpdir)
      
      # write in temp
      reference_exposure <- exp_ref()
      current_exposure <- exp_current()
      st_write(reference_exposure, dsn = file.path(tmpdir, "reference_exposure_lease.shp"), driver = "ESRI Shapefile", delete_layer = TRUE, quiet = TRUE)
      st_write(current_exposure, dsn = file.path(tmpdir, "current_exposure_lease.shp"), driver = "ESRI Shapefile", delete_layer = TRUE, quiet = TRUE)
      
      r1 <- rast(paste0("www/spp_pred_reference/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_osr_reference.tif"))
      r2 <- rast(paste0("www/exposure_maps/", spp_tbl[spp_tbl$CommonName == input$spp, ]$SpeciesID, "_grid_exposure.tif"))
      writeRaster(r1, filename = file.path(tmpdir, "reference_sdm_osr.tif"))
      writeRaster(r2, filename = file.path(tmpdir, "exposure_osr.tif"))

      # Zip everything
      oldwd <- getwd()
      setwd(tmpdir)
      on.exit(setwd(oldwd), add = TRUE)
      
      # return the zip folder
      zip::zipr(zipfile = file, files = dir(tmpdir, full.names = FALSE))
    }
    
  )
  
  output$download_report_ui <- renderUI({
    req(report_ready())
    downloadButton("dwd_report", "Download report", style="margin-top: 20px;  width: 250px;")
  })
  
  output$dwd_report <- downloadHandler(
    filename = function() {
      paste0("Vulnerability_Assessment_", gsub(" ", "_", input$spp),".pdf")
    },
    contentType = "application/pdf",
    content = function(file) {
      req(isTRUE(report_ready()))
      html_file <- file.path("www", "vulnerability.html")
      
      # options( chromote.chrome_args = c( "--headless", "--no-sandbox", "--disable-dev-shm-usage" ) )
      webshot2::webshot(
        url = html_file,
        file = file,
        vwidth = 1200,
        vheight = 900
      )
    }
  )
}