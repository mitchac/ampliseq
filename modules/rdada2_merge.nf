process rdada2_merge {
    publishDir "${params.outdir}/rdada2_merge", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple file(R1dns), file(R2dns), file(R1lerr), file(R2lerr)

    output:
    file("${R1.getSimpleName()}merged.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');

    R1dns <- readRDS('${R1dns}');
    R2dns <- readRDS('${R2dns}');
    R1lerr <- readRDS('${R1lerr}');
    R2lerr <- readRDS('${R2lerr}');
        
    merger <- mergePairs(
        R1dns, R1lerr,
        R2dns, R2lerr,
        verbose=TRUE,
    );
    saveRDS(merger, "${R1dns.getSimpleName()}merged.rds");

   
    """
}