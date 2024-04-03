# dataframe & string manipulation
library(tidyverse)
library(data.table)
library(rebus)
library(tidytable)
# plot & aesthetics
library(RColorBrewer)
library(ggtext)
library(ggdendro) # dentrogram
#
closeAllConnections()
rm(list=ls())
#
# load data from Rdata =====
load("data.Rdata")
member_name <- as.character(1:nrow(data)) 
#
# cat1 = Big Five Categories; cat2 = sub-categories under cat1 ====
cat1 <- data.frame(member_name, data[,2:6])
colnames(cat1)[2:6] <- str_sub(colnames(cat1)[2:6], 1, 1) #colnames(cat1)[2:6] <- c("Neuroticism", "Extraversion", " Openness To\n   Experience","Agreeableness", "Conscientious-\nness") 
cat2 <- data.frame(member_name, data[,-(1:6)])
#
# create function to generate dendrogram (here set 3 clusters (k = 3); can also change distancing methods) ====
gen_dendro <- function(cat, clus_k){#cat <- cat2
  dist_cat <- dist(cat[,-1], method = "euclidean")
  hc_cat <- hclust(dist_cat, method = "complete")
  #
  #ggdendrogram(hc_cat)
  dhc_cat <- as.dendrogram(hc_cat)
  ddata_cat <- dendro_data(dhc_cat, type = "rectangle")
  cluster_cat <- cutree(hc_cat, k = clus_k)[label(ddata_cat)$label %>% as.numeric()]
  #
  # assign colors for each member; avoid yellow range for better visualization ====
  n_member <- nrow(data); n_red_range <- ceiling(n_member/2); n_blue_range <- n_member - n_red_range
  colors <- data.frame(col = c(colorRampPalette(colors = brewer.pal(11, 'Spectral')[1:4])(n_red_range),
              colorRampPalette(colors = brewer.pal(11, 'Spectral')[8:11])(n_blue_range)),
              label = as.character(1:n_member)) %>% left_join(ddata_cat$labels[,c("x", "label")], by = "label") %>% arrange(x)
  col <- colors$col
#
  p <- ggplot(segment(ddata_cat)) + 
    geom_segment(aes(x = x, y = y, xend = xend, yend = yend), color = "grey40", size = 1) + 
    coord_flip() + 
    scale_y_reverse(expand = c(0.2, 0)) +
    theme_bw() +
    geom_point(data = cbind(label(ddata_cat), cluster=as.character(cluster_cat)),
               aes(x = x, y = y - 8, shape = cluster), fill = col, color = "NA", size = 8) +
    geom_text(data = label(ddata_cat), 
              aes(x = x, y = y - 8, label = paste0("",label)), 
              size = 5, fontface = "bold", color = "white") +
    scale_shape_manual(values =c(21,24,22))+
    theme(panel.grid = element_blank(),
          panel.border = element_blank(),
          axis.ticks = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          legend.position = "none")
  return(p)
}
#
dendro_list <- list(cat1 = gen_dendro(cat1, 3), cat2 = gen_dendro(cat2, 3))
save("dendro_list", file = "dendrogram.Rdata")