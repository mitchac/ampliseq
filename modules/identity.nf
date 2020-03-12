process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			file(f1[0])

			output:
			//file "${f1}"
            //file "${f2}"

			script: 
			"""
            //echo ${f1[0]}
            //echo ${f2[0]}
			"""
		}