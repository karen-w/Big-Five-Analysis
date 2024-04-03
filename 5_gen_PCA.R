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
# assign colors for each member; avoid yellow range for better visualization ====
n_member <- nrow(data); n_red_range <- ceiling(n_member/2); n_blue_range <- n_member - n_red_range
colors <- c(colorRampPalette(colors = brewer.pal(11, 'Spectral')[1:4])(n_red_range),
            colorRampPalette(colors = brewer.pal(11, 'Spectral')[8:11])(n_blue_range))
# generate long tbl ====
cat2_longtbl <- data[,-1] %>% data.frame(row.names = member_name) %>% t() %>%
  data.frame() %>% .[-c(1:5),] %>% rownames_to_column(var = "cat2") %>%
  gather(member, val, -cat2) %>% mutate(cat2 = str_replace_all(cat2, "\\.", "\\-")) %>%
  left_join(cat_df, by = "cat2") %>% select(cat1, cat2, member, val) %>% 
  mutate(member = str_replace_all(member, "X", ""))
cat2_longtbl$cat1 <- factor(cat2_longtbl$cat1, levels = colnames(data)[2:6])
cat2_longtbl$member <- factor(cat2_longtbl$member, levels = dendro_list$cat2$plot_env$ddata_cat$labels$label)
# generate PCA ====
cat_tbls <- list(cat1 = data.frame(member_name, data[,2:6]), cat2 = data.frame(member_name, data[,-(1:6)]))
#
gen_cluster_tbl <- function(cat_sel){ #cat_sel <- "cat1"
  out <- data.frame(member = dendro_list[[cat_sel]]$plot_env$ddata_cat$labels$label,
                    cluster = dendro_list[[cat_sel]]$plot_env$cluster_cat) %>% arrange(member)
  return(out)
}
clusters <- map(paste0("cat", 1:2), gen_cluster_tbl)
#
gen_PCA <- function(n_cat, loadTF, n_load){# n_cat <- 1; loadTF <- TRUE
  cat_pca <- prcomp(cat_tbls[[n_cat]][,-1], scale=TRUE)
  cat_pc_tbl <- data.frame(clusters[[n_cat]], as.data.frame(cat_pca$x))
  var <- cat_pca$sdev^2 / sum(cat_pca$sdev^2) # % variance explained by each PC
  #
  PCA_basic <- ggplot(cat_pc_tbl, aes(x = PC1, y = PC2)) +
    coord_equal() +
    geom_point(aes(shape = as.character(cluster), fill = member), size = 5, color = "NA") +
    geom_text(aes(x = PC1+0, y = PC2+0, label = member), 
              fontface = "bold", size = 3.5, color = "white") +
    scale_fill_manual(values = colors) +
    scale_shape_manual(values = c(21, 24, 22)) +
    theme_bw() +
    labs(x = paste0("PC1 (", round(var[1]*100,2), "%)"),
         y = paste0("PC2 (", round(var[2]*100,2), "%)"),
         shape = "Cluster") +
    guides(fill = "none", shape = guide_legend(override.aes = list(fill = "grey20", size = 2.4))) +
    theme(panel.grid = element_blank(),
          panel.border = element_rect(color = "grey20"),
          legend.position = "right",
          legend.box.margin = unit(c(0,0,0,1), "mm"),
          axis.text = element_text(size = 8),
          axis.title.x = element_text(margin = unit(c(4, 0, 0, 0), "mm")),
          axis.title.y = element_text(margin = unit(c(0, 4, 0, 0), "mm")),
          axis.title = element_text(size = 8, color = "grey30", face = "bold"))
  # add loadings
  if (loadTF == TRUE) {
    if(n_cat == 1){cat_name <- cat1_name} else {cat_name <- cat2_name}
    load_tbl <- data.frame(Variables = cat_name, cat_pca$rotation)
    load_mult <- (max(cat_pc_tbl$PC1)/max(load_tbl$PC1))*0.55
    if (n_cat == 1){
      PCA_out <- PCA_basic + 
        geom_segment(data = load_tbl, 
                     aes(x = 0, y = 0, xend = (PC1*load_mult), yend = (PC2*load_mult)), 
                     arrow = arrow(length = unit(0.4, "picas")), color = "grey50") +
        annotate("text", x = (load_tbl$PC1*(load_mult*1.15)), y = (load_tbl$PC2*(load_mult*1.15)),
                 label = load_tbl$Variables, size = 3, color = "grey20")
      } else if (n_cat == 2) {
        cat1_col <- data.frame(cat1 = cat1_name,
                   cat1_col = colorRampPalette(colors = wes_palette("GrandBudapest2"))(10)[c(1,3,5,7,9)])
                     #rev(brewer.pal(n = 5, name = 'Dark2')))#viridis(10)[c(1,3,5,7,9)])
        #
        top_var <- load_tbl %>% select(Variables, PC1, PC2) %>% 
          mutate(hyp = sqrt(PC1^2+PC2^2)) %>% arrange(desc(hyp)) %>%
          left_join(cat2_longtbl %>% select(-member, -val) %>% unique(), by = c("Variables" = "cat2")) %>%
          left_join(cat1_col, by = "cat1") %>% .[1:n_load,]
        if(n_load < 30){title <- paste0("PCA (Top ", n_load, " loadings)")} else {title <- "PCA (All loadings)"}
        set.seed(10)
        PCA_out <- PCA_basic + 
          geom_segment(data = top_var, 
                       aes(x = 0, y = 0, xend = (PC1*load_mult), yend = (PC2*load_mult)), 
                       arrow = arrow(length = unit(0.4, "picas")), 
                       color = top_var$cat1_col, alpha = 0.6,#linetype = "dotted", 
                       linewidth = 0.7) +
          geom_label(data = top_var,
                    aes(x = PC1*(load_mult*1.6), y = PC2*(load_mult*1.2)),
                    label = top_var$Variables, size = 3, fill = top_var$cat1_col, 
                    color = "white", alpha = 0.6, fontface = "bold", hjust = 0.5, vjust = 1,
                    label.size = 0,
                    position = position_jitter(width = 0.8, height = 0.8)) +
          ggtitle(label = title) +
          theme(title = element_text(size = 8, face = "bold", color = "grey20"))
        PCA_out$layers <- PCA_out$layers[c(4,3,1,2)]
        PCA_out
      }
  } else { PCA_out <- PCA_basic }
  return(PCA_out)
}
PCA_cat1 <- list(gen_PCA(n_cat = 1, loadTF = FALSE), gen_PCA(n_cat = 1, loadTF = TRUE))
PCA_cat2 <- list(gen_PCA(n_cat = 2, loadTF = FALSE), pmap(list(2, TRUE, seq(10, 30, by = 5)), gen_PCA))
#
# save PCA plots ====
save(list = c("PCA_cat1", "PCA_cat2"), file = "PCA.Rdata")