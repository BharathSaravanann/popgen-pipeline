// ROH detection with plink1.9
// outputs: *.hom (per-segment), *.hom.indiv (per-sample NSEG/KB/KBAVG)
process ROH_ANALYSIS {
    tag "${meta.id}"
    publishDir "${params.outdir}/roh", mode: 'copy'

    input:
    tuple val(meta), path(bed), path(bim), path(fam)

    output:
    tuple val(meta), path("${meta.id}.roh.hom.indiv"), emit: hom_indiv
    tuple val(meta), path("${meta.id}.roh.hom"),        emit: hom
    path "${meta.id}.roh.log",                          emit: log

    script:
    """
    plink \\
        --bfile ${bed.baseName} \\
        --homozyg \\
        --homozyg-kb ${params.homozyg_kb} \\
        --homozyg-snp ${params.homozyg_snp} \\
        --homozyg-density ${params.homozyg_density} \\
        --homozyg-gap ${params.homozyg_gap} \\
        --homozyg-window-snp ${params.homozyg_window_snp} \\
        --homozyg-window-het ${params.homozyg_window_het} \\
        --homozyg-window-missing ${params.homozyg_window_missing} \\
        --out ${meta.id}.roh \\
        --threads ${task.cpus}
    """
}
