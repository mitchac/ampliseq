Channel.fromPath("${params.reference_database}")
		.set { ch_ref_database }

	process make_SILVA_132_16S_classifier {
		publishDir "${params.outdir}/DB/", mode: 'copy', 
		saveAs: {filename -> 
			if (filename.indexOf("${params.FW_primer}-${params.RV_primer}-${params.dereplication}-classifier.qza") == 0) filename
			else if(params.keepIntermediates) filename 
			else null}

		input:
		file database from ch_ref_database
		env MATPLOTLIBRC from ch_mpl_for_make_classifier

		output:
		file("${params.FW_primer}-${params.RV_primer}-${params.dereplication}-classifier.qza") into ch_qiime_classifier
		file("*.qza")
		stdout ch_message_classifier_removeHash

		when:
		!params.onlyDenoising && !params.untilQ2import

		script:
	  
		"""
		unzip -qq $database

		fasta=\"SILVA_132_QIIME_release/rep_set/rep_set_16S_only/${params.dereplication}/silva_132_${params.dereplication}_16S.fna\"
		taxonomy=\"SILVA_132_QIIME_release/taxonomy/16S_only/${params.dereplication}/consensus_taxonomy_7_levels.txt\"

		if [ \"${params.classifier_removeHash}\" = \"true\" ]; then
			sed \'s/#//g\' \$taxonomy >taxonomy-${params.dereplication}_removeHash.txt
			taxonomy=\"taxonomy-${params.dereplication}_removeHash.txt\"
			echo \"\n######## WARNING! The taxonomy file was altered by removing all hash signs!\"
		fi

		### Import
		qiime tools import --type \'FeatureData[Sequence]\' \
			--input-path \$fasta \
			--output-path ref-seq-${params.dereplication}.qza
		qiime tools import --type \'FeatureData[Taxonomy]\' \
			--input-format HeaderlessTSVTaxonomyFormat \
			--input-path \$taxonomy \
			--output-path ref-taxonomy-${params.dereplication}.qza

		#Extract sequences based on primers
		qiime feature-classifier extract-reads \
			--i-sequences ref-seq-${params.dereplication}.qza \
			--p-f-primer ${params.FW_primer} \
			--p-r-primer ${params.RV_primer} \
			--o-reads ${params.FW_primer}-${params.RV_primer}-${params.dereplication}-ref-seq.qza \
			--quiet

		#Train classifier
		qiime feature-classifier fit-classifier-naive-bayes \
			--i-reference-reads ${params.FW_primer}-${params.RV_primer}-${params.dereplication}-ref-seq.qza \
			--i-reference-taxonomy ref-taxonomy-${params.dereplication}.qza \
			--o-classifier ${params.FW_primer}-${params.RV_primer}-${params.dereplication}-classifier.qza \
			--quiet
		"""
	}
	ch_message_classifier_removeHash
		.subscribe { log.info it }