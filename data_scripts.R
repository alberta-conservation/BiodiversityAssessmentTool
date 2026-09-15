
library(sf)
library(terra)
library(tidyverse)


# Add the species table to the sysdata.R file 
spp_tbl <- read.csv("www/data/final_abmi_spp_list.csv")

save(spp_tbl, file = "www/data/sysdata.rda")

# Create the version.url table and add it to the sysdata.R file 
version.url <- data.frame(
  version = c("bam", "reference", "current"), 
  url = c("http://206.12.92.143/data/bam", 
          "http://206.12.92.143/data/abmiReference", 
          "http://206.12.92.143/data/abmiCurrent")
)

abmi_spp_info <- read.csv("www/data/abmi_spp_info.csv")

# Create a new environment to load the sysdata and combine the files, then save
e <- new.env()
e$version.url <- version.url
e$abmi_spp_info <- abmi_spp_info
load("www/data/sysdata.rda", envir = e)
save(list = ls(e, all.names = TRUE), file = "www/data/sysdata.rda", envir = e)

