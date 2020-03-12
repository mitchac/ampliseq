process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			set 1,2,3,4

			output:
			//file "${f1}"
            //file "${f2}"

			script: 
			"""
            //echo ${f1[0]}
            //echo ${f2[0]}
			"""
		}