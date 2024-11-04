library(tidyverse)
library(spatialreg)
library(INLA)
library(spdep)  #adjacency matrix


# -------- Global Model formula -----
# Bernardinelli model:
formula <- count ~ f(id.area, model = "bym", graph = g) + 
  f(id.area1, id.month, model = "iid") + 
  f(id.area2, stringency, model = "iid") +
  f(quarter, model = 'iid') +
  id.month


# ------- Plot themes ------
plt_theme = theme(
  axis.text.x = element_text(size = 12, angle = 37, margin = margin(t = 12)),
  axis.text.y = element_text(size = 12, margin = margin(t = 6)),
  legend.text = element_text(family = "Arial",size = 15),
  legend.title = element_text(size = 15, face = "bold"),
  legend.spacing.x = unit(1,"cm"),
  axis.title.y = element_text(family = "Arial",size = 12, face = "bold"),
  axis.title.x = element_text(family = "Arial",size = 12, face = "bold", 
                              margin = margin(t = 10, r = 0, b = 0, l = 0)),
  title = element_text(face = 'bold'))

# -------- Global Function ----------
map_effects = function(df, polygones, fitted_model, uncertainty_bound = 'middle'){
  # It maps the stringency effect over the regions of a city
  
  #-Args:
  #   df (data.frame): A dataframe containing outputs of the INLA model
  #   polygones (sf data.frame): Polygones of the target city 
  #   fitted_model (INLA object): An INLA fitted object including the strigency effect
  #-Returns:
  #   Map of the strigency effect
  # browser()  
  st_med <- fitted_model$summary.random$id.area2$`0.5quant`
  st_low <- fitted_model$summary.random$id.area2$`0.025quant`
  st_high <- fitted_model$summary.random$id.area2$`0.975quant`
  
  df_map = left_join(df, polygones, by = "id.area") %>% st_as_sf()
  
  if (uncertainty_bound == 'middle'){
    df_str_effect = data.frame(id.area = seq(1,length(st_med),1), str = st_med)
  }
  else if (uncertainty_bound == 'low'){
    df_str_effect = data.frame(id.area = seq(1,length(st_med),1), str = st_low)
  }
  else{
    df_str_effect = data.frame(id.area = seq(1,length(st_med),1), str = st_high)
  }
  
  # st_crs(df_map) = 4326 # a weird bug in sf package that can be solved by this trick for mapping
  
  df_map %>% 
    filter(id.month == 10) %>% 
    left_join(., df_str_effect) %>% 
    ggplot() + geom_sf(aes(fill = str), lwd = 0.1) + # Changing the effect's scale to percentage per unit increase
    labs(fill = NULL) + #'log(θ)'
    theme_bw() + 
    theme(legend.position = c(0.11,0.8),
          # plot.background = element_rect(fill = "grey5"),
          panel.background = element_rect(fill = "grey90", colour="blue"),
          #title = element_text(color = "white", size = 20, face = "bold"),
          legend.text = element_text(color = "black", size = 8),
          #strip.text = element_text(colour = 'white', size = 10, face = "bold"),
          legend.title = element_text(face = "bold"),
          axis.text.x = element_text(size = 12, margin = margin(t = 6)),
          axis.text.y = element_text(size = 12, margin = margin(t = 6)),
          #axis.ticks = element_blank()
    ) + 
    #scale_fill_gradient2(midpoint = 0, low = "dodgerblue4", mid = "white", high = "red")#, labels= ~paste(.x, "%")
    scale_fill_gradient2(midpoint = 0, limits = c(min(st_low), max(st_high)),low = "dodgerblue4", mid = "white", high = "red")
  
  
}


# -------------------------------- Modelling UK data -----------------------------------------

# -------- New code (Can be used for other types of crimes) 

g <- poly2nb(shapefile) # Extracting adjacency matrix
image(inla.graph2matrix(g),xlab=NULL,ylab=NULL, main= "Adjacency Matrix")

# Fitting INLA
res_uk <- inla(formula, family = "poisson", data = df_inla , control.predictor = list(compute = TRUE))

# Evaluating the model results
df_inla$count <- res_uk$summary.fitted.values[, "mean"] #Expectation

# ----- Plotting 
#(c <- plot_risk(df_inla) )
# ----- Mapping stringency index
p_low = map_effects(df_inla, la_uk, res_uk, uncertainty_bound = 'low') +
  ggtitle("Percentile: 2.5%")

p_mid = map_effects(df_inla, la_uk, res_uk, uncertainty_bound = 'middle') +
  ggtitle("Percentile: 50%")

p_high = map_effects(df_inla, la_uk, res_uk, uncertainty_bound = 'high') +
  ggtitle("Percentile: 97.5%")

combined_plot = ggpubr::ggarrange(p_low, p_mid, p_high, ncol = 3, nrow = 1)

ggsave(filename = "Violence and sexual offences map.png",  
  plot = combined_plot,
  width = 12,    
  height = 6,    
  dpi = 600)


