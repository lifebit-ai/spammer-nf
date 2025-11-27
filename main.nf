nextflow.enable.dsl = 2

/*
 * Minimal spammer-style smoke test
 *
 * - Launches N tiny jobs (default 1)
 * - Each writes a small result file into params.output_dir
 * - Designed to finish quickly and prove CloudOS works end-to-end
 */

params.n_jobs      = params.n_jobs ?: 1
params.message     = params.message ?: 'Hello from spammer smoke test 🎉'
params.output_dir  = params.output_dir ?: 'results'

log.info "Smoke spammer starting"
log.info "  n_jobs     = ${params.n_jobs}"
log.info "  message    = ${params.message}"
log.info "  output_dir = ${params.output_dir}"

/****************************************
 * CHANNELS
 ****************************************/

Channel
    .from( 1..params.n_jobs as List<Integer> )
    .set { JOB_IDS }

/****************************************
 * PROCESSES
 ****************************************/

process SPAMMER_SMOKE {
    tag { "job_${job_id}" }

    publishDir "${params.output_dir}", mode: 'copy', overwrite: true

    cpus 1
    memory '512 MB'
    time '10 min'

    input:
    val job_id from JOB_IDS

    output:
    path "result_${job_id}.txt" into RESULT_FILES

    """
    echo "Job ID: ${job_id}"                           >  result_${job_id}.txt
    echo "Message: ${params.message}"                 >> result_${job_id}.txt
    echo "Timestamp: \$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> result_${job_id}.txt
    echo "Hostname: \$(hostname)"                     >> result_${job_id}.txt
    """
}

/****************************************
 * WORKFLOW
 ****************************************/

workflow {

    main:
        SPAMMER_SMOKE(JOB_IDS)

    emit:
        RESULT_FILES
}

