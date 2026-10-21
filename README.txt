This file describes the data included with the Vulnerability Report Download
from the Biodiversity Assessment Tool developed by the 
Alberta Biodiversity Conservation Program. 


  
- cell_exposure_data.csv
  Data describine the exposure of the species to oil sands disturbance within each 1ha cell 
  - SpeciesID: Species common name in camel case 
  - speciesCode: The four-letter species code
  - CommonName: The common name used in the application 
  - total_exp: the sum of cell-level exposure throughout the OSR
  - lease_exp: the sum of cell-level exposure among all lease areas
  - pct_rank_total: percentage rank of osr-level exposure from among all species
  - pct_rank_lease: percentage rank of lease-level exposure from among all species
  - osr_pop: estimated population size within the osr
  - osr_lease_area: area (ha) covered by oil sands leases within the OSR
  - osr_lease_prop: proportion of the OSR population on lease areas
  - osr_lease_index: Exposure index as proportion of the OSR-Level population in all leases divided by the proportion of the OSR covered by leases

- current_exposure_lease.shp 
  Data for current exposure of the selected species on the selected lease areas 
  - spp: The selected species
  - osa: The selected oil sands area(s) 
  - prod_pool: The productionn pool 
  - lease_holder: The company that holds the lease
  - lease: alpha-numeric code for the lease
  - lease_area_ha: lease area (ha) 
  - lease_pop: population size so the selected species within the lease area
  - lease_pct: percentage of the osr population of the selected species within the lease area
  - lease_index: Exposure index as proportion of the OSR-Level population in lease area divided by the proportion of the OSR covered by lease
  - geometry: spatial description of the lease area
  
- exposure_bcr.csv 
  Data on exposure of the BCR-level population to the oil sands area 
  - spp_code: the 4 letter species code for the selected species 
  - bcr_label: numeric label for bird conservation region 
  - name_en: the bird conservation region name in English
  - name_fr: the bird conservation region name in French 
  - bcr_pop: Estimatmed BCR-level population according to Boreal Avian Modelling Projct Version 5 models
  - osr_pop: Estimated OSR-level population according to Boreal Avian Modelling Projct Version 5 models
  - osr_pct: Percentage of the BCR-level populaiton in the OSR
  - osr_index: Exposure index as proportion of the BCR-Level population in the OSR divided by the proportion of the BCR covered by the OSR
  
- exposure_osr.tif
  Raster file of cell-level exposure in the OSR
  
- linear_sensitivity.csv 
  Measure of the species’ relative abundance in four types of linear features: Energy Seismic (narrow and wide seismic lines); Energy Soft Linear (energy related features such as transmission lines and pipelines); Transportation Soft Linear (road verges); and Transportation Hard Linear (roads and rails). These figures represent the under footprint effects of these four groups
  

- reference_exposure_lease.shp
  Same as for current exposure lease, but assuming no humanfootprint 
  
- reference_sdm_osr.tif
  Raster map of predicted species distribution within the OSR assuming no human footprint

- sector_sensitivity.csv 
  Coefficients representing the the difference between the abundance of the species in the native habitat prior to the footprint and the abundance in the footprint expressed as a percentage relative to the reference
  - The report displays LocalScale_Energy
  
- vulnerability_report.html
  The generated report in .html format 


