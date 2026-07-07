#!/usr/bin/env nextflow
/*
 * nextflow-genomics-demo
 * A minimal, nf-core-style DSL2 pipeline: QC each FASTQ sample, then aggregate a report.
 * Runs locally with Docker or at scale on AWS Batch (see nextflow.config profiles).
 */
nextflow.enable.dsl = 2

include { FASTQC }  from './modules/local/fastqc'
include { MULTIQC } from './modules/local/multiqc'

workflow {
    // Read a nf-core-style samplesheet: columns `sample,fastq`
    Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.fastq, checkIfExists: true)) }
        .set { reads_ch }

    FASTQC(reads_ch)

    // Collect every per-sample QC artifact into one aggregated report
    MULTIQC(FASTQC.out.zip.map { _sample, zip -> zip }.collect())
}

workflow.onComplete {
    log.info(workflow.success ? "✅ Pipeline complete → ${params.outdir}" : "❌ Pipeline failed")
}
