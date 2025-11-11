nextflow.enable.dsl=2

// ------------ Detect filesystem ------------
fileSystem = params.dataLocation?.contains(':') ? params.dataLocation.split(':')[0] : 'local'

// ------------ Generator params (new) ------------
params.run_generator = (params.run_generator != null ? params.run_generator : true)
params.gen_count     = (params.gen_count ?: 3000) as int
params.gen_outdir    = params.gen_outdir ?: 'results'

// ------------ Header log ------------
log.info "\nPARAMETERS SUMMARY"
log.info "mainScript                            : ${params.mainScript}"
log.info "config                                : ${params.config}"
log.info "fileSystem                            : ${fileSystem}"
log.info "dataLocation                          : ${params.dataLocation}"
log.info "fileSuffix                            : ${params.fileSuffix}"
log.info "repsProcessA                          : ${params.repsProcessA}"
log.info "processAWriteToDiskMb                 : ${params.processAWriteToDiskMb}"
log.info "processATimeRange                     : ${params.processATimeRange}"
log.info "filesProcessA                         : ${params.filesProcessA}"
log.info "processATimeBetweenFileCreationInSecs : ${params.processATimeBetweenFileCreationInSecs}"
log.info "processBTimeRange                     : ${params.processBTimeRange}"
log.info "processBWriteToDiskMb                 : ${params.processBWriteToDiskMb}"
log.info "processCTimeRange                     : ${params.processCTimeRange}"
log.info "processDTimeRange                     : ${params.processDTimeRange}"
log.info "output                                : ${params.output}"
log.info "echo                                  : ${params.echo}"
log.info "cpus                                  : ${params.cpus}"
log.info "processA_cpus                         : ${params.processA_cpus}"
log.info "errorStrategy                         : ${params.errorStrategy}"
log.info "container                             : ${params.container}"
log.info "maxForks                              : ${params.maxForks}"
log.info "queueSize                             : ${params.queueSize}"
log.info "pre_script                            : ${params.pre_script}"
log.info "post_script                           : ${params.post_script}"
log.info "executor                              : ${params.executor}"
if (params.executor == 'awsbatch') {
  log.info "aws_batch_cliPath                     : ${params.aws_batch_cliPath}"
  log.info "aws_batch_fetchInstanceType           : ${params.aws_batch_fetchInstanceType}"
  log.info "aws_batch_process_queue               : ${params.aws_batch_process_queue}"
  log.info "aws_batch_docker_run_options          : ${params.aws_batch_docker_run_options}"
}
if (params.executor == 'google-lifesciences') {
  log.info "gls_bootDiskSize                      : ${params.gls_bootDiskSize}"
  log.info "gls_preemptible                       : ${params.gls_preemptible}"
  log.info "gls_usePrivateAddress                 : ${params.gls_usePrivateAddress}"
  log.info "zone                                  : ${params.zone}"
  log.info "network                               : ${params.network}"
  log.info "subnetwork                            : ${params.subnetwork}"
  log.info "lifeSciences.usePrivateAddress        : ${params.gls_usePrivateAddress}"
  log.info "google.lifeSciences.sshDaemon         : ${params.gls_sshDaemon}"
}
log.info "run_generator                         : ${params.run_generator}"
log.info "gen_count                             : ${params.gen_count}"
log.info "gen_outdir                            : ${params.gen_outdir}"
log.info ""

// ------------ Defaults to avoid nulls ------------
numberRepetitionsForProcessA = (params.repsProcessA ?: 1) as int
numberFilesForProcessA       = (params.filesProcessA ?: 1) as int
processAWriteToDiskMb        = (params.processAWriteToDiskMb ?: 1) as int

// =====================================================
//                      PROCESSES
// =====================================================

/**
 * Generates N tiny files under params.gen_outdir.
 * We use publishDir so CloudOS captures the folder; no outputs required.
 */
process GENERATE_RESULTS {
  tag "generate ${params.gen_count} -> ${params.gen_outdir}"
  cpus 1
  publishDir "${params.gen_outdir}", mode: 'copy', overwrite: true

  when:
  params.run_generator

  script:
  """
  mkdir -p "${params.gen_outdir}"
  for i in \$(seq 1 ${params.gen_count}); do
    printf "This is file %d\\n" "\$i" > "${params.gen_outdir}/result_\$(printf '%05d' "\$i").txt"
  done
  echo "Created \$(ls -1 "${params.gen_outdir}" | wc -l) files in ${params.gen_outdir}"
  """
}

process processA {
  publishDir "${params.output}/${task.hash}", mode: 'copy'
  tag "cpus: ${task.cpus}"

  input:
  val x
  file a_file

  // three vals (fan-out) + files
  output:
  val x
  val x
  val x
  file "*.txt"

  script:
  """
  ${params.pre_script}
  pwd=\$(basename "\$PWD" | cut -c1-6)
  echo "\$pwd"
  timeToWait=\$(shuf -i ${params.processATimeRange} -n 1)
  for i in \$(seq 1 ${numberFilesForProcessA}); do
    head -c ${processAWriteToDiskMb}MB /dev/urandom > "\${pwd}_file_\${i}.txt"
    sleep ${params.processATimeBetweenFileCreationInSecs}
  done
  sleep "\$timeToWait"
  echo "task cpus: ${task.cpus}"
  ${params.post_script}
  """
}

process processB {
  publishDir "${params.output}/${task.hash}", mode: 'copy'

  input:
  val x

  output:
  file "newfile"

  script:
  """
  ${params.pre_script}
  timeToWait=\$(shuf -i ${params.processBTimeRange} -n 1)
  sleep "\$timeToWait"
  dd if=/dev/urandom of=newfile bs=1M count=${params.processBWriteToDiskMb}
  ${params.post_script}
  """
}

process processC {
  publishDir "${params.output}/${task.hash}", mode: 'copy'

  input:
  val x

  output:
  val x

  script:
  """
  ${params.pre_script}
  timeToWait=\$(shuf -i ${params.processCTimeRange} -n 1)
  sleep "\$timeToWait"
  ${params.post_script}
  """
}

process processD {
  publishDir "${params.output}/${task.hash}", mode: 'copy'

  input:
  val x

  output:
  val x

  script:
  """
  ${params.pre_script}
  timeToWait=\$(shuf -i ${params.processDTimeRange} -n 1)
  sleep "\$timeToWait"
  ${params.post_script}
  """
}

// =====================================================
//                      WORKFLOW
// =====================================================

workflow {

  // Inputs for A
  def chA_vals  = Channel.from( [1] * numberRepetitionsForProcessA )
  def chA_files = Channel.fromPath("${params.dataLocation}/*${params.fileSuffix}")
                         .take( numberRepetitionsForProcessA )

  // Optional generator (standalone)
  if (params.run_generator) {
    GENERATE_RESULTS()
  }

  // Invoke A and destructure its positional outputs
  // processA outputs (in order): val, val, val, files
  def (A_to_B, A_to_C, A_to_D, A_files) = processA( chA_vals, chA_files )

  // Downstream steps
  def (B_file) = processB( A_to_B )
  def (C_val)  = processC( A_to_C )
  def (D_val)  = processD( A_to_D )

  // Expose useful outputs if you like
  emit:
    a_files = A_files
    b_file  = B_file
    c_val   = C_val
    d_val   = D_val
}
