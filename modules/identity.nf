process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(f1), file(f1)

			output:
			file "${f1}"

			script: 
			"""
            echo ${f1}
			"""
		}