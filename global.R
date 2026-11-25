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

load("www/data/sysdata.rda")

# Spatial objects pre-projected to EPSG:4326 (and osa recoded) by prep_spatial_data.R
osr <- readRDS("www/data/osr_4326.rds")
bcr <- readRDS("www/data/bcr_4326.rds")
bcr_exp <- readRDS("www/data/bcr_exp_4326.rds")
lease_exp_current <- readRDS("www/data/lease_exp_current_4326.rds")
lease_exp_ref <- readRDS("www/data/lease_exp_ref_4326.rds")
lease_osa_matrix <- readRDS("www/data/lease_osa_matrix.rds")

load("www/data/osr_current_exposure_metrics.rda")
load("www/data/osr_reference_exposure_metrics.rda")
load("www/data/risk_results_list_36.rda")
load("www/data/osr_risk_data_36.rda")
load("www/data/vulnerability_data.rda")
load("www/data/vulnerability_data_lease.rda")
load("www/data/total_risk_lease_36.rda")
load("www/data/total_risk_osr_36.rda")
load("www/data/total_risk_lease_area_36.rda")
vulnerability_table <- read.csv("www/vulnerability_data.csv")
sector_eff <- read.csv("www/data/all_forest_sectoreff.csv")
linear_eff <- read.csv("www/data/linear_coefficients_forest.csv")
final_abmi_spp_list <- read.csv("www/data/final_abmi_spp_list.csv")


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