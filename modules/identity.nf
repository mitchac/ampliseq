process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(i1), file(i2)

			output:
			//file "${i1}"
            //file "${i2}"

			script: 
			"""
            echo ${i2[0]}
            echo ${i2}
			"""
		}