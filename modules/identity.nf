process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			set i1

			output:
			//file "${i1}"
            //file "${i2}"

			script: 
			"""
            echo ${i1[1][0]}
            echo ${i1[1][1]}
			"""
		}