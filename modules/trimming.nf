process trimming {
			tag "${pair_id}"  
			publishDir "${params.outdir}/trimmed", mode: 'copy',
				saveAs: {filename -> 
				if (filename.indexOf(".gz") == -1) "logs/$filename"
				else if(params.keepIntermediates) filename 
				else null}
		
			input:
			set val(pair_id), file(reads)
		
			output:
			file "trimmed/*.*" set { ch_trimmed_reads }
			file "cutadapt_log_*.txt"

			script:
			discard_untrimmed = params.retain_untrimmed ? '' : '--discard-untrimmed'
			"""
			mkdir -p trimmed
			cutadapt -g ${params.FW_primer} -G ${params.RV_primer} ${discard_untrimmed} \
				-o trimmed/${reads[0]} -p trimmed/${reads[1]} \
				${reads[0]} ${reads[1]} > cutadapt_log_${pair_id}.txt
			"""
		}