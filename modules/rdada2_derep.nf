process rdada2_derep {
    publishDir "${params.outdir}/rdada2_derep", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple file(R1), file(R2)

    output:
    tuple file(R1), file("${R1.getSimpleName()}.derep.rds"), file(R2), file("${R2.getSimpleName()}.derep.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');
    derep_1 <- derepFastq('${R1}');
    saveRDS(derep_1, '${R1.getSimpleName()}.derep.rds');
    derep_2 <- derepFastq('${R2}');
    saveRDS(derep_2, '${R2.getSimpleName()}.derep.rds');
   
    """
}