process rdada2_filterandtrim {
    publishDir "${params.outdir}/rdada2_filterandtrim", mode: 'copy'
    //conda 'bioconda::bioconductor-dada2'
    //container 'biocontainers/bioconductor-dada2'
    //container 'golob/dada2'
    container 'golob/dada2:1.12.0.ub.1804__bcw.0.3.1'

    input:
    tuple name, file(R1), file(R2)
    //set val(pair_id), file(reads)

    output:
    tuple file("${R2.getSimpleName()}.ft.gz"), file("${R1.getSimpleName()}.ft.gz")
    //  file "outfile.txt"

    script:
    """
    #!/usr/bin/env Rscript
    library('dada2'); 
    filterAndTrim(
        '${R1}', '${R1.getSimpleName()}.ft.gz',
        '${R2}', '${R2.getSimpleName()}.ft.gz'
    );
    """
}