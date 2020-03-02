process fastqc {
			tag "${pair_id}"
			publishDir "${params.outdir}/fastQC", mode: 'copy',
			saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

			input:
			set val(pair_id), file(reads)

			output:
			file "*_fastqc.{zip,html}"

			when:
			!params.skip_fastqc

			script: 
			"""
			fastqc -q ${reads}
			"""
		}