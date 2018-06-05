### metal_summary.R
# Description: This function generates the metal input script, processes each input results file, and runs the meta analysis
# Inputs:
# marker.column : column name in results_files with variant identifiers (string)
# freq.column : column in results_files with variant frequency (string)
# pval.column : column in results_files with variant p-value (string)
# sample.column : column in results_files with number of samples (string)
# cols.tokeep : comma separated list of columns in each association results file (string)
# assoc.names : comma separated list of association analysis names, one corresponding to each input result file (string)
# out.pref : prefix for output filename (string)
# metal.file : output of runMetal task (File)
# result.files : comma separated list of result files to summarize, these are the csv outputs of the single variant association pipeline (string)

# Outputs:
# csv : a comma separated file of results including METAL results and "cols_tokeep" from each input results file (.csv)
# plots : quantile-quantile and manhattan plots subset by MAF (all, <5%, >=5%) for meta-analysis p-values (.png)

# Check if required packages are installed (sourced from https://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them)
packages <- c("qqman","data.table")
to_install <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(to_install)) install.packages(to_install,repos='http://cran.us.r-project.org')

# Load packages
lapply(packages, library, character.only = TRUE)

# Parse inputs
input_args <- commandArgs(trailingOnly=T)
marker.column <- input_args[1]
freq.column <- input_args[2]
pval.column <- input_args[3]
sample.column <- input_args[4]
cols.tokeep <- unlist(strsplit(input_args[5],","))
assoc.names <- unlist(strsplit(input_args[6],","))
out.pref <- input_args[7]
metal.file <- input_args[8]
assoc.files <- unlist(strsplit(input_args[9],","))

# if you provide less names than the number of assoc files, use arbitrary names
if (length(assoc.names) < length(assoc.files)){
  assoc.names = as.character(seq(1,length(assoc.files)))
}

# load metal results
metal.data <- fread(metal.file,data.table=F)

for (f in seq(1,length(assoc.files))) {
  assoc.data <- fread(assoc.files[f],data.table=F)[,c(marker.column, cols.tokeep, freq.column, pval.column, sample.column)]
  if (f == 1){
    assoc.data.all = assoc.data[,c(marker.column, cols.tokeep, freq.column, pval.column, sample.column)]
    colnames(assoc.data.all)[which(colnames(assoc.data.all) %in% c(freq.column, pval.column, sample.column))] <- paste(c(freq.column, pval.column, sample.column),assoc.names[f],sep=".")
  } else {
    names(assoc.data)[names(assoc.data) %in% c(freq.column, pval.column, sample.column)] <- paste(names(assoc.data)[names(assoc.data) %in% c(freq.column, pval.column, sample.column)],".",assoc.names[f],sep = "")
    assoc.data.all <- merge(assoc.data.all, assoc.data, by=c(marker.column,cols.tokeep),all=T)
  }
}

metal.data <- merge(metal.data,assoc.data.all,by.x=c("MarkerName"), by.y=marker.column,all.x=T)


# order based on meta pvalue
metal.data = metal.data[order(metal.data[,"P-value"]),]

# calculate full sample mac for each variant
all_mac <- c()
for (n in assoc.names){
  all_mac <- cbind(all_mac, 2 * metal.data[,paste(sample.column,".",n,sep="")] * metal.data[,paste(freq.column,".",n,sep="")] )
}
metal.data$total_maf <- rowSums(all_mac)/(2*metal.data$Weight)

# subset back to only the cols we want
cols_to_save <- colnames(metal.data)[! (colnames(metal.data) %in% sub("$", paste("_", sample.column, sep=""), assoc.names))]

# write results out to file
fwrite(metal.data[,cols_to_save], file = paste(out.pref,"_all.csv",sep=""), sep=",")

png(filename = paste(out.pref,"_all_plots.png",sep=""),width = 11, height = 11, units = "in", res=400, type = "cairo")
par(mfrow=c(3,3))
qq(metal.data[,"P-value"],main="All variants")
qq(metal.data[metal.data$total_maf>0.05,"P-value"],main="Variants with MAF>0.05")
qq(metal.data[metal.data$total_maf<=0.05,"P-value"],main="Variants with MAF<=0.05")
manhattan(metal.data,chr="chr",bp="pos",p="P-value", main="All variants")
manhattan(metal.data[metal.data$total_maf>0.05,],chr="chr",bp="pos",p="P-value", main="Variants with MAF>0.05")
manhattan(metal.data[metal.data$total_maf<=0.05,],chr="chr",bp="pos",p="P-value", main="Variants with MAF<=0.05")
dev.off()
