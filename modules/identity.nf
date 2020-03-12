process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(f1), file(f1)

			output:
			file "*"

			script: 
			"""
            touch ${f1}
			//echo 'test' >> ${f1}
			"""
		}