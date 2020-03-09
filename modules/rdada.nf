process rdada {
    publishDir "${params.outdir}/rdada", mode: 'copy'
    //conda 'bioconda::bioconductor-dada2'
    //container 'biocontainers/bioconductor-dada2'
    //container 'golob/dada2'
    container 'kgolob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    set name, file(R1), file(R2)
    //set val(pair_id), file(reads)

    output:
    file("${R2.getSimpleName()}.dada2.ft.fq.gz")
    file("${R1.getSimpleName()}.dada2.ft.fq.gz")
    //  file "outfile.txt"

    script:
    """
    #!/usr/bin/env Rscript
    library('dada2'); 
    filterAndTrim(
        '${R1}', '${R1.getSimpleName()}.dada2.ft.fq.gz',
        '${R2}', '${R2.getSimpleName()}.dada2.ft.fq.gz'
    )
    """
}