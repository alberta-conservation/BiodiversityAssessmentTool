# One-time preparation of the spatial objects used by the app.
# Reprojects to EPSG:4326 and applies the recoding that used to run in global.R
# at every app start. Rerun this script whenever the source data change.
#
# Objects are saved as uncompressed .rds: the fastest format to read with base R
# (about 2x faster than the gzip-compressed .rda files), at the cost of larger files.

library(sf)
library(dplyr)

dir_data <- "www/data"
save_fast <- function(x, name) saveRDS(x, file.path(dir_data, paste0(name, ".rds")), compress = FALSE)

# Oil sands regions (5th polygon dropped, as before) and BCR 6S
osr_4326 <- st_transform(st_read(file.path(dir_data, "oil_sands_areas.shp"), quiet = TRUE), crs = 4326)[-5, ]
bcr_4326 <- st_transform(st_read(file.path(dir_data, "BCR6S.shp"), quiet = TRUE), crs = 4326)

# BCR exposure metrics
load(file.path(dir_data, "bam_exposure_metrics.rda"))          # -> bam_exposure_metrics
bcr_exp_4326 <- st_transform(bam_exposure_metrics, crs = 4326)

# Lease exposure metrics
load(file.path(dir_data, "lease_current_exposure_metrics.rda"))   # -> lease_exp_current
load(file.path(dir_data, "lease_reference_exposure_metrics.rda")) # -> lease_exp_ref

# Lookup of lease holders by oil sands area. Built before recoding, so `osa`
# stays upper case (server.R filters it with toupper(input$prod_field)).
lease_osa_matrix <- lease_exp_ref |>
  st_drop_geometry() |>
  distinct(osa, lease_holder)

recode_osa <- function(x) {
  x |>
    st_transform(crs = 4326) |>
    mutate(
      osa = replace_values(
        osa,
        "ATHABASCA" ~ "Athabasca",
        "COLD LAKE" ~ "Cold Lake",
        "PEACE RIVER AREA 1" ~ "Peace River Area 1",
        "PEACE RIVER AREA 2" ~ "Peace River Area 2"
      )
    )
}
lease_exp_current_4326 <- recode_osa(lease_exp_current)
lease_exp_ref_4326 <- recode_osa(lease_exp_ref)

save_fast(osr_4326, "osr_4326")
save_fast(bcr_4326, "bcr_4326")
save_fast(bcr_exp_4326, "bcr_exp_4326")
save_fast(lease_exp_current_4326, "lease_exp_current_4326")
save_fast(lease_exp_ref_4326, "lease_exp_ref_4326")
save_fast(lease_osa_matrix, "lease_osa_matrix")
