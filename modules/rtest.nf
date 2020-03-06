
process rtest {
                        
    input:
    //set val(pair_id), file(reads)

    output:
    //file "*_fastqc.{zip,html}"

    script:
    """
    #!/usr/bin/env Rscript
    print ("Print this on the screen")
    library('dada2');
    """
}