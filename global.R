options(repos = c(CRAN = "https://cran.rstudio.com"))

#required_packages <- c("bslib", "leaflet", "markdown", "rmarkdown", "sf", "shiny", 
#                       "shinydashboard", "shinyjs", "terra", "tidyverse")


#invisible(lapply(required_packages, library, character.only = TRUE))
library(leaflet)
library(bslib)
library(markdown)
library(rmarkdown)
library(sf)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(terra)
library(tidyverse)
library(flextable)
library(officer)
library(ggplot2)
library(webshot2)


load("www/data/sysdata.rda")

osr <- st_transform(st_read("www/data/oil_sands_areas.shp"), crs = 4326)[-5, ]
bcr <- st_transform(st_read("www/data/BCR6S.shp"), crs = 4326)
load("www/data/bam_exposure_metrics.rda")
load("www/data/lease_current_exposure_metrics.rda")
load("www/data/lease_reference_exposure_metrics.rda")
load("www/data/osr_current_exposure_metrics.rda")
load("www/data/osr_reference_exposure_metrics.rda")
load("www/data/risk_results_list.rda")
load("www/data/osr_risk_data.rda")
load("www/data/vulnerability_data.rda")
vulnerability_table <- read.csv("www/vulnerability_data.csv")
bcr_exp <- st_transform(bam_exposure_metrics, crs = 4326)
sector_eff <- read.csv("www/data/all_forest_sectoreff.csv")
linear_eff <- read.csv("www/data/linear_coefficients_forest.csv")
#lease_exp_current <- st_transform(lease_exp_current, crs = 4326) |> 
#  mutate(osa = replace_values(osa, "ATHABASCA" ~ "Athabasca", "COLD LAKE" ~ "Cold Lake", "PEACE RIVER AREA 1" ~ "Peace River Area 1", "PEACE RIVER AREA 2" ~ "Peace River Area 2"))

lease_osa_matrix <- lease_exp_ref |>
  sf::st_drop_geometry() |>
  dplyr::distinct(osa, lease_holder)

lease_exp_current <- lease_exp_current |>
  st_transform(crs = 4326) |>
  mutate(
    osa = case_match(
      osa,
      "ATHABASCA" ~ "Athabasca",
      "COLD LAKE" ~ "Cold Lake",
      "PEACE RIVER AREA 1" ~ "Peace River Area 1",
      "PEACE RIVER AREA 2" ~ "Peace River Area 2",
      .default = osa
    )
  )
#lease_exp_ref <- st_transform(lease_exp_ref, crs = 4326) |> 
#  mutate(osa = replace_values(osa, "ATHABASCA" ~ "Athabasca", "COLD LAKE" ~ "Cold Lake", "PEACE RIVER AREA 1" ~ "Peace River Area 1", "PEACE RIVER AREA 2" ~ "Peace River Area 2"))
lease_exp_ref <- lease_exp_ref |>
  st_transform(crs = 4326) |>
  mutate(
    osa = case_match(
      osa,
      "ATHABASCA" ~ "Athabasca",
      "COLD LAKE" ~ "Cold Lake",
      "PEACE RIVER AREA 1" ~ "Peace River Area 1",
      "PEACE RIVER AREA 2" ~ "Peace River Area 2",
      .default = osa
    )
  )
lease_holders <- data.frame(lease_holder = levels(as.factor(lease_exp_ref$lease_holder)))
risk_leases <- data.frame(lease_name = levels(as.factor(risk_results_list[[1]]$lease_name)))
risk_species <- data.frame(CommonName = vulnerability_table$CommonName[which(vulnerability_table$SpeciesID %in% names(osr_risk_data))])

# Data and functions for quantitative risk assessment 
scenario_names <- c("baseline", "baseline_OS", "climate", "climate_OS")
cbbPalette <- c("#56B4E9", "#009E73", "#F0E442", "#D55E00", "#0072B2", "#CC79A7", "#000000", "#E69F00")
decline_list <- seq(0.01, 0.2, 0.01)

pctDecline_fxn_sim <- function(spp, baseline_scenario, comp_scenario, prop_decline, num.sim){
  baseline <- spp %>% filter(scenario == baseline_scenario) 
  comp <- spp %>% filter(scenario == comp_scenario) 
  
  risk <- mean(sapply(1:num.sim, function(x){
    b <- sample(baseline$pop_size, 1)
    c <- sample(comp$pop_size, 1)
    ifelse(c/b < (1 - prop_decline), 1, 0)
  }))
  
  return(risk)
}



