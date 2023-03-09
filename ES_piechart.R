## ES_piechart.R
## =============
## 
## Author: Mattia Mancini
## Created: 03-Mar-2023
## ----------------------
## DESCRIPTION
## Pie chart to visualise the benefits by ecosystem service for the payment
## mechanisms included in the analysis for the PTRS paper
## ========================================================================

## (0) SETUP
## =========
library(ggplot2)
library(ggrepel)
library(tidyverse)

## Paths
data_path <- 'D:\\Documents\\GitHub\\defra-elms\\Data\\'
save_path <- 'D:\\Documents\\GitHub\\defra-elms\\Plots\\'

## (1) LOAD DATA
## =============

pay_mechanisms <- list('oc_pay', 'fr_act', 'fr_env', 'fr_es', 'fr_act_pctl', 
                       'fr_act_pctl_rnd', 'up_auc')
budgets        <- list('1bill')

for (mechanism in pay_mechanisms){
  for (budget in budgets){
    
    # open relevant data file
    df <- read.csv(list.files(data_path, pattern = paste0(budget, '_', mechanism, '.csv'), full.names = T))
    
    # select relevant columns
    benefits <- df[, grepl("benefits", names(df))]
    benefits$benefits_ghg_farm <- benefits$benefits_ghg_farm + benefits$benefits_ghg_dispfood
    benefits$benefits_treatment <- benefits$benefits_totn + benefits$benefits_totp
    benefits$benefits_ghg_dispfood <- NULL
    benefits$benefits_totn <- NULL
    benefits$benefits_totp <- NULL
    benefits_aggr <- colSums(benefits)
    data <- data.frame(
      category=c('GHG: farm', 'GHG: Trees', 'GHG: Soil', 'Recreation', 
                 'Flooding', 'Water non-use', 'Pollination: crops', 
                 'Pollination: non-use', 'Water treatment'),
      count=benefits_aggr[2:length(benefits_aggr)]
    )
    # Compute percentages
    data$fraction = round(data$count / sum(data$count) * 100, 1)
    
    # Compute the cumulative percentages (top of each rectangle)
    data$ymax = cumsum(data$fraction)

    # Compute the bottom of each rectangle
    data$ymin = c(0, head(data$ymax, n=-1))

    # Compute label position
    data$labelPosition <- (data$ymax + data$ymin) / 2

    # Compute a good label
    data$label <- paste0(data$category, "\n value: ", data$fraction)

    # title
    if (mechanism == 'oc_pay'){
      title = paste0('Benefits by ecosystem service\nopportunity cost\n')
    } else if (mechanism == 'fr_act'){
      title = paste0('Benefits by ecosystem service\nflat rate for activity\n')
    } else if (mechanism == 'fr_env'){
      title = paste0('Benefits by ecosystem service\nflat rate for environmental outcome\n')
    } else if (mechanism == 'fr_es'){
      title = paste0('Benefits by ecosystem service\nflat rate for ecosystem services\n')
    } else if (mechanism == 'fr_act_pctl'){
      title = paste0('Benefits by ecosystem service\nflat rate percentile for\nactivity with farmer selection\n')
    } else if (mechanism == 'fr_act_pctl_rnd'){
      title = paste0('Benefits by ecosystem service\nflat rate percentile\nfor activity, first-come-first-serve\n')
    } else if (mechanism == 'up_auc'){
      title = paste0('Benefits by ecosystem service\nuniform price auction\n')
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
    
    plot = ggplot(data, aes(ymax=ymax, ymin=ymin, xmax=5, xmin=3, fill=category)) +
      geom_rect() +
      geom_label_repel(data = data,
                       aes(x = 4, y = labelPosition, label = paste(category, '\n', fraction, '%')),
                       size = 5, nudge_x = 2, show.legend = FALSE) +
      scale_fill_brewer(palette='Spectral') +
      scale_color_brewer(palette='Spectral') +
      coord_polar(theta="y") +
      xlim(c(0, 5.5)) +
      theme_void() +
      # ggtitle(title) +
      annotate("text", x=0,y=0.5,label=title, size=6, fontface=2) +
      theme(legend.position = "none",
            plot.title = element_text(face="bold", hjust=0.5, vjust=0.5))
    
    # Save
    savename <- paste0('pie_', mechanism, '_', budget, '.tiff')
    ggsave(filename=savename, plot = plot, device = "tiff",
           path = save_path, units = "in", width = 12, height = 10)
  }
}