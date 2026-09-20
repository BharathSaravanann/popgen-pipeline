// building ROH summary, kinship summary, and Summary Plots
process REPORT {
    tag "${meta.id}"
    publishDir "${params.outdir}/report", mode: 'copy'

    input:
    tuple val(meta), path(hom_indiv), path(kin0)

    output:
    tuple val(meta), path("roh_summary.csv"), path("summary_plots.png"), emit: summary
    path "kinship_summary.csv",                                          emit: kinship_csv

    script:
    """
    generate_report.py \\
        --hom-indiv ${hom_indiv} \\
        --kin0 ${kin0} \\
        --froh-denom-mb ${params.froh_denom_mb} \\
        --outdir .
    """
}
