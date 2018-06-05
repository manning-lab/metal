# METAL -- Meta analysis

## Description 

This workflow performs a meta analysis of association results using the [METAL software](http://csg.sph.umich.edu/abecasis/metal/)

### Authors

This workflow is produced and maintained by the [Manning Lab](https://manning-lab.github.io/). Contributing authors include:

* Tim Majarian (tmajaria@broadinstitute.org)
* Alisa Manning (amanning@broadinstitute.org).

## Dependencies

### Workflow execution

* [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart)
* [Chromwell](http://cromwell.readthedocs.io/en/develop/)

### METAL (included in Docker image)

* [Metal - generic distribution](http://csg.sph.umich.edu/abecasis/metal/download/)

### R packages

* [data.table](https://cran.r-project.org/web/packages/data.table/index.html)
* [qqman](https://cran.r-project.org/web/packages/qqman/index.html)

### Docker images

* [Bioconductor](https://hub.docker.com/r/robbyjo/r-mkl-bioconductor/) - by Roby Joehanes (robbyjo@gmail.com)
* [METAL](https://hub.docker.com/r/tmajarian/metal/)

## Main Functions

### runMetal

This function generates the metal input script, processes each input results file, and runs the meta analysis

Inputs:
* result_files : an array of association results files, like those generated in the single variant association pipeline (Array[File], .csv or .tsv)
* marker_column : column name in results_files with variant identifiers (string)
* weight_column : column name in results_files for weighting of variants (string)
* allele_effect_column : column name in results_files with effect allele (string)
* allele_non_effect_column : column name in results_files with non effect allele (string)
* freq_column : column in results_files with variant frequency (string)
* pval_column : column in results_files with variant p-value (string)
* effect_column : column in results_files with variant effect (string)
* out_pref : prefix for output filename (string)
* separator : character that separates each input result file (default: COMMA; WHITESPACE, TAB)
* analyze_arg : optional argument for other types of analyses (default: ZSCORE)

Outputs:
* result_file : results per variant for all variants tested (.TBL)
* metal_script : script that was generated as input to METAL (script.txt)
* log_file : log file capturing standard error of running METAL (.log)

### metalSummary

This function generates the metal input script, processes each input results file, and runs the meta analysis

Inputs:
* marker_column : column name in results_files with variant identifiers (string)
* freq_column : column in results_files with variant frequency (string)
* pval_column : column in results_files with variant p-value (string)
* sample_column : column in results_files with number of samples (string)
* cols_tokeep : comma separated list of columns in each association results file (string)
* assoc_names : comma separated list of association analysis names, one corresponding to each input result file (string)
* out_pref : prefix for output filename (string)
* metal_file : output of runMetal task (File)
* result_files : an array of association results files, like those generated in the 

Outputs:
* csv : a comma separated file of results including METAL results and "cols_tokeep" from each input results file (.csv)
* plots : quantile-quantile and manhattan plots subset by MAF (all, <5%, >=5%) for meta-analysis p-values (.png)

## Other workflow inputs

* this_memory : amount of memory in GB for each execution of a task (int)
* this_disk : amount of disk space in GB to allot for each execution of a task (int)



