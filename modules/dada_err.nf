process dada_err {
    publishDir "${params.outdir}/rdada", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    set name, file(R1), file(R2)

    output:

    script:
    """
    #!/usr/bin/env Rscript

    #filtsF <- list.files("/data/my-pipelines/nf-core/ampliseq/results/rdada", pattern=".fastq.gz$", full.names=TRUE);
    """
}