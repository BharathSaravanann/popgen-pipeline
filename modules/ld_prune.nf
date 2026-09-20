// LD pruning for kinship, reducing reduntant SNPS

process LD_PRUNE {
    tag "${meta.id}"
    publishDir "${params.outdir}/ld_prune", mode: 'copy'

    input:
    tuple val(meta), path(bed), path(bim), path(fam)

    output:
    tuple val(meta), path("${meta.id}.prune.in"), emit: prune_in
    path "${meta.id}.prune.out",                  emit: prune_out
    path "${meta.id}.ldprune.log",                emit: log

    script:
    """
    plink2 \\
        --bfile ${bed.baseName} \\
        --indep-pairwise ${params.ld_window} ${params.ld_step} ${params.ld_r2} \\
        --bad-ld \\
        --out ${meta.id} \\
        --threads ${task.cpus}

    mv ${meta.id}.log ${meta.id}.ldprune.log
    """
}
