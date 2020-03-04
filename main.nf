#!/usr/bin/env nextflow
nextflow.preview.dsl=2
/*
========================================================================================
						 nf-core/ampliseq
========================================================================================
 nf-core/ampliseq Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/ampliseq
----------------------------------------------------------------------------------------
*/


def helpMessage() {
	log.info nfcoreHeader()
	log.info"""
	Usage:

	The minimal command for running the pipeline is as follows:
	nextflow run nf-core/ampliseq -profile singularity --reads "data" --FW_primer GTGYCAGCMGCCGCGGTAA --RV_primer GGACTACNVGGGTWTCTAAT

	In case of a timezone error, please specify "--qiime_timezone", e.g. --qiime_timezone 'Europe/Berlin'!

	Main arguments:
	  -profile [strings]            Use this parameter to choose a configuration profile. If not specified, runs locally and expects all software
	                                to be installed and available on the `PATH`. Otherwise specify a container engine, "docker" or "singularity" 
	                                and a specialized profile such as "binac".
	  --reads [path/to/folder]      Folder containing paired-end demultiplexed fastq files
	                                Note: All samples have to be sequenced in one run, otherwise also specifiy "--multipleSequencingRuns"
	  --FW_primer [str]             Forward primer sequence
	  --RV_primer [str]             Reverse primer sequence
	  --metadata [path/to/file]     Path to metadata sheet, when missing most downstream analysis are skipped (barplots, PCoA plots, ...)
	  --qiime_timezone [str]		Needs to be specified to resolve a timezone error (default: 'Europe/Berlin')

	Other input options:
	  --extension [str]             Naming of sequencing files (default: "/*_R{1,2}_001.fastq.gz"). 
	                                The prepended "/" is required, also one "*" is required for sample names and "{1,2}" indicates read orientation
	  --multipleSequencingRuns      If samples were sequenced in multiple sequencing runs. Expects one subfolder per sequencing run
	                                in the folder specified by "--reads" containing sequencing data of the specific run. These folders 
	                                may not contain underscores. Also, fastQC is skipped because multiple sequencing runs might 
	                                create overlapping file names that crash MultiQC.
	  --split [str]                 A string that will be used between the prepended run/folder name and the sample name. (default: "-")
	                                May not be present in run/folder names and no underscore(s) allowed. Only used with "--multipleSequencingRuns"
	  --phred64                     If the sequencing data has PHRED 64 encoded quality scores (default: PHRED 33)

	Filters:
	  --exclude_taxa [str]          Comma separated list of unwanted taxa (default: "mitochondria,chloroplast")
	                                To skip taxa filtering use "none"
	  --min_frequency [int]         Remove entries from the feature table below an absolute abundance threshold (default: 1)
	  --min_samples [int]           Filtering low prevalent features from the feature table (default: 1)                   

	Cutoffs:
	  --retain_untrimmed            Cutadapt will retain untrimmed reads
	  --trunclenf [int]             DADA2 read truncation value for forward strand
	  --trunclenr [int]             DADA2 read truncation value for reverse strand
	  --trunc_qmin [int]            If --trunclenf and --trunclenr are not set, 
	                                these values will be automatically determined using 
	                                this mean quality score (not preferred) (default: 25)

	References:                     If you have trained a compatible classifier before
	  --classifier [path/to/file]   Path to QIIME2 classifier file (typically *-classifier.qza)
	  --classifier_removeHash       Remove all hash signs from taxonomy strings, resolves a rare ValueError during classification (process classifier)

	Statistics:
	  --metadata_category [str]     Comma separated list of metadata column headers for statistics (default: false)
	                                If not specified, all suitable columns in the metadata sheet will be used.
	                                Suitable are columns which are categorical (not numerical) and have multiple  
	                                different values that are not all unique.

	Other options:
	  --untilQ2import               Skip all steps after importing into QIIME2, used for visually choosing DADA2 parameter
	  --Q2imported [path/to/file]   Path to imported reads (e.g. "demux.qza"), used after visually choosing DADA2 parameter
	  --onlyDenoising               Skip all steps after denoising, produce only sequences and abundance tables on ASV level
	  --keepIntermediates           Keep additional intermediate files, such as trimmed reads or various QIIME2 archives
	  --outdir [path/to/folder]     The output directory where the results will be saved
	  --email [email]               Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
	  --maxMultiqcEmailFileSize     Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, 
	                                it will not be attached (Default: 25MB)
	  -name [str]                   Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

	Skipping steps:
	  --skip_fastqc                 Skip FastQC
	  --skip_alpha_rarefaction      Skip alpha rarefaction
	  --skip_taxonomy               Skip taxonomic classification
	  --skip_barplot                Skip producing barplot
	  --skip_abundance_tables       Skip producing any relative abundance tables
	  --skip_diversity_indices      Skip alpha and beta diversity analysis
	  --skip_ancom                  Skip differential abundance testing     
	""".stripIndent()
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Show help emssage
if (params.help){
	helpMessage()
	exit 0
}

// Configurable variables
params.name = false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"
params.email = false
params.plaintext_email = false

ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")
Channel.fromPath("$baseDir/assets/matplotlibrc")
	.set { ch_mpl }


/*
 * Define pipeline steps
 */
params.untilQ2import = false

params.Q2imported = false
if (params.Q2imported) {
	params.skip_fastqc = true
	params.skip_multiqc = true
} else {
	params.skip_multiqc = false
}

//Currently, fastqc doesnt work for multiple runs when sample names are identical. These names are encoded in the sequencing file itself.
if (params.multipleSequencingRuns) {
	params.skip_fastqc = true
} else {
	params.skip_fastqc = false
}

params.onlyDenoising = false
if (params.onlyDenoising || params.untilQ2import) {
	params.skip_abundance_tables = true
	params.skip_barplot = true
	params.skip_taxonomy = true
	params.skip_alpha_rarefaction = true
	params.skip_diversity_indices = true
	params.skip_ancom = true
} else {
	params.skip_abundance_tables = false
	params.skip_barplot = false
	params.skip_taxonomy = false
	params.skip_alpha_rarefaction = false
	params.skip_diversity_indices = false
	params.skip_ancom = false
}

/*
 * Import input files
 */
if (params.metadata) {
	Channel.fromPath("${params.metadata}", checkIfExists: true)
		.set { ch_metadata }
} else {
	Channel.from()
		.set { ch_metadata }
}

if (params.Q2imported) {
	Channel.fromPath("${params.Q2imported}", checkIfExists: true)
		   .set { ch_qiime_demux }
}

if (params.classifier) {
	Channel.fromPath("${params.classifier}", checkIfExists: true)
		   .set { ch_qiime_classifier }
}

/*
 * Sanity check input values
 */
if (!params.Q2imported) { 
	if (!params.FW_primer) { exit 1, "Option --FW_primer missing" }
	if (!params.RV_primer) { exit 1, "Option --RV_primer missing" }
	if (!params.reads) { exit 1, "Option --reads missing" }
}

if (params.Q2imported && params.untilQ2import) {
	exit 1, "Choose either to import data into a QIIME2 artefact and quit with --untilQ2import or use an already existing QIIME2 data artefact with --Q2imported."
}

if ("${params.split}".indexOf("_") > -1 ) {
	exit 1, "Underscore is not allowed in --split, please review your input."
}

// AWSBatch sanity checking
if(workflow.profile == 'awsbatch'){
	if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
	if (!workflow.workDir.startsWith('s3') || !params.outdir.startsWith('s3')) exit 1, "Specify S3 URLs for workDir and outdir parameters on AWSBatch!"
}

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


if( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (params.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

// Stage config files
ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")


// Header log info
log.info nfcoreHeader()
def summary = [:]
summary['Pipeline Name']  = 'nf-core/ampliseq'
if(workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
summary['Reads']            = params.reads
summary['Data Type']        = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if(workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName
if(workflow.profile == 'awsbatch'){
   summary['AWS Region']    = params.awsregion
   summary['AWS Queue']     = params.awsqueue
}
summary['Config Profile'] = workflow.profile
if(params.config_profile_description) summary['Config Description'] = params.config_profile_description
if(params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if(params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if(params.email) {
  summary['E-mail Address']  = params.email
  summary['MultiQC maxsize'] = params.maxMultiqcEmailFileSize
}
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m----------------------------------------------------\033[0m-"

if( !params.trunclenf || !params.trunclenr ){
	if ( !params.untilQ2import ) log.info "\n######## WARNING: No DADA2 cutoffs were specified, therefore reads will be truncated where median quality drops below ${params.trunc_qmin}.\nThe chosen cutoffs do not account for required overlap for merging, therefore DADA2 might have poor merging efficiency or even fail.\n"
}
// Check the hostnames against configured profiles
checkHostname()

def create_workflow_summary(summary) {
	def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
	yaml_file.text  = """
	id: 'nf-core-ampliseq-summary'
	description: " - this information is collected when the pipeline is started."
	section_name: 'nf-core/ampliseq Workflow Summary'
	section_href: 'https://github.com/nf-core/ampliseq'
	plot_type: 'html'
	data: |
		<dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
		</dl>
	""".stripIndent()

   return yaml_file
}


/*
 * Parse software version numbers
 */
process get_software_versions {
	publishDir "${params.outdir}/pipeline_info", mode: 'copy',
	saveAs: {filename ->
		if (filename.indexOf(".csv") > 0) filename
		else null
	}

	output:
	file 'software_versions_mqc.yaml'
	file "software_versions.csv"

	script:
	"""
	echo $workflow.manifest.version > v_pipeline.txt
	echo $workflow.nextflow.version > v_nextflow.txt
	fastqc --version > v_fastqc.txt
	multiqc --version > v_multiqc.txt
	cutadapt --version > v_cutadapt.txt
	qiime --version > v_qiime.txt
	scrape_software_versions.py &> software_versions_mqc.yaml
	"""
}

include fastqc from './modules/fastQC.nf'
include trimming from './modules/trimming.nf'
include qiime_import from './modules/qiime_import.nf'
include qiime_demux_visualize from './modules/qiime_demux_visualize.nf'
include dada_trunc_parameter from './modules/dada_trunc_parameter.nf'
include dada_single from './modules/dada_single.nf'

workflow {

	/*
	* Create a channel for input read files
	*/
	Channel
		.fromFilePairs( params.reads + params.extension, size: 2 )
		.ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}${params.extension}\nNB: Path needs to be enclosed in quotes!" }
		.set { ch_read_pairs }

	fastqc(ch_read_pairs)
	trimming(ch_read_pairs)

	/*
	* Produce manifest file for QIIME2
	*/
	// nb 'out' from process with mult outputs is list so using [0] to access first element of list 
	trimming.out[0]
		.map { forward, reverse -> [ forward.drop(forward.findLastIndexOf{"/"})[0], forward, reverse ] } //extract file name
		.map { name, forward, reverse -> [ name.toString().take(name.toString().indexOf("_")), forward, reverse ] } //extract sample name
		.map { name, forward, reverse -> [ name +","+ forward + ",forward\n" + name +","+ reverse +",reverse" ] } //prepare basic synthax
		.flatten()
		.collectFile(name: 'manifest.txt', newLine: true, storeDir: "${params.outdir}/demux", seed: "sample-id,absolute-filepath,direction")
		.set { ch_manifest }

	qiime_import(ch_manifest,ch_mpl)
	qiime_demux_visualize(qiime_import.out,ch_mpl)
	dada_trunc_parameter(qiime_demux_visualize.out[0])
	dada_single(qiime_demux_visualize.out[0],dada_trunc_parameter.out,ch_mpl)

}	


	





/*
 * STEP 3 - Output Description HTML
 */
process output_documentation {
	publishDir "${params.outdir}/Documentation", mode: 'copy'

	input:
	file output_docs from ch_output_docs

	output:
	file "results_description.html"

	script:
	"""
	markdown_to_html.r $output_docs results_description.html
	"""
}



/*
 * Completion e-mail notification
 */
workflow.onComplete {

	// Set up the e-mail variables
	def subject = "[nf-core/ampliseq] Successful: $workflow.runName"
	if(!workflow.success){
	  subject = "[nf-core/ampliseq] FAILED: $workflow.runName"
	}
	def email_fields = [:]
	email_fields['version'] = workflow.manifest.version
	email_fields['runName'] = custom_runName ?: workflow.runName
	email_fields['success'] = workflow.success
	email_fields['dateComplete'] = workflow.complete
	email_fields['duration'] = workflow.duration
	email_fields['exitStatus'] = workflow.exitStatus
	email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
	email_fields['errorReport'] = (workflow.errorReport ?: 'None')
	email_fields['commandLine'] = workflow.commandLine
	email_fields['projectDir'] = workflow.projectDir
	email_fields['summary'] = summary
	email_fields['summary']['Date Started'] = workflow.start
	email_fields['summary']['Date Completed'] = workflow.complete
	email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
	email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
	if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
	if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
	if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
	if(workflow.container) email_fields['summary']['Docker image'] = workflow.container
	email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
	email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
	email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

	// On success try attach the multiqc report
	def mqc_report = null
	try {
		if (workflow.success) {
			mqc_report = multiqc_report.getVal()
			if (mqc_report.getClass() == ArrayList){
				log.warn "[nf-core/ampliseq] Found multiple reports from process 'multiqc', will use only one"
				mqc_report = mqc_report[0]
			}
		}
	} catch (all) {
		log.warn "[nf-core/ampliseq] Could not attach MultiQC report to summary email"
	}

	// Render the TXT template
	def engine = new groovy.text.GStringTemplateEngine()
	def tf = new File("$baseDir/assets/email_template.txt")
	def txt_template = engine.createTemplate(tf).make(email_fields)
	def email_txt = txt_template.toString()

	// Render the HTML template
	def hf = new File("$baseDir/assets/email_template.html")
	def html_template = engine.createTemplate(hf).make(email_fields)
	def email_html = html_template.toString()

	// Render the sendmail template
	def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.maxMultiqcEmailFileSize.toBytes() ]
	def sf = new File("$baseDir/assets/sendmail_template.txt")
	def sendmail_template = engine.createTemplate(sf).make(smail_fields)
	def sendmail_html = sendmail_template.toString()

	// Send the HTML e-mail
	if (params.email) {
		try {
		  if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
		  // Try to send HTML e-mail using sendmail
		  [ 'sendmail', '-t' ].execute() << sendmail_html
		  log.info "[nf-core/ampliseq] Sent summary e-mail to $params.email (sendmail)"
		} catch (all) {
		  // Catch failures and try with plaintext
		  [ 'mail', '-s', subject, params.email ].execute() << email_txt
		  log.info "[nf-core/ampliseq] Sent summary e-mail to $params.email (mail)"
		}
	}

	// Write summary e-mail HTML to a file
	def output_d = new File( "${params.outdir}/pipeline_info/" )
	if( !output_d.exists() ) {
	  output_d.mkdirs()
	}
	def output_hf = new File( output_d, "pipeline_report.html" )
	output_hf.withWriter { w -> w << email_html }
	def output_tf = new File( output_d, "pipeline_report.txt" )
	output_tf.withWriter { w -> w << email_txt }

	c_reset = params.monochrome_logs ? '' : "\033[0m";
	c_purple = params.monochrome_logs ? '' : "\033[0;35m";
	c_green = params.monochrome_logs ? '' : "\033[0;32m";
	c_red = params.monochrome_logs ? '' : "\033[0;31m";

	if (workflow.stats.ignoredCountFmt > 0 && workflow.success) {
	  log.info "${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}"
	  log.info "${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCountFmt} ${c_reset}"
	  log.info "${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCountFmt} ${c_reset}"
	}

	if(workflow.success){
		log.info "${c_purple}[nf-core/ampliseq]${c_green} Pipeline completed successfully${c_reset}"
	} else {
		checkHostname()
		log.info "${c_purple}[nf-core/ampliseq]${c_red} Pipeline completed with errors${c_reset}"
	}

}


def nfcoreHeader(){
	// Log colors ANSI codes
	c_reset = params.monochrome_logs ? '' : "\033[0m";
	c_dim = params.monochrome_logs ? '' : "\033[2m";
	c_black = params.monochrome_logs ? '' : "\033[0;30m";
	c_green = params.monochrome_logs ? '' : "\033[0;32m";
	c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
	c_blue = params.monochrome_logs ? '' : "\033[0;34m";
	c_purple = params.monochrome_logs ? '' : "\033[0;35m";
	c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
	c_white = params.monochrome_logs ? '' : "\033[0;37m";

return """${c_dim}----------------------------------------------------${c_reset}
	                                ${c_green},--.${c_black}/${c_green},-.${c_reset}
${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
	                                ${c_green}`._,._,\'${c_reset}
${c_purple}  nf-core/ampliseq v${workflow.manifest.version}${c_reset}
${c_dim}----------------------------------------------------${c_reset}
""".stripIndent()
}

def checkHostname(){
	def c_reset = params.monochrome_logs ? '' : "\033[0m"
	def c_white = params.monochrome_logs ? '' : "\033[0;37m"
	def c_red = params.monochrome_logs ? '' : "\033[1;91m"
	def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
	if(params.hostnames){
		def hostname = "hostname".execute().text.trim()
		params.hostnames.each { prof, hnames ->
			hnames.each { hname ->
				if(hostname.contains(hname) && !workflow.profile.contains(prof)){
					log.error "====================================================\n" +
							"  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
							"  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
							"  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
							"============================================================"
				}
			}
		}
	}
}
