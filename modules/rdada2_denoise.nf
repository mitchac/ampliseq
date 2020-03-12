process rdada2_denoise {
    publishDir "${params.outdir}/rdada_denoise", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple file(R1), file(R1_err), file(R2), file(R2_err)

    output:
        tuple file(R1), file("${R1.getSimpleName()}.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');

    ddR <- dada(${R1}, ${R1_err}, multithread=multithread, verbose=FALSE);
    saveRDS(derep_1, '${R1.getSimpleName()}.rds');

   
    """
}