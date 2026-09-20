// pairwise kinship on the LD-pruned variants
process KINSHIP {
    tag "${meta.id}"
    publishDir "${params.outdir}/kinship", mode: 'copy'

    input:
    tuple val(meta), path(bed), path(bim), path(fam), path(prune_in)

    output:
    tuple val(meta), path("${meta.id}.kinship.kin0"), emit: king_table
    path "${meta.id}.kinship.log",                    emit: log

    script:
    """
    plink2 \\
        --bfile ${bed.baseName} \\
        --extract ${prune_in} \\
        --make-king-table \\
        --king-table-filter ${params.king_cutoff} \\
        --out ${meta.id}.kinship \\
        --threads ${task.cpus}
    """
}
