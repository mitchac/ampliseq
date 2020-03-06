process rdada {
    publishDir "${params.outdir}/rdada", mode: 'copy'
              
    input:
    set name, file(R1), file(R2)
    //set val(pair_id), file(reads)

    output:
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