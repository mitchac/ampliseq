process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(i1[0]), file(i2), file(i3), file(i4)

			output:
			//file "${f1}"
            //file "${f2}"

			script: 
			"""
            echo ${i1}
			"""
		}