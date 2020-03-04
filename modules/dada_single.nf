process dada_single {
		tag "$trunc"
		publishDir "${params.outdir}", mode: 'copy',
			saveAs: {filename -> 
					 if (filename.indexOf("dada_stats/stats.tsv") == 0)         "abundance_table/unfiltered/dada_stats.tsv"
				else if (filename.indexOf("dada_report.txt") == 0)              "abundance_table/unfiltered/dada_report.txt"
				else if (filename.indexOf("table.qza") == 0)                    "abundance_table/unfiltered/$filename"
				else if (filename.indexOf("rel-table/feature-table.biom") == 0) "abundance_table/unfiltered/rel-feature-table.biom"
				else if (filename.indexOf("table/feature-table.biom") == 0)     "abundance_table/unfiltered/feature-table.biom"
				else if (filename.indexOf("rel-feature-table.tsv") > 0)         "abundance_table/unfiltered/rel-feature-table.tsv"
				else if (filename.indexOf("feature-table.tsv") > 0)             "abundance_table/unfiltered/feature-table.tsv"
				else if (filename.indexOf("rep-seqs.qza") == 0)                 "representative_sequences/unfiltered/rep-seqs.qza"
				else if (filename.indexOf("unfiltered/*"))                      "representative_sequences/$filename"
				else null}

		input:
		file demux
		val trunc
		env MATPLOTLIBRC

		output:
		file("table.qza")
		file("rep-seqs.qza")
		file("table/feature-table.tsv") 
		file("dada_stats/stats.tsv")
		file("table/feature-table.biom")
		file("rel-table/feature-table.biom")
		file("table/rel-feature-table.tsv")
		file("unfiltered/*")
		file("dada_report.txt")

		when:
		!params.untilQ2import

		script:
		def values = trunc.split(',')
		if (values[0].toInteger() + values[1].toInteger() <= 10) { 
			log.info "\n######## ERROR: Total read pair length is below 10, this is definitely too low.\nForward ${values[0]} and reverse ${values[1]} are chosen.\nPlease provide appropriate values for --trunclenf and --trunclenr or lower --trunc_qmin\n" }
		"""
		IFS=',' read -r -a trunclen <<< \"$trunc\"

		#denoise samples with DADA2 and produce
		qiime dada2 denoise-paired  \
			--i-demultiplexed-seqs ${demux}  \
			--p-trunc-len-f \${trunclen[0]} \
			--p-trunc-len-r \${trunclen[1]} \
			--p-n-threads 0  \
			--o-table table.qza  \
			--o-representative-sequences rep-seqs.qza  \
			--o-denoising-stats stats.qza \
			--verbose \
		>dada_report.txt

		#produce dada2 stats "dada_stats/stats.tsv"
		qiime tools export --input-path stats.qza \
			--output-path dada_stats

		#produce raw count table in biom format "table/feature-table.biom"
		qiime tools export --input-path table.qza  \
			--output-path table

		#produce raw count table
		biom convert -i table/feature-table.biom \
			-o table/feature-table.tsv  \
			--to-tsv

		#produce representative sequence fasta file
		qiime feature-table tabulate-seqs  \
			--i-data rep-seqs.qza  \
			--o-visualization rep-seqs.qzv
		qiime tools export --input-path rep-seqs.qzv  \
			--output-path unfiltered

		#convert to relative abundances
		qiime feature-table relative-frequency \
			--i-table table.qza \
			--o-relative-frequency-table relative-table-ASV.qza

		#export to biom
		qiime tools export --input-path relative-table-ASV.qza \
			--output-path rel-table

		#convert to tab separated text file
		biom convert \
			-i rel-table/feature-table.biom \
			-o table/rel-feature-table.tsv --to-tsv
		"""
	}