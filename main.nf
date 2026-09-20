#!/usr/bin/env nextflow
// popgen-pipeline: ROH + kinship from a multi-sample VCF (Nextflow DSL2)

nextflow.enable.dsl = 2

include { QC_FILTER      } from './modules/qc_filter.nf'
include { ROH_ANALYSIS   } from './modules/roh_analysis.nf'
include { LD_PRUNE       } from './modules/ld_prune.nf'
include { KINSHIP        } from './modules/kinship.nf'
include { REPORT         } from './modules/report.nf'

def helpMessage() {
    log.info """
    popgen-pipeline: ROH & Kinship from multi-sample VCF

    Usage:
      nextflow run main.nf -profile docker --vcf <multi_sample.vcf.gz> --outdir results/

    Required:
      --vcf         bgzipped, tabix-indexed multi-sample VCF (.vcf.gz)

    """.stripIndent()
}

workflow {

    if (!params.vcf) {
        log.error "Missing required parameter --vcf. Run with --help for usage."
        exit 1
    }

    def vcf_path   = file(params.vcf, checkIfExists: true)
    def index_path = params.vcf_index ? file(params.vcf_index, checkIfExists: true)
                                       : file("${params.vcf}.tbi", checkIfExists: true)

    ch_input = Channel.of([
        [ id: vcf_path.simpleName ],
        vcf_path,
        index_path
    ])

    // QC + biallelic SNP filtering
    QC_FILTER(ch_input)

    // ROH branch
    ROH_ANALYSIS(QC_FILTER.out.bed_set)

    // Kinship branch (LD pruning -> kinship table)
    LD_PRUNE(QC_FILTER.out.bed_set)
    KINSHIP(QC_FILTER.out.bed_set.join(LD_PRUNE.out.prune_in))

    // Combining both branches
    REPORT(
        ROH_ANALYSIS.out.hom_indiv.join(KINSHIP.out.king_table)
    )

    REPORT.out.summary.view { meta, csv, plot ->
        "Done: ${meta.id} -> ${csv}, ${plot}"
    }
}

workflow.onComplete {
    log.info "Finished at: ${workflow.complete}"
    log.info "Status:      ${workflow.success ? 'OK' : 'Pipeline interupted'}"
    log.info "Results in:  ${params.outdir}"
}
