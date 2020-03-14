process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(i1), file(i2)

			output:
			//file "${i1}"
            //file "${i2}"

			script: 
			"""
            echo ${i1}
            echo ${i2}
			"""
		}