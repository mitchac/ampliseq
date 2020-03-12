process rdada2_learnerrors {
    publishDir "${params.outdir}/rdada_learnerrors", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple file(R1), file(R2)

    output:
    file("${R1.getSimpleName()}.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');

    errF <- learnErrors('${R1}', multithread=multithread)
    saveRDS(errF, '${R1.getSimpleName()}.rds');

    """
}