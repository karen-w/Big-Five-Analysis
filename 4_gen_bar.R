# dataframe & string manipulation
library(tidyverse)
library(data.table)
library(rebus)
library(tidytable)
# plot & aesthetics
library(RColorBrewer)
library(ggtext)
library(wesanderson)
#
closeAllConnections()
rm(list=ls())
# load data  ====
#setwd()
load("data.Rdata")
load("radar.Rdata")
load("dendrogram.Rdata")
# cat names =====
cat1_name <- colnames(data)[2:6]
cat2_name <- colnames(data)[7:length(colnames(data))] %>% str_replace_all(" ", "-")
cat_df <- data.frame(cat1 = rep(cat1_name, each = 6), cat2 = cat2_name)
# member names ====
member_name <- as.character(1:nrow(data)) 
#
# assign colors for each member; avoid yellow range for better visualization ====
n_member <- nrow(data); n_red_range <- ceiling(n_member/2); n_blue_range <- n_member - n_red_range
colors <- c(colorRampPalette(colors = brewer.pal(11, 'Spectral')[1:4])(n_red_range),
            colorRampPalette(colors = brewer.pal(11, 'Spectral')[8:11])(n_blue_range))
#
# generate bar-plots for cat2 ====
gen_bar <- function(cat){ #cat <- cat2_longtbl
  bar <- ggplot(cat, aes(x = member, y = val)) +
    facet_wrap(.~cat2, nrow = 1) +
    geom_col(aes(fill = member), alpha = 0.8) +
    geom_text(aes(y = val + 2, label = val), size = 2.6, color = "grey20") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    labs(title = paste0(cat$cat1[1], " (",str_sub(cat$cat1[1],1,1), ")")) +
    ylim(c(0, 23)) + 
    theme(axis.title = element_blank(),
          legend.title = element_blank(),
          panel.grid = element_blank(),
          panel.border = element_blank(),
          legend.position = "none",
          strip.background = element_rect(fill = "grey90", color = "NA"),
          strip.text = element_text(size = 6, face = "bold", color = "grey20"),
          axis.text = element_blank(), axis.ticks = element_blank(), 
          title = element_text(size = 8.5, face = "bold", color = "grey20"))
  return(bar)
}
# generate long tbl ====
cat2_longtbl <- data[,-1] %>% data.frame(row.names = member_name) %>% t() %>%
  data.frame() %>% .[-c(1:5),] %>% rownames_to_column(var = "cat2") %>%
  gather(member, val, -cat2) %>% mutate(cat2 = str_replace_all(cat2, "\\.", "\\-")) %>%
  left_join(cat_df, by = "cat2") %>% select(cat1, cat2, member, val) %>% 
  mutate(member = str_replace_all(member, "X", ""))
cat2_longtbl$cat1 <- factor(cat2_longtbl$cat1, levels = colnames(data)[2:6])
cat2_longtbl$member <- factor(cat2_longtbl$member, levels = dendro_list$cat2$plot_env$ddata_cat$labels$label)
# 
bar_list <- map(cat2_longtbl %>% group_by(cat1) %>% group_split(), gen_bar) #bar_list[[1]]
save(list = c("bar_list"), file = "bar.Rdata")