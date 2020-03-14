process rdada2_denoise {
    publishDir "${params.outdir}/rdada2_denoise", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple key, file(files)

    output:
    tuple file("${files[0].getSimpleName()}.dns.rds")
        
    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');

    derep <- readRDS('${files[0]}');
    lerr <- readRDS('${files[1]}');

    ddR <- dada(derep, lerr, multithread=TRUE, verbose=FALSE);
    saveRDS(ddR, '${files[0].getSimpleName()}.dns.rds');

   
    """
}