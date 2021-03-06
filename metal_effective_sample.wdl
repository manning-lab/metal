# Main task for meta analysis
task runMetal {
	Array[File] assoc_files
	String? marker_column
	Array[Int] effective_sample
	String? allele_effect_column
	String? allele_non_effect_column
	String? pval_column
	String? effect_column
	String out_pref
	String? separator
	String? analyze_arg

	Int memory
	Int disk

	command {
		echo "# this is your metal input file" > script.txt
		echo "MARKER ${default='MarkerName' marker_column}" >> script.txt
		echo "ALLELE ${default='alt' allele_effect_column} ${default='ref' allele_non_effect_column}" >> script.txt
		echo "FREQ MAF" >> script.txt
		echo "AVERAGEFREQ ON" >> script.txt
		echo "PVAL ${default='pvalue' pval_column}" >> script.txt
		echo "EFFECT ${default='Score.Stat' effect_column}" >> script.txt
		echo "SEPARATOR ${default= 'COMMA' separator}" >> script.txt
		echo "COLUMNCOUNTING LENIENT " >> script.txt
		set ${sep=" " assoc_files}
		for i in ${sep=" " effective_sample}; do
			echo DEFAULTWEIGHT "$i" >> script.txt
	        echo PROCESS "$1" >> script.txt
	        shift
	    done
		echo "OUTFILE ${default='metal' out_pref} .tsv" >> script.txt
		echo "ANALYZE ${default='' analyze_arg}" >> script.txt
		metal script.txt > "${out_pref}.log"
	}

	runtime {
		docker: "manninglab/metal:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory} GB"
	}

	output {
		File result_file = "${out_pref}1.tsv"
		File metal_script = "script.txt"
		File log_file = "${out_pref}.log"
		File info_file = "${out_pref}1.tsv.info"
	}
}

# Summarization of meta analysis results
task metalSummary {
	String? marker_column 
	String? pval_column 
	String? sample_column
	String out_pref
	File metal_file
	Array[File] assoc_files
	Float? pval_thresh

	Int disk
	Int memory
	
	command {
		R --vanilla --args ${default="MarkerName" marker_column} ${default="Score.pval" pval_column} ${default="n" sample_column} ${out_pref} ${metal_file} ${sep="," assoc_files} ${default="0.0001" pval_thresh} < /metal/metal_summary.R
	}

	runtime {
		docker: "manninglab/metal:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory} GB"
	}

	output {
		File csv = "${out_pref}.METAL.assoc.csv"
		File top_csv = "${out_pref}.METAL.top.assoc.csv"
		File plots = "${out_pref}.plots.png"
	}
}

# Workflow to run meta analysis and summary
workflow w_metal {
	# inputs
	Array[File] these_assoc_files
	Array[Int] these_effective_sample
	String? this_marker_column
	String? this_sample_column
	String? this_allele_effect_column
	String? this_allele_non_effect_column
	String? this_pval_column
	String? this_effect_column
	String this_out_pref
	String? this_separator
	String? this_analyze_arg
	String? this_pval_thresh

	# other inputs
	Int this_memory
	Int this_disk

	call runMetal {
		input: assoc_files = these_assoc_files, marker_column = this_marker_column, effective_sample = these_effective_sample, allele_effect_column = this_allele_effect_column, allele_non_effect_column = this_allele_non_effect_column, pval_column = this_pval_column, effect_column = this_effect_column, out_pref = this_out_pref, separator = this_separator, analyze_arg = this_analyze_arg, memory = this_memory, disk = this_disk
		
	}

	call metalSummary {
		input: marker_column = this_marker_column, pval_column = this_pval_column, sample_column = this_sample_column, out_pref = this_out_pref, metal_file = runMetal.result_file, assoc_files = these_assoc_files, pval_thresh = this_pval_thresh, disk = this_disk, memory = this_memory
	}
}
