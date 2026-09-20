// QC + filter to biallelic SNPs
// Also fixes '.' dup positions in 1000G VCFs
process QC_FILTER {
    tag "${meta.id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("${meta.id}.qc.bed"), path("${meta.id}.qc.bim"), path("${meta.id}.qc.fam"), emit: bed_set
    path "${meta.id}.qc.log", emit: log

    script:
    """
    plink2 \\
        --vcf ${vcf} \\
        --double-id \\
        --vcf-half-call missing \\
        --set-all-var-ids '@:#:\$r:\$a' \\
        --rm-dup force-first \\
        --max-alleles 2 \\
        --snps-only just-acgt \\
        --maf ${params.maf} \\
        --geno ${params.geno} \\
        --mind ${params.mind} \\
        --hwe ${params.hwe} \\
        --missing \\
        --make-bed \\
        --out ${meta.id}.qc \\
        --threads ${task.cpus}
    """
}
