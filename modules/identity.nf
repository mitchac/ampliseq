process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(f1), file(f2)

			output:
			//file "${f1}"
            //file "${f2}"

			script: 
			"""
            echo ${f1}
            echo ${f2}
			"""
		}