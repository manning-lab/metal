task summaryCSVMetal {
	File metal_file
	String out_pref
	Float? pval_thresh

	Int disk
	Int memory
	
	command {
		R --vanilla --args ${metal_file} ${out_pref} ${default="0.001" pval_thresh} < /metal/summaryCSVMetal.R
	}

	runtime {
		docker: "manninglab/metal:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File top_csv = "${out_pref}.METAL.top.assoc.csv"
		File plots = "${out_pref}.plots.png"
	}
}

workflow w_summaryCSVMetal {
	# inputs
	File metal_file
	String this_out_pref
	String? this_pval_thresh

	# other inputs
	Int this_memory
	Int this_disk

	call summaryCSVMetal {
		input: metal_file = metal_file, out_pref = this_out_pref, pval_thresh = this_pval_thresh, disk = this_disk, memory = this_memory
	}
}