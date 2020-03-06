
process rtest {
    publishDir "${params.output}/rtest", mode: 'copy'

                        
    input:
    //set val(pair_id), file(reads)

    output:
    //file "*_fastqc.{zip,html}"

    script:
    """
    #!/usr/bin/env Rscript
    print ("Print this on the screen")
    library('dada2');
    txt <- c("Hallo", "World")
    writeLines(txt, "outfile.txt")
    """
}