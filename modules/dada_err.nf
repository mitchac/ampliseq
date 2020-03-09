process dada_err {
    publishDir "${params.outdir}/rdada_err", mode: 'copy'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    set file(R1), file(R2)

    script:
    """
    #!/usr/bin/env Rscript
    library('dada2');
    print ("Print this on the screen")
   
    """
}