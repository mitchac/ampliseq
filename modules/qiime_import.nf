process qiime_import {
			publishDir "${params.outdir}/demux", mode: 'copy', 
			saveAs: { filename -> 
				params.keepIntermediates ? filename : null
				params.untilQ2import ? filename : null }

			input:
			file(manifest)
			env MATPLOTLIBRC

			output:
			file "demux.qza"

			when:
			!params.Q2imported
		
			script:
			if (!params.phred64) {
				"""
				qiime tools import \
					--type 'SampleData[PairedEndSequencesWithQuality]' \
					--input-path ${manifest} \
					--output-path demux.qza \
					--input-format PairedEndFastqManifestPhred33
				"""
			} else {
				"""
				qiime tools import \
					--type 'SampleData[PairedEndSequencesWithQuality]' \
					--input-path ${manifest} \
					--output-path demux.qza \
					--input-format PairedEndFastqManifestPhred64
				"""
			}
		}