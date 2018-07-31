# Main task for meta analysis
task runMetal {
	Array[File] assoc_files
	String? marker_column
	String? sample_column
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
		echo "WEIGHT ${default='n' sample_column}" >> script.txt
		echo "ALLELE ${default='alt' allele_effect_column} ${default='ref' allele_non_effect_column}" >> script.txt
		echo "FREQ MAF" >> script.txt
		echo "AVERAGEFREQ ON" >> script.txt
		echo "PVAL ${default='pvalue' pval_column}" >> script.txt
		echo "EFFECT ${default='Score.Stat' effect_column}" >> script.txt
		echo "SEPARATOR ${default= 'COMMA' separator}" >> script.txt
		echo "COLUMNCOUNTING LENIENT " >> script.txt
		echo "PROCESS ${sep = '\nPROCESS ' assoc_files}" >> script.txt
		echo "OUTFILE ${default='metal' out_pref} .tsv" >> script.txt
		echo "ANALYZE ${default='' analyze_arg}" >> script.txt
		dstat -c -d -m --nocolor 10 1>runMetal_out.log &
		metal script.txt > "${out_pref}.log"
	}

	runtime {
		docker: "manninglab/metal:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File result_file = "${out_pref}1.tsv"
		File metal_script = "script.txt"
		File log_file = "${out_pref}.log"
		File info_file = "${out_pref}1.tsv.info"
		File dstat_log = "runMetal_out.log"
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
		dstat -c -d -m --nocolor 10 1>metalSummary_out.log &
		R --vanilla --args ${default="MarkerName" marker_column} ${default="Score.pval" pval_column} ${default="n" sample_column} ${out_pref} ${metal_file} ${sep="," assoc_files} ${default="0.0001" pval_thresh} < /metal/metal_summary.R
	}

	runtime {
		docker: "manninglab/metal:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File csv = "${out_pref}.METAL.assoc.csv"
		File top_csv = "${out_pref}.METAL.top.assoc.csv"
		File plots = "${out_pref}.plots.png"
		File dstat_log = "metalSummary_out.log"
	}
}

# Workflow to run meta analysis and summary
workflow w_metal {
	# inputs
	Array[File] these_assoc_files
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
		input: assoc_files = these_assoc_files, marker_column = this_marker_column, sample_column = this_sample_column, allele_effect_column = this_allele_effect_column, allele_non_effect_column = this_allele_non_effect_column, pval_column = this_pval_column, effect_column = this_effect_column, out_pref = this_out_pref, separator = this_separator, analyze_arg = this_analyze_arg, memory = this_memory, disk = this_disk
		
	}

	call metalSummary {
		input: marker_column = this_marker_column, pval_column = this_pval_column, sample_column = this_sample_column, out_pref = this_out_pref, metal_file = runMetal.result_file, assoc_files = these_assoc_files, pval_thresh = this_pval_thresh, disk = this_disk, memory = this_memory
	}
}
