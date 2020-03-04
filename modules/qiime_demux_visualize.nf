process qiime_demux_visualize {
		tag "${demux.baseName}"
		publishDir "${params.outdir}", mode: 'copy'

		input:
		file(demux)
        env(MATPLOTLIBRC)

		output:
		file("${demux.baseName}/*-seven-number-summaries.csv")
		file("${demux.baseName}/*")
	  
		"""
		qiime demux summarize \
		--i-data ${demux} \
		--o-visualization ${demux.baseName}.qzv

		qiime tools export --input-path ${demux.baseName}.qzv --output-path ${demux.baseName}
		"""
	}