process rdada2_merge {
    publishDir "${params.outdir}/rdada2_merge", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple key, file(files)

    output:
    file("${R1.getSimpleName()}merged.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');

    R1dns <- readRDS('${files[0]}');
    R2dns <- readRDS('${files[1]}');
    R1lerr <- readRDS('${files[2]}');
    R2lerr <- readRDS('${files[3]}');
        
    merger <- mergePairs(
        R1dns, R1lerr,
        R2dns, R2lerr,
        verbose=TRUE,
    );
    saveRDS(merger, "${files[0].getSimpleName()}merged.rds");

   
    """
}