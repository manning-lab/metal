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

# Load packages
lapply(c("qqman","data.table","tools","RColorBrewer"), library, character.only = TRUE)

# Parse inputs
input_args <- commandArgs(trailingOnly=T)
marker.column <- input_args[1]
pval.column <- input_args[2]
sample.column <- input_args[3]
out.pref <- input_args[4]
metal.file <- input_args[5]
assoc.files <- unlist(strsplit(input_args[6],","))
pval.thresh <- as.numeric(input_args[7])

freq.column <- "MAF"

######### test inputs #################
# marker.column <- "snpID"
# pval.column <- "Score.pval"
# sample.column <- "n"
# out.pref <- "demo"
# metal.file <- "demo1.tsv"
# assoc.files <- c("demo.1.assoc.csv","demo.2.assoc.csv")
######################################

# define names for each input analysis
assoc.names <- unlist(lapply(assoc.files, function(x) file_path_sans_ext(basename(x)) ))

# load metal results
metal.data <- fread(metal.file,data.table=F)

# names to keep later on
names.to.keep <- names(metal.data)

# load individual results and merge
for (f in seq(1,length(assoc.files))){
  assoc.data <- fread(assoc.files[f],data.table=F)
  names(assoc.data)[names(assoc.data) != marker.column] = paste(names(assoc.data)[names(assoc.data) != marker.column], assoc.names[f], sep = ".")
  metal.data <- merge(metal.data, assoc.data, by.x = "MarkerName", by.y = marker.column, all.x=TRUE)
}

# get the position and chromosome columns for manhatten
metal.data$pos <- unlist(apply(metal.data[,names(metal.data)[startsWith(names(metal.data), "pos")]], 1, function(x) unique(x[!is.na(x)])[1]))
metal.data$chr <- unlist(apply(metal.data[,names(metal.data)[startsWith(names(metal.data), "chr")]], 1, function(x) unique(x[!is.na(x)])[1]))

# remove unneeded columns
names.to.keep <- c(names.to.keep, "pos", "chr", names(metal.data)[startsWith(names(metal.data),"n.")], names(metal.data)[startsWith(names(metal.data),"MAF")], names(metal.data)[startsWith(names(metal.data),pval.column)])
metal.data <- metal.data[,names(metal.data)[names(metal.data) %in% names.to.keep]]

# order based on meta pvalue
metal.data <- metal.data[order(metal.data[,"P-value"]),]

# calculate full sample mac for each variant
all_mac <- c()
for (n in assoc.names){
  all_mac <- cbind(all_mac, 2 * metal.data[,paste(sample.column,".",n,sep="")] * metal.data[,paste(freq.column,".",n,sep="")] )
}
metal.data$total_maf <- rowSums(all_mac)/(2*metal.data$Weight)

# change marker sep
metal.data$MarkerName <- gsub("-",":",metal.data$MarkerName)

# write results out to file
fwrite(metal.data[which(metal.data[,"P-value"] < pval.thresh),], file = paste0(out.pref,".METAL.top.assoc.csv"), sep=",")
fwrite(metal.data, file = paste0(out.pref,".METAL.assoc.csv"), sep=",")

## Plotting ##

# calculate genomic control 
lam = function(x,p=.5){
  x = x[!is.na(x)]
  chisq <- qchisq(1-x,1)
  round((quantile(chisq,p)/qchisq(p,1)),2)
}

# qq plot
qqpval2 = function(x, main="", col="black"){
  x<-sort(-log(x[x>0],10))
  n<-length(x)
  plot(x=qexp(ppoints(n))/log(10), y=x, xlab="Expected", ylab="Observed", main=main ,col=col ,cex=.8, bg= col, pch = 21)
  abline(0,1, lty=2)
}

# qq without identity line
qqpvalOL = function(x, col="blue"){
  x<-sort(-log(x[x>0],10))
  n<-length(x)
  points(x=qexp(ppoints(n))/log(10), y=x, col=col, cex=.8, bg = col, pch = 21)
}

# get the right colors
cols <- brewer.pal(8,"Dark2")

# qq plot
png(filename = paste0(out.pref,".plots.png"),width = 11, height = 11, units = "in", res=400)#, type = "cairo")
layout(matrix(c(1,2,3,3),nrow=2,byrow = T))

qqpval2(metal.data[,"P-value"], col=cols[8])
legend('topleft',c(paste0('GC = ',lam(metal.data[,"P-value"]))),col=c(cols[8]),pch=c(21))

qqpval2(metal.data[metal.data$total_maf >= 0.05, "P-value"],col=cols[1])
qqpvalOL(metal.data[metal.data$total_maf < 0.05, "P-value"],col=cols[2])
legend('topleft',c(paste0('GC (MAF >= 5%) = ',lam(metal.data[metal.data$total_maf >= 0.05, "P-value"])),
                   paste0('GC (MAF < 5%) = ',lam(metal.data[metal.data$total_maf < 0.05, "P-value"]))),
                   col=c(cols[1],cols[2]),pch=c(21,21))
manhattan(metal.data,chr="chr",bp="pos",p="P-value", main="All variants")

dev.off()
