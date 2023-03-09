## maps.R
## ======
## 
## Author: Mattia Mancini
## Created: 03-Mar-2023
## ----------------------
## DESCRIPTION
## maps to visualise spatial distribution of uptake of each option from the work
## for the PTRS paper. The output of this script is a strip of 5 maps in this 
## order:
## 1 - elm uptake (cells enrolled in any scheme)
## 2 - converted to sng from (arable, grassland)
## 3 - sng rec access (yes, no)
## 4 - converted to woodland from (arable, grassland)
## 5 - woodland rec access (yes, no)
## =============================================================================

## (0) SETUP
## =========
rm(list=ls())
library(sf)
library(RPostgres)
library(dplyr)
library(gridExtra)    # grid_arrange
library(ggpubr)       # annotate_figure


## Paths
data_path <- 'D:\\Documents\\GitHub\\defra-elms\\Data\\'
seer_path <- 'D:\\Documents\\Data\\SEER\\____STATE_OF_GB____\\SEER_GIS\\SEER_GRID\\'
save_path <- 'D:\\Documents\\GitHub\\defra-elms\\Plots\\'

## (1) LOAD DATA
## =============
## 1.1. Seer 2km grid
## ------------------
seer_2km <- st_read(paste0(seer_path, 'SEER_net2km.shp'))
seer_2km <- seer_2km[, "new2kid"]

# filter to England 
conn <- dbConnect(Postgres(), 
                  dbname = "nev",
                  host = "localhost",
                  port = 5432,
                  user="postgres",
                  password="postgres")

df <- dbGetQuery(conn, "SELECT * FROM regions_keys.key_grid_countries_england")
cell_id <- df$new2kid
seer_2km <- seer_2km[seer_2km$new2kid %in% cell_id, 'new2kid']

## 1.2. Border of England
## ----------------------
eng_border <- st_read("D:/Documents/Data/BNG/Data/SEER_GRID/england_full_clipped.shp")

## (2) LOOP TO CREATE MAPS
## ========================
pay_mechanisms <- list('oc_pay', 'fr_act', 'fr_env', 'fr_es', 'fr_act_pctl', 
                       'fr_act_pctl_rnd', 'up_auc')
budgets        <- list('1bill')

for (mechanism in pay_mechanisms){
  for (budget in budgets){
    
    # open relevant data file
    df <- read.csv(list.files(data_path, pattern = paste0(budget, '_', mechanism, '.csv'), full.names = T)) %>%
      select(new2kid, option_choice, option_hectares) %>% 
      mutate(land_from = case_when(
        (option_choice == 1 | option_choice == 3 | option_choice == 5 | option_choice == 7) ~ "arable",
        (option_choice == 2 | option_choice == 4 | option_choice == 6 | option_choice == 8) ~ "grassland")
        ) %>%
      mutate(land_to = case_when(
        (option_choice == 1 | option_choice == 2 | option_choice == 5 | option_choice == 6) ~ "sng",
        (option_choice == 3 | option_choice == 4 | option_choice == 7 | option_choice == 8) ~ "woodland")
      ) %>%
      mutate(access = case_when(
        (option_choice == 1 | option_choice == 2 | option_choice == 3 | option_choice == 4) ~ "access",
        (option_choice == 5 | option_choice == 6 | option_choice == 7 | option_choice == 8) ~ "no-access")
      ) %>%
      mutate(any_uptake = if_else(option_choice != 0, 'uptake', '0')) %>%
      mutate_at(vars(land_from, land_to, access, any_uptake), list(factor))
    
    sp_df <- merge(seer_2km, df, by='new2kid')

        # 2.1. uptake map
    # ---------------
    uptake <- ggplot() +
      # geom_sf(data = eng_border, fill = 'white', lwd = 0.8) +
      geom_sf(data = sp_df,
              aes(fill = any_uptake, color = any_uptake)) +
      scale_fill_manual(values = c("brown4"), na.value='white') +
      scale_color_manual(values = c("brown4"), na.value='white') +
      geom_sf(data = eng_border, fill = NA, lwd = 0.6) +
      ggtitle('Option uptake') +
      theme_bw() +
      theme(panel.border = element_blank(), 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      coord_sf(datum = NA) +
      theme(plot.title = element_text(size=30, hjust = 0.5),
            legend.text = element_text(size = 22),
            legend.title = element_blank(),
            legend.position = 'bottom')
    
    to_sng <- ggplot() +
      # geom_sf(data = eng_border, fill = 'white', lwd = 0.8) +
      geom_sf(data = sp_df[sp_df$land_to == 'sng',],
              aes(fill = land_from, color = land_from)) +
      scale_fill_manual(values = c("brown4", "darkolivegreen"), na.value='white') +
      scale_color_manual(values = c("brown4","darkolivegreen"), na.value='white') +
      geom_sf(data = eng_border, fill = NA, lwd = 0.6) +
      ggtitle('Converted to sng from') +
      theme_bw() +
      theme(panel.border = element_blank(), 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      coord_sf(datum = NA) +
      theme(plot.title = element_text(size=30, hjust = 0.5),
            legend.text = element_text(size = 22),
            legend.title = element_blank(),
            legend.position = 'bottom')
    
    sng_access <- ggplot() +
      # geom_sf(data = eng_border, fill = 'white', lwd = 0.8) +
      geom_sf(data = sp_df[sp_df$land_to == 'sng',],
              aes(fill = access, color = access)) +
      scale_fill_manual(values = c("red3", "blue4"), na.value='white') +
      scale_color_manual(values = c("red3","blue4"), na.value='white') +
      geom_sf(data = eng_border, fill = NA, lwd = 0.6) +
      ggtitle('sng recreational access') +
      theme_bw() +
      theme(panel.border = element_blank(), 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      coord_sf(datum = NA) +
      theme(plot.title = element_text(size=30, hjust = 0.5),
            legend.text = element_text(size = 22),
            legend.title = element_blank(),
            legend.position = 'bottom')
    
    to_wood <- ggplot() +
      # geom_sf(data = eng_border, fill = 'white', lwd = 0.8) +
      geom_sf(data = sp_df[sp_df$land_to == 'woodland',],
              aes(fill = land_from, color = land_from)) +
      scale_fill_manual(values = c("brown4", "darkolivegreen"), na.value='white') +
      scale_color_manual(values = c("brown4","darkolivegreen"), na.value='white') +
      geom_sf(data = eng_border, fill = NA, lwd = 0.6) +
      ggtitle('Converted to woodland from') +
      theme_bw() +
      theme(panel.border = element_blank(), 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      coord_sf(datum = NA) +
      theme(plot.title = element_text(size=30, hjust = 0.5),
            legend.text = element_text(size = 22),
            legend.title = element_blank(),
            legend.position = 'bottom')
    
    wood_access <- ggplot() +
      # geom_sf(data = eng_border, fill = 'white', lwd = 0.8) +
      geom_sf(data = sp_df[sp_df$land_to == 'woodland',],
              aes(fill = access, color = access)) +
      scale_fill_manual(values = c("red3", "blue4"), na.value='white') +
      scale_color_manual(values = c("red3","blue4"), na.value='white') +
      geom_sf(data = eng_border, fill = NA, lwd = 0.6) +
      ggtitle('Woodland recreational access') +
      theme_bw() +
      theme(panel.border = element_blank(), 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      coord_sf(datum = NA) +
      theme(plot.title = element_text(size=30, hjust = 0.5),
            legend.text = element_text(size = 22),
            legend.title = element_blank(),
            legend.position = 'bottom')
    
    # title
    if (mechanism == 'oc_pay'){
      title = paste0('Scheme uptake and land use change\nopportunity cost\n')
    } else if (mechanism == 'fr_act'){
      title = paste0('Scheme uptake and land use change\nflat rate for activity\n')
    } else if (mechanism == 'fr_env'){
      title = paste0('Scheme uptake and land use change\nflat rate for environmental outcome\n')
    } else if (mechanism == 'fr_es'){
      title = paste0('Scheme uptake and land use change\nflat rate for ecosystem services\n')
    } else if (mechanism == 'fr_act_pctl'){
      title = paste0('Scheme uptake and land use change\nflat rate percentile for\nactivity with farmer selection\n')
    } else if (mechanism == 'fr_act_pctl_rnd'){
      title = paste0('Scheme uptake and land use change\nflat rate percentile\nfor activity, first-come-first-serve\n')
    } else if (mechanism == 'up_auc'){
      title = paste0('Scheme uptake and land use change\nuniform price auction\n')
    } else {
      stop('Payment mechhanism not found!!!\n')
    }
    
    if (budget == '1bill'){
      title = paste0(title, '£1 billion budget')
    } else if (budget == '2bill'){
      title = paste0(title, '£2 billion budget')
    } else if (budget == '3bill'){
      title = paste0(title, '£3 billion budget')
    } else {
      stop('Error in budget specification!!!\n')
    }
    
    figure <- ggarrange(uptake, to_sng,  sng_access, to_wood, wood_access,
                        ncol = 5, nrow = 1) + 
      bgcolor("white") + 
      border("white")
    
    figure <- annotate_figure(figure,
                              top = text_grob(title, face = "bold", size = 32))
    filename <- paste0('maps_', mechanism, '_', budget, '.tiff')
    ggsave(filename=filename, plot = figure, device = "tiff",
           path = save_path, units = "in", width = 30, height = 14) 
  }
}