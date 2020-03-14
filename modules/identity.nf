process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple key, file(files)

			output:
			//file "${i1}"
            //file "${i2}"

			script: 
			"""
            echo ${files[0]}
            echo ${files1]}
			"""
		}