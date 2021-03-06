## Define the local directory for R librairies
dir.rsat <- Sys.getenv("RSAT")
if (dir.rsat == "") {
  stop(paste("The environment variable RSAT is not defined. Command: ", commandArgs()))
}

## Load some libraries
source(file.path(dir.rsat, 'R-scripts/config.R'))

## Load required libraries
required.packages = c("RColorBrewer","gplots")

## List of RSAT-specific packages to be compiled on the server
for (pkg in c(required.packages)) { #required.packages.bioconductor
  suppressPackageStartupMessages(library(pkg, warn.conflicts=FALSE, character.only = TRUE, lib.loc=c(dir.rsat.rlib, .libPaths())))
}

###########################################
## Read arguments from the command line.
##
## Arguments passed on the command line
## will over-write the default arguments
## specified above.
# message("Reading arguments from command-line")
args <- commandArgs(trailingOnly=TRUE)
if (length(args >= 1)) {
  for(i in 1:length(args)){
    eval(parse(text=args[[i]]))
  }
}

if (!exists("prefix")) {
  stop("Missing mandatory argument (prefix): prefix ")
} else if (!exists("maxNWD.table.file")) {
  stop("Missing mandatory argument ( NWD table (matrix-quality output) ): maxNWD.table.file ")
} else if (!exists("d3.base")) {
  stop("Missing mandatory argument (The path to the D3 source code):d3.base  ")
} else if (!exists("d3.array.base")) {
  stop("Missing mandatory argument (The path to the D3 Array library source code):d3.array.base  ")
} else if (!exists("maxNWD.tsv")) {
  stop("Missing mandatory argument (The path to the tsv file used as input for the dynamic heatmap): maxNWD_tsv ")
} else if (!exists("parsed.heatmap.html")) {
  stop("Missing mandatory argument (The path to the D3 Dynamic heatmap): parsed.heatmap.html  ")
} else if (!exists("Sequences")){
  stop("Missing mandatory argument (Sequences names): Sequences ")
} else if (!exists("TFs")){
  stop("Missing mandatory argument (TF names): TFs ")
} else if (!exists("fields.table")){
  stop("Missing mandatory argument (The path to the table to complete the html report): fields.table ")
}



## Not required
# else if (!exists("Diff.maxNWD.tsv")) {
#   stop("Missing mandatory argument (The path to the tsv file used as input for the dynamic heatmap): Diff.maxNWD_tsv ")
# } else if (!exists("Diff.maxNWD.heatmap.html")) {
#   stop("Missing mandatory argument (The path to the D3 Dynamic heatmap): Diff.maxNWD.heatmap.html  ")
# }



if (!exists("heatmap.color.palette")) {
  heatmap.color.palette <- "RdBu";
}
if (!exists("heatmap.color.classes")) {
  heatmap.color.classes <- as.numeric(9);
}
heatmap.color.classes <- as.numeric(heatmap.color.classes)

fields.to.fill.report <- data.frame()

# maxNWD.table.file <- "/home/jamondra/Downloads/maxNWD_heatmap_compare.txt"
# TFs <- c("DDIT", "FCP2_GRHL1", "JUN_FOS", "REST", "SP", "USF2", "YY")
# Sequences <- c("HELA", "K562", "inactive")

# maxNWD.table.file <- "/home/jaime/Downloads/MatEnr/maxNWD_heatmap_compare.txt"
# TFs <- c("DDIT", "FCP2_GRHL1", "JUN_FOS", "REST", "SP", "USF2", "YY")
# Sequences <- c("HELA", "K562", "inactive")


#############################
## Draw the maxNWD heatmap ##
#############################
base.name <- basename(prefix)

#######################################
## Read the input file: maxNWD table
max.NWD.table <- read.table(maxNWD.table.file, sep = "\t", header = TRUE)
max.NWD.table <- round(max.NWD.table, digits = 3)
max.NWD.table[is.na(max.NWD.table)] <- 0


# ## Calculate Differential
sets <- colnames(max.NWD.table)
# for(n in 1:(length(sets)-1)){
#   
#   for(m in 2:(length(sets))){
#     ## Get the set names
#     set1 <- sets[n]
#     set2 <- sets[m]
#     
#     ## Skip when the both sets are the same
#     if(n < m){
#       ## Assign the names to the differential
#       diff.name.1 <- paste("Diff", set1, set2, sep = "__")
#       diff.name.2 <- paste("Diff", set2, set1, sep = "__")
#       
#       print(diff.name.1)
#       print(diff.name.2)
#       
#       max.NWD.table[,diff.name.1] <- max.NWD.table[,set1] - max.NWD.table[,set2]
#       max.NWD.table[,diff.name.2] <- max.NWD.table[,diff.name.1] * -1
#     }
#   }
# }

nb.sets <- length(sets)
nb.diff.columns <- dim(max.NWD.table)[2]

# NWD.sub <- max.NWD.table[,(nb.sets+1):nb.diff.columns]
NWD.sub <- max.NWD.table
NWD.sub <- NWD.sub[order(NWD.sub[,1], decreasing = TRUE),]
NWD.sub <- as.matrix(round(NWD.sub, digits = 2))


#######################################################################
## Convert the DataFrame in a 'tsv' object which is the input format
## for D3 heatmap.
# for(set in c("Normal", "Diff")){
set <- "Normal"

  tsv.tab <- NULL
  
  if(set == "Normal"){
    tab <- max.NWD.table
    file.export <- maxNWD.tsv
    heatmap.html <- parsed.heatmap.html
  } else if (set == "Diff"){
    tab <- NWD.sub
    file.export <- Diff.maxNWD.tsv
    heatmap.html <- Diff.maxNWD.heatmap.html
  }
  
  for(j in 1:dim(tab)[1]){
    for(i in 1:dim(tab)[2]){
      tsv.tab <<- rbind(tsv.tab, matrix(c(j,i, as.numeric(tab[j,i])), nrow = 1))
    }
  }
  
  ## Export the TSV table
  colnames(tsv.tab) <- c("Row", "Col", "Value")
  write.table(tsv.tab, file = file.export, sep = "\t", quote = FALSE, row.names = FALSE)
  
    
  ################################################
  ## Generate the lines to fill the html report ##
  ## Export the fields in a table               ##
  ################################################
  
  ## Get the Sequences (column) and Motifs (row) names
  sequences.names <- colnames(tab)
  motifs.names <- rownames(tab)
  
  ## Add the logo path to the template
  logo.path <- sapply(motifs.names, function(m){
    paste("'", m, "/", base.name, "_", m, "_logo_m1.png'", sep = "")
  })
  logo.path <- as.vector(logo.path)
  logo.path <- paste(logo.path, collapse = ",")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--logo_path--",
                                          content = logo.path))
  
  
  ## Add the link to the distrib comparison curves pictures
  curves.path <- sapply(motifs.names, function(m){
    paste("'", m, "/", base.name, "_", m, "_score_distrib_compa_logy.png'", sep = "")
  })
  curves.path <- as.vector(curves.path)
  curves.path <- paste(curves.path, collapse = ",")

  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--curves_path--",
                                                                   content = curves.path))
  
  
  ## Insert the number of rows and columns
  col.nb <- length(sequences.names)
  row.nb <- length(motifs.names)
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--r_numb--",
                                                                   content = as.character(row.nb)))
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--c_numb--",
                                                                   content = as.character(col.nb)))
  
  
  ## Insert the D3 paths
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--d3_base--",
                                                                   content = d3.base))
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--d3_array_base--",
                                                                   content = d3.array.base))
  
  ## Insert the Default order of the rows and columns
  seq.number <- paste(1:col.nb, collapse = ",")
  motif.number <- paste(1:row.nb, collapse = ",")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--col_order_default--",
                                                                   content = seq.number))
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--row_order_default--",
                                                                   content = motif.number))
  
  ## Insert the Column and Row names
  sequences.names.cat <- paste("'" , sequences.names, "'", sep = "")
  sequences.names.cat <- paste(sequences.names.cat, collapse = ", ")
  motifs.names.cat <- paste("'" , motifs.names, "'", sep = "")
  motifs.names.cat <- paste(motifs.names.cat, collapse = ", ")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--col_names--",
                                                                   content = sequences.names.cat))
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--row_names--",
                                                                   content = motifs.names.cat))
  
  ## Insert the TSV file
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--file--",
                                                                   content = shortpath.maxNWD.tsv))
  
  ## Div bottom + Cell size
  cell.size <- 30
  bottom <- 120
  legend.header <- bottom - 35
  if(row.nb < 5){
    bottom <- 120
    legend.header <- bottom - 35
  } else if(row.nb < 8){
    bottom <- 170
    legend.header <- bottom - 35
  } else if(row.nb < 13){
    bottom <- 220
    cell.size <- 20
    legend.header <- bottom - 27
  } else if(row.nb < 18){
    bottom <- 270
    cell.size <- 15
    legend.header <- bottom - 27
  }
  
  ## Set the cell size
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--cell_size--",
                                                                   content = as.character(cell.size)))
  
  ## Left space
  left <- (max(as.vector(sapply(c(sequences.names, motifs.names), nchar))) + 2.5) * 10
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--left--",
                                                                   content = as.character(left)))
  
  ## D3 path
  D3 <- "d3js.org/d3.v3.min.js"

  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--d3--",
                                                                   content = D3))
  
  ## Body size
  html.body.size <- 250 + left + (col.nb*cell.size)
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--body--",
                                                                   content = as.character(html.body.size)))
  
  ## Calculate the legend names for the color scale
  # stp <- (max(max.NWD.table) - min(max.NWD.table))/9
  # legend.domain.values <- seq(from = min(max.NWD.table), to = max(max.NWD.table), by = 0.05)
  # limit <- max(abs(c(min(max.NWD.table), max(max.NWD.table))))
  # limit <- round(limit, digits = 1)
  # legend.domain.values <- seq( (min(max.NWD.table) - 0.2), limit, by = 0.05)
  
  ## Remove noisy extremities
  tab.range <- range(tab)
  tab.range.abs <- abs(tab.range)
  
  if (tab.range.abs[1] > tab.range.abs[2]){
    tab.range[2] <- -tab.range[1]
  } else {
    tab.range[1] <- -tab.range[2]
  }
  
  legend.domain.values <- quantile(tab.range, probs = seq(0, 1, 0.1))
  legend.length <- length(legend.domain.values)
  legend <- legend.domain.values
  legend <- round(legend, digits = 3)
  legend <- paste(rev(legend), collapse = ",")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--data_legend--",
                                                                   content = legend))
  
  ## Create Gradient Hexadecimal:
  ## Given X hexa colors creates a color
  palette.hexa <- colorRampPalette(brewer.pal(heatmap.color.classes, heatmap.color.palette), space="Lab")(11)
  palette.hexa <- rev(palette.hexa)
  
  palette <- paste("'" , palette.hexa, "'", sep = "")
  palette <- paste(palette, collapse = ", ")
  
  palette.rev <- paste("'" , rev(palette.hexa), "'", sep = "")
  palette.rev <- paste(palette.rev, collapse = ", ")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--gradient--",
                                                                   content = palette))
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--gradient_rev--",
                                                                   content = palette.rev))
  
  ## Color domain
  domain <- legend.domain.values[1:(legend.length-1)]
  domain <- paste(domain, collapse = ",")
  
  fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--domain--",
                                                                   content = domain))


#################################################
## Draw the Binomial ocurrence enrichment plot ##
#################################################

##########################
## Initialize variables
# binomial.occ.file <- "/home/jamondra/Downloads/results_me_A7_LEF1_HUMAN_H11MO_0_A_occ_proba_LEF1_HUMAN_H11MO_0_A_compare-scores.tab"
all.IDs <- NULL
# all.names <- all.profiles ## Remember!
hash.profile.ID <- list()
plot.names <- NULL
ID.counter <- 0
x.x <- NULL
y.y <- NULL 
line.w <- 5
all.profiles.max.occ <- vector()

base.name <- basename(prefix)
dir.name <- dirname(prefix)

## Get sequences names
Sequences <- unlist(strsplit(Sequences, "---", perl = TRUE))

## Get TF names
TFs <- unlist(strsplit(TFs, "---", perl = TRUE))

prof <- as.vector(outer(Sequences, TFs, paste))
all.profiles <<- as.vector(sapply(prof, function(p){gsub(" ", "_", p)}))
# pdf.file <- paste(prefix, "_Binomial_occ_plots.pdf", sep = "")
# pdf(pdf.file )
for(TF in TFs){
  
  ## Read Binomial OCC table
  binomial.occ.file <- paste(dir.name, "/", TF, "/", base.name, "_", TF, "_occ_proba_", TF,"_compare-scores.tab", sep = "")
  binomial.occ.tab <- read.csv(binomial.occ.file, header = TRUE, sep = "\t")
  
  ## Assign a color to each sequence set
  col.nb <- dim(binomial.occ.tab)[2]
  colors <- colorRampPalette(brewer.pal(5, "Set1"), space="Lab")(col.nb-1)
  
  old.names <- names(binomial.occ.tab)
  names(binomial.occ.tab) <- c("values", as.character(2:col.nb))
  
  ## Convert the <NULL> values (coming from previous steps) to NA
  ## in order to have a numeric vector
  binomial.occ.tab.cp <- apply(binomial.occ.tab, 2, function(x){
    
    x <- as.vector(x)
    x <- as.numeric(gsub("<NULL>", NA, x))
    x
  })
  
  calculate.max.y <- max(binomial.occ.tab.cp[,2:col.nb], na.rm = TRUE)
  calculate.min.y <- min(binomial.occ.tab.cp[,2:col.nb], na.rm = TRUE)
  
  x <- binomial.occ.tab.cp[,1]
  y <- binomial.occ.tab.cp[,2]
  
  ## X-axis values scaled at -log10
  x <- -log10(x)
  
  ## Plot the Binomial OCC separately of each TF
  # plot(x,y, 
  #      type = "l", 
  #      col = colors[1],
  #      main = paste("Binomial OCC", TF, sep = " "),
  #      ylim = c(calculate.min.y - 1, calculate.max.y + 1),
  #      lwd = 2,
  #      xlab = "P-value",
  #      ylab = "Binomial OCC significance"
  # )
  # 
  # ## Add the lines only if there are 2 or more sequences
  # ## The first sequences is in column 2.
  # if(col.nb > 2){
  #   for(c in 3:col.nb){
  #     lines(x = x, y = binomial.occ.tab.cp[,c],
  #           type = "l", 
  #           col = colors[c-1],
  #           lwd = 2)
  #   }
  # }
  # legend("topright", Sequences, fill = colors, cex = 0.75)
  
  
  ## When only one set of sequences is used R converts it to a vector, then the program dies.
  ## So the vector should be converted in a data.frame
  max.occ <- apply(as.data.frame(binomial.occ.tab.cp[,2:col.nb]), 2, function(m){ max(m, na.rm = TRUE)})
  names(max.occ) <- paste(TF, Sequences, sep = "_")
  all.profiles.max.occ <<- append(all.profiles.max.occ, max.occ)
  
  ################################
  ## Prepare C3 html fields     
  ## (Before create the report) 
  
  ## Define all profiles of the current TF
  set.profiles <- paste(TF, "_", Sequences, sep = "")
  
  ## Set colors (one per profile)
  set.colors <- colorRampPalette(brewer.pal(10,"Paired"))(length(all.profiles))
  
  binomial.occ.tab <- binomial.occ.tab.cp
  binomial.occ.tab[,1] <- -log10(binomial.occ.tab.cp[,1])
  colnames(binomial.occ.tab) <- c("values", set.profiles)
  binomial.occ.tab <- t(binomial.occ.tab)
  
  ## Rename the columns
  colnames(binomial.occ.tab) <- binomial.occ.tab[1,]
  
  ## This step must be done when the sequences sets == 1
  ## Transpose the values
  if(nb.sets == 1){
    binomial.occ.tab <- t(data.frame(binomial.occ.tab[2:(length(set.profiles)+1),] )) 
  } else {
    binomial.occ.tab <- binomial.occ.tab[2:(length(set.profiles)+1),]
  }
  sub.tab.nb.col <- dim(as.data.frame(binomial.occ.tab))[1]
  
  ###################################################
  ## Get the X and Y data
  ## As there are some NA values, they are removed 
  ## from the data to draw them properly in C3
  
  thrash <- apply(as.data.frame(binomial.occ.tab), 1, function(values){
    
    ## Count the IDs
    ID.counter <<- ID.counter + 1
    
    ## Here we create a unique ID without CSS special characters
    ## Only to manipulate the objects in the HTML form
    ID <- all.profiles[ID.counter]
    ID <- gsub("_", "", ID)
    ID <- gsub("_", "", ID)
    ID <- gsub("-", "", ID)
    ID <- gsub("\\.", "", ID)
    ID <- gsub(":", "", ID)
    ID <- gsub("\\s+", "", ID, perl = TRUE)
    ID <- paste(ID.counter, ID, ID.counter, sep = "") 
    
    hash.profile.ID[[all.profiles[ID.counter]]] <<- ID
    all.IDs <<- append(all.IDs, ID)
    
    ## Create the name's data for the HTML file
    ## The name correspond to the motif name. 
    ## Note that two motifs for the same TF will have the same name and this name will appears twice 
    ## in the report. However their IDs are unique.
    plot.names <<- append(plot.names, paste("'", ID, "' : '",  all.profiles[ID.counter],"',", sep = ""))
    
    ## PArse the values vector
    ## Only extract those positions without NA
    values.wo.NA <- values[which(values != "NA")]
    
    # Create the Y value
    y <- paste("['",
               ID,
               "',",
               paste(values.wo.NA,
                     collapse = ","),
               "],",
               sep = "")
    y.y <<- rbind(y.y, y)
    
    ## Add the X-value
    
    aaa <- as.numeric(names(values.wo.NA))
    aaa <- prettyNum(aaa, scientific=TRUE, digits = 6)
    
    
    x.x <<- rbind(x.x, paste("['x", ID.counter,"',", paste(aaa,collapse = ","), "],", sep = ""))
  })
}
# dev.off()

#############################
## Create the HTML c3 plot ##
#############################
reorder <- order(all.profiles.max.occ, decreasing = TRUE)
all.IDs <- all.IDs[reorder]
all.profiles <- all.profiles[reorder]
plot.names <- plot.names[reorder]

## Print Motif names array
html.names <- sapply(TFs, function(x){
  rep(x, times = length(Sequences))
})
html.names <- html.names[reorder]
html.names <- paste("Names['", all.IDs, "'] = '", html.names, "';", sep = "")
html.names <- paste(html.names, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--names_vector--",
                                                                 content = html.names))

## Print Sequence names array
html.seq <- rep(Sequences, times = length(Sequences))
#html.seq <- html.seq[reorder]
html.seq <- gsub("_\\w+", "", all.profiles, perl = TRUE)

html.seq <- paste("Seqs['", all.IDs, "'] = '", html.seq, "';", sep = "")
html.seq <- paste(html.seq, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--seqs--",
                                                                 content = html.seq))

## Write the logo's path
## for both orientations
## Each path is repeated N-times where N is the 
## number of sequences
logos.F <- sapply(TFs, function(i){
  paste(i, "/", base.name , "_", i, "_logo_m1.png", sep = "")
})
logos.F <- as.vector(logos.F)
logos.F <- sapply(logos.F, function(x){
  rep(x, times = length(Sequences))
})
logos.F <- logos.F[reorder]
logos.F <- paste("pics['", all.IDs, "'] = '", logos.F, "';", sep = "")
logos.F <- paste(logos.F, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--pics--",
                                                                 content = logos.F))


logos.R <- sapply(TFs, function(i){
  paste(i, "/", base.name , "_", i, "_logo_m1_rc.png", sep = "")
})
logos.R <- as.vector(logos.R)
logos.R <- sapply(logos.R, function(x){
  rep(x, times = length(Sequences))
})
logos.R <- logos.R[reorder]
logos.R <- paste("pics_rc['", all.IDs, "'] = '", logos.R, "';", sep = "")
logos.R <- paste(logos.R, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--pics_rc--",
                                                                 content = logos.R))


## Add the color code (one color per motif)
## They are inserted in the C3 section
colors <- colorRampPalette(brewer.pal(5, "Set1"), space="Lab")(length(all.IDs))
set.colors <- paste(paste("'", colors, "'", sep = ""), collapse = ",")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--color_pattern--",
                                                                 content = set.colors))

## CSS section to set the line width
## Note: the width is proportional cummulative sum of the profile (TO DO)
## For the moment, only a fixed value is working
line.w <- paste("#chart .c3-line-", all.IDs, "{ stroke-width: ", line.w, "px; }", sep = "")
line.w <- paste(line.w, collapse = "; ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--lines_w--",
                                                                 content = line.w))

## Add the TF_names data
TF.names <- paste("TF_names['", all.profiles, "'] = '", all.IDs, "';", sep = "")
TF.names <- paste(TF.names, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--TF_names--",
                                                                 content = TF.names))

## Add the TF_names data
tfs <- paste(paste("'", all.profiles, "'", sep = ""), collapse = ",")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--tfs--",
                                                                 content = tfs))


## Add the real motif IDs (to display in the tooltip)
## They are inserted in the JS section
## I called them 'real' because are those found on the original motif file
IDs <- paste("IDs['", all.IDs, "'] = '", all.profiles, "';", sep = "")
IDs <- paste(IDs, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--IDs--",
                                                                 content = IDs))

## The plot heigth depends in the number of motifs
motif.total <- length(all.profiles)
chart.heigth <- 500
if(motif.total >= 300){
  chart.heigth <- 700
} else if(motif.total >= 400){
  chart.heigth <- 900
}

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--chart_h--",
                                                                 content = as.character(chart.heigth)))

## Add xs values (one row per motif)
## They are inserted in the C3 section
# xs <- paste("'", all.IDs, "' : 'x", 1:ID.counter, "',", sep = "")
xs <- paste("'", all.IDs, "' : 'x", reorder, "',", sep = "")
xs <- paste(xs, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--xs--",
                                                                 content = xs))

## Add x values (one row per motif)
## They are inserted in the C3 section
x.x <- x.x[reorder]
y.y <- y.y[reorder]
x.x <- paste(x.x, collapse = "  ")
x.x <- gsub(",NA,", ",NaN,", x.x)
y.y <- paste(y.y, collapse = "  ")
y.y <- gsub(",NA,", ",NaN,", y.y)

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--x_x--",
                                                                 content = x.x))

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--y_y--",
                                                                 content = y.y))

## Insert the motif names
## They are inserted in the C3 section
plot.names <- paste(plot.names, collapse = " ")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--names--",
                                                                 content = plot.names))

## Insert the motif names (to hide/show all)
## They are inserted in the JQuery section
all.IDs <- paste(paste("'", all.IDs, "'", sep = ""), collapse = ",")

fields.to.fill.report <- rbind(fields.to.fill.report, data.frame(field = "--all--",
                                                                 content = all.IDs))

## Export the field table
write.table(fields.to.fill.report, file = fields.table, sep = "\t\t", quote = FALSE, row.names = FALSE, col.names = TRUE)