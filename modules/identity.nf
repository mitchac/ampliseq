process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'}"
			
			input:
			tuple file(f1), file(f1)

			output:
			file "*"

			script: 
			"""
			cat ${f1} >> ${f1}
			"""
		}