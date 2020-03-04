process dada_trunc_parameter { 

	input:
	file summary_demux from ch_csv_demux 

	output:
	stdout ch_dada_trunc

	when:
	!params.untilQ2import

	script:
	if( !params.trunclenf || !params.trunclenr ){
		"""
		dada_trunc_parameter.py ${summary_demux[0]} ${summary_demux[1]} ${params.trunc_qmin}
		"""
	}
	else
		"""
		printf "${params.trunclenf},${params.trunclenr}"
		"""
}