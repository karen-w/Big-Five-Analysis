# dataframe & string manipulation
library(tidyverse)
library(data.table)
library(rebus)
library(tidytable)
# plot & aesthetics
library(ggradar)
library(gridExtra)
library(RColorBrewer)
library(ggtext)
#
closeAllConnections()
rm(list=ls())
#
# source functions in ggradar package (manually edited previously from original code) ====
walk(list.files("D:/MSL Miscellaneous/20240320 LMT BigFive/github/ggradar_edit", full.names = T), source)
#
# load data from Rdata; set dir if necessary ====
# setwd()
load("data.Rdata")
member_name <- as.character(1:nrow(data)) 
#
# cat1 = Big Five Categories; cat2 = sub-categories under cat1 ====
cat1 <- data.frame(member_name, data[,2:6])
colnames(cat1)[2:6] <- str_sub(colnames(cat1)[2:6], 1, 1) #colnames(cat1)[2:6] <- c("Neuroticism", "Extraversion", " Openness To\n   Experience","Agreeableness", "Conscientious-\nness") 
cat2 <- data.frame(member_name, data[,-(1:6)])
#
# assign colors for each member; avoid yellow range for better visualization ====
n_member <- nrow(data); n_red_range <- ceiling(n_member/2); n_blue_range <- n_member - n_red_range
colors <- c(colorRampPalette(colors = brewer.pal(11, 'Spectral')[1:4])(n_red_range),
            colorRampPalette(colors = brewer.pal(11, 'Spectral')[8:11])(n_blue_range))
#
# create function to generate radar plot ====
gen_rader <- function(member_num, label){ #member_num <- 5; label == TRUE
  out <- ggradar(cat1[member_num,], base.size = 3,
                 axis.label.size = 3, axis.label.offset = 1.18, axis.label.color = "grey20", axis.lebel.face = "bold",
                 label.gridline.max = FALSE, label.gridline.mid = FALSE, label.gridline.min = FALSE,
                 grid.min = 0, grid.mid = 60, grid.max = 120,
                 gridline.mid.colour = "grey",
                 plot.extent.x.sf = 1.4, plot.extent.y.sf = 1.4,
                 fill = TRUE, fill.alpha = 0.25,
                 group.colours = colors[member_num], group.point.size = 1.5, group.line.width = 1) +
    theme(panel.border = element_blank(),
          plot.margin = unit(c(0,0,0,0), "lines")
    )
  if(label == TRUE){
    #out <- out + theme(title = element_text(size = 12, color = colors[member_num], face = "bold"))
    out <- out + geom_text(x = 0, y = 0, label = member_num,
                           size = 6, fontface = "bold", color = colors[member_num])
  }# else {
  #  out <- out + theme(title = element_blank())
  #}
  return(out)
}
radar_list_titleT <- map2(1:n_member, TRUE, gen_rader) # generate individual radar plots with labels
radar_list_titleF <- map2(1:n_member, FALSE, gen_rader) # generate individual radar plots without labels
#
print(grid.arrange(grobs = radar_list_titleT, nrow = 3, padding = unit(0, "line"))) # plot on screen for viewing 
save(list=c("radar_list_titleT", "radar_list_titleF"), file = "radar.Rdata") # save plot lists as Rdata