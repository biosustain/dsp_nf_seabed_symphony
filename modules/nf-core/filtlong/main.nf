process FILTLONG {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/filtlong:0.2.1--h9ee0642_1' :
        'biocontainers/filtlong:0.2.1--h9ee0642_1' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    path  "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filtlong \\
        $args \\
        ${reads} \\
        | gzip -c > ${prefix}.filtlong.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$(filtlong --version 2>&1 | sed 's/Filtlong v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.filtlong.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$(filtlong --version 2>&1 | sed 's/Filtlong v//')
    END_VERSIONS
    """
}
