process identity {
			publishDir "${params.outdir}/identity", mode: 'copy'
			
			input:
			tuple file(f1), file(f2), file(f3), file(f4), file(f5), file(f6)

			output:
			file "${f1}"
            file "${f2}"
            file "${f3}"

			script: 
			"""
            echo ${f1}
            echo ${f2}
            echo ${f3}
            echo ${f4}
            echo ${f5}
            echo ${f6}
			"""
		}