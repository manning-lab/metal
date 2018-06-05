task getScript {
	command {
		wget https://raw.githubusercontent.com/manning-lab/topmed-t2d-glycemia-public/master/workflows/metal/metal_summary.R
	}

	runtime {
		docker: "tmajarian/alpine_wget@sha256:f3402d7cb7c5ea864044b91cfbdea20ebe98fc1536292be657e05056dbe5e3a4"
	}

	output {
		File script = "metal_summary.R"
	}
}

task metalSummary {
	String marker_column 
	String freq_column 
	String pval_column 
	String sample_column
	String cols_tokeep 
	String assoc_names
	String out_pref
	File metal_file 
	Array[File] result_files

	Int disk
	Int memory

	File script
	
	command {
		R --vanilla --args ${marker_column} ${freq_column} ${pval_column} ${sample_column} ${cols_tokeep} ${assoc_names} ${out_pref} ${metal_file} ${sep="," result_files} < ${script}
	}

	runtime {
		docker: "robbyjo/r-mkl-bioconductor@sha256:b88d8713824e82ed4ae2a0097778e7750d120f2e696a2ddffe57295d531ec8b2"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File csv = "${out_pref}_all.csv"
		File plots = "${out_pref}_all_plots.png"
	}
}

task runMetal {
	Array[File] result_files
	String marker_column
	String weight_column
	String allele_effect_column
	String allele_non_effect_column
	String freq_column
	String pval_column
	String effect_column
	String out_pref
	String? separator
	String? analyze_arg

	Int memory
	Int disk

	command {
		echo "# this is your metal out_file" > script.txt
		echo "MARKER ${marker_column}" >> script.txt
		echo "WEIGHT ${weight_column}" >> script.txt
		echo "ALLELE ${allele_effect_column} ${allele_non_effect_column}" >> script.txt
		echo "FREQ ${freq_column}" >> script.txt
		echo "PVAL ${pval_column}" >> script.txt
		echo "EFFECT ${effect_column}" >> script.txt
		echo "SEPARATOR ${default= "COMMA" separator}" >> script.txt
		echo "COLUMNCOUNTING LENIENT " >> script.txt
		echo "PROCESS ${sep = "\nPROCESS " result_files}" >> script.txt
		echo "OUTFILE ${out_pref} .TBL" >> script.txt
		echo "ANALYZE ${default="" analyze_arg}" >> script.txt
		metal script.txt > "${out_pref}.log"
	}

	runtime {
		docker: "tmajarian/metal@sha256:27e2c3189cff9c974d814a3ea3968330160d068b98e7d53dec85c098e5c57c1a"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File result_file = "${out_pref}1.TBL"
		File metal_script = "script.txt"
		File log_file = "${out_pref}.log"
	}
}

workflow w_metal {
	# runMetal inputs
	Array[File] these_result_files
	String this_marker_column
	String this_weight_column
	String this_allele_effect_column
	String this_allele_non_effect_column
	String this_freq_column
	String this_pval_column
	String this_effect_column
	String this_out_pref
	String? this_separator
	String? this_analyze_arg

	# metalSummary inputs
	String this_sample_column
	String this_cols_tokeep 
	String this_assoc_names	

	# other inputs
	Int this_memory
	Int this_disk

	call getScript 

	call runMetal {
		input: result_files = these_result_files, marker_column = this_marker_column, weight_column = this_weight_column, allele_effect_column = this_allele_effect_column, allele_non_effect_column = this_allele_non_effect_column, freq_column = this_freq_column, pval_column = this_pval_column, effect_column = this_effect_column, out_pref = this_out_pref, separator = this_separator, analyze_arg = this_analyze_arg, memory = this_memory, disk = this_disk
		
	}

	call metalSummary {
		input: marker_column = this_marker_column, freq_column = this_freq_column, pval_column = this_pval_column, sample_column = this_sample_column, cols_tokeep = this_cols_tokeep, assoc_names = this_assoc_names, out_pref = this_out_pref, metal_file = runMetal.result_file, result_files = these_result_files, disk = this_disk, memory = this_memory, script = getScript.script
	}
}