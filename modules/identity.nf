process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple i1, i2, i3, i4

			output:
			//file "${f1}"
            //file "${f2}"

			script: 
			"""
            #echo ${f1[0]}
            #echo ${f2[0]}
			"""
		}