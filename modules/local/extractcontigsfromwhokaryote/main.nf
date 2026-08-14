// Local module wrapping bin/extractContigsFromWhokaryote.py
// (from the original seabed-symphony repository, author Felipe Vaz Peres).
//
// Nextflow puts bin/ on PATH automatically, so the script is called by name.
// The `domain` input selects the script's --p (prokaryote) or --e (eukaryote)
// mode, which are mutually exclusive.

process EXTRACTCONTIGSFROMWHOKARYOTE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.84' :
        'quay.io/biocontainers/biopython:1.84' }"

    input:
    tuple val(meta), path(contigs), path(headers)
    val  domain // 'prokaryote' or 'eukaryote'

    output:
    tuple val(meta), path("*.fasta.gz")                                                  , emit: contigs
    tuple val("${task.process}"), val('extractContigsFromWhokaryote.py'), val('1.0')     , topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ( !( domain in ['prokaryote', 'eukaryote'] ) ) {
        error "EXTRACTCONTIGSFROMWHOKARYOTE: domain must be 'prokaryote' or 'eukaryote', got '${domain}'"
    }
    def flag = domain == 'prokaryote' ? '--p' : '--e'
    // Bio.SeqIO cannot read gzipped FASTA directly
    def decompress = contigs.toString().endsWith('.gz')
        ? "gzip -cd ${contigs} > contigs.fasta"
        : "cp -L ${contigs} contigs.fasta"
    """
    ${decompress}

    extractContigsFromWhokaryote.py \\
        --i contigs.fasta \\
        ${flag} ${headers} \\
        --o . \\
        ${args}

    mv contigs_${domain}.fasta ${prefix}.${domain}.fasta
    gzip -n ${prefix}.${domain}.fasta
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo stub | gzip -c > ${prefix}.${domain}.fasta.gz
    """
}
