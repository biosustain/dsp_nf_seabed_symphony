// Local module: no nf-core module exists for Whokaryote.
//
// Version reporting: whokaryote.py has no --version flag, so the version is
// declared literally from environment.yml. Bump both together.

process WHOKARYOTE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/whokaryote:1.1.2--pyhdfd78af_0' :
        'quay.io/biocontainers/whokaryote:1.1.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(contigs)

    output:
    tuple val(meta), path("whokaryote/prokaryote_contig_headers.txt")                  , emit: prokaryote_headers
    tuple val(meta), path("whokaryote/eukaryote_contig_headers.txt")  , optional: true , emit: eukaryote_headers
    tuple val(meta), path("whokaryote/featuretable_predictions_T.tsv"), optional: true , emit: predictions
    tuple val(meta), path("whokaryote/*")                                              , emit: results
    tuple val("${task.process}"), val('whokaryote'), val('1.1.2')                      , topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Whokaryote runs Prodigal and Tiara over plain FASTA, but Flye emits .fasta.gz
    def decompress = contigs.toString().endsWith('.gz')
        ? "gzip -cd ${contigs} > contigs.fasta"
        : "cp -L ${contigs} contigs.fasta"
    """
    ${decompress}

    whokaryote.py \\
        --contigs contigs.fasta \\
        --outdir whokaryote \\
        --threads ${task.cpus} \\
        ${args}
    """

    stub:
    """
    mkdir -p whokaryote
    touch whokaryote/prokaryote_contig_headers.txt
    touch whokaryote/eukaryote_contig_headers.txt
    touch whokaryote/featuretable_predictions_T.tsv
    """
}
