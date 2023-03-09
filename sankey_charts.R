## sankey_charts.R
## ===============
## 
## Author: Mattia Mancini
## Created: 03-Mar-2023
## ----------------------
## DESCRIPTION
## Sankey summary charts for the PTRS paper
## ========================================

## (0) SETUP
## =========
rm(list=ls())
library(dplyr)
library(ggplot2)
library(networkD3)
library(webshot)      # convert sankey html into png
library(htmlwidgets)
library(gridExtra)    # grid_arrange
library(ggpubr)       # annotate_figure
# devtools::install_github("davidsjoberg/ggsankey")
# library(ggsankey)
# library(ggalluvial)

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
      select(new2kid, option_choice, option_hectares, benefits_total, farm_payment, 
             benefits_ghg_farm, benefits_ghg_dispfood, benefits_ghg_forestry, benefits_ghg_soil_forestry,
             benefits_rec, benefits_flooding, benefits_totn, benefits_totp, benefits_water_non_use,
             benefits_pollination_yield, benefits_pollination_non_use) %>% 
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
      mutate_at(vars(land_from, land_to, access, any_uptake), list(factor)) %>%
      mutate(benefits_ghg = benefits_ghg_farm + benefits_ghg_forestry + benefits_ghg_dispfood + benefits_ghg_soil_forestry)
    
    df <- df %>% 
      select(benefits_total, farm_payment, benefits_ghg, benefits_rec, benefits_flooding, benefits_totn, 
             benefits_totp, benefits_water_non_use, benefits_pollination_yield, 
             benefits_pollination_non_use, land_from, land_to, access)
    
    
    # nodes <- data.frame('id' = c(0:16),
    #                     'node' = c('budget','cost', 'benefits', 'arable', 'grassland', 
    #                                'sng access', 'sng no-access', 
    #                                'woodland access', 'woodland no-access',
    #                                'benefits_ghg', 'benefits_rec', 
    #                                'benefits_flooding', 'benefits_totn', 
    #                                'benefits_totp', 'benefits_water_non_use', 
    #                                'benefits_pollination_yield', 
    #                                'benefits_pollination_non_use'))
    # links <- data.frame('from' = c(0,0,2,2,3,3,3,3,4,4,4,4,rep(5,8),rep(6,8), rep(7,8), rep(8,8)),
    #                     'to'   = c(1,2,3,4,5,6,7,8,5,6,7,8,c(9:16),c(9:16), c(9:16), c(9:16)))
    nodes <- data.frame('id' = c(0:14),
                        'node' = c('benefits', 'arable', 'grassland', 
                                   'sng access', 'sng no-access', 
                                   'woodland access', 'woodland no-access',
                                   'benefits_ghg', 'benefits_rec', 
                                   'benefits_flooding', 'benefits_totn', 
                                   'benefits_totp', 'benefits_water_non_use', 
                                   'benefits_pollination_yield', 
                                   'benefits_pollination_non_use'))
    links <- data.frame('from' = c(0,0,1,1,1,1,2,2,2,2,rep(3,8),rep(4,8), rep(5,8), rep(6,8)),
                        'to'   = c(1,2,3,4,5,6,3,4,5,6,c(7:14),c(7:14), c(7:14), c(7:14)))
    links$values <- NA
    
    links$values[1] <- sum(df$benefits_total)
    links$values[2] <- sum(df$farm_payment)
    
    for (i in c(1:dim(links)[1])){
      from <- nodes[nodes$id==links[i, 'from'], 'node']
      to   <- nodes[nodes$id==links[i, 'to'], 'node']
      if (from == 'benefits'){
        val <- sum(df$benefits_total[df$land_from == to])
      } else if (from == 'arable' | from == 'grassland'){
        to_access <- strsplit(to, " ")[[1]][2]
        to <- strsplit(to, " ")[[1]][1]
        df_filter <- df %>% 
          select(land_from, land_to, access, benefits_total) %>%
          filter(land_from == from, land_to == to, access == to_access)
        val <- sum(df_filter$benefits_total)
      } else if (from == 'sng access' | from == 'sng no-access' | from == 'woodland access' | from == 'woodland no-access'){
        land <- strsplit(from, " ")[[1]][1]
        land_access <- strsplit(from, " ")[[1]][2]
        df_filter <- df %>% 
          select(benefits_total, land_from, land_to, access, to) %>%
          filter(land_to == land, access == land_access)
        val <- sum(df_filter[, which(colnames(df_filter) == to)])
      } else {
        stop('there is an error somewhere!')
      }
      links$values[i] <- val
    }
    
    
    nodes$node[8:length(nodes$node)] <- c("GHGs","Recreation","Flooding","water nitrogen", 
                        "water phosphorus", "non-use water quality", 
                        "pollination yields", "non-use pollination")
    
    
    col_codes <- c(brewer.pal(n=7,name='Spectral'), brewer.pal(n=7,name='Spectral'))
    colour_list <- paste(col_codes, collapse = '", "')
    colourJS <- paste('d3.scaleOrdinal(["', colour_list, '"])')
    
    a <- sankeyNetwork(Links=links, Nodes=nodes, Source="from", Target="to", 
                  Value="values", NodeID="node", fontSize=18, nodeWidth=45,
                  nodePadding=20, fontFamily="sans-serif", iterations=10,
                  width = 1200, height = 500, sinksRight=T, margin=c("left"=200),
                  colourScale = colourJS)
    to_move <- nodes$node[8:length(nodes$node)] 
    a <- onRender(
      a,
      paste0('
        function(el,x){
        d3.select(el)
        .selectAll(".node text")
        .filter(function(d) { return (["',paste0(to_move,collapse = '","'),'"].indexOf(d.name) > -1);})
        .attr("x", 6 + x.options.nodeWidth)
        .attr("text-anchor", "start");
        }
        ')
    )
    
    saveNetwork(a, paste0(save_path, "Sankey_diagram.html"), selfcontained = T)
    webshot(paste0(save_path, "Sankey_diagram.html"), paste0(save_path, "Sankey_diagram.png"), vwidth = 1200, vheight = 500)
    
    
    
    
    
    
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