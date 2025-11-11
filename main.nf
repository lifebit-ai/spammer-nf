nextflow.enable.dsl=1

// ------------ Detect filesystem ------------
fileSystem = params.dataLocation?.contains(':') ? params.dataLocation.split(':')[0] : 'local'

// ------------ Generator params ------------
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
if(params.executor == 'awsbatch') {
  log.info "aws_batch_cliPath                     : ${params.aws_batch_cliPath}"
  log.info "aws_batch_fetchInstanceType           : ${params.aws_batch_fetchInstanceType}"
  log.info "aws_batch_process_queue               : ${params.aws_batch_process_queue}"
  log.info "aws_batch_docker_run_options          : ${params.aws_batch_docker_run_options}"
}
if(params.executor == 'google-lifesciences') {
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

// ------------ Channels (DSL1) ------------
// A's inputs
processAInput      = Channel.from( [1] * numberRepetitionsForProcessA )
processAInputFiles = Channel.fromPath("${params.dataLocation}/*${params.fileSuffix}")
                            .take( numberRepetitionsForProcessA )
// Generator trigger: emits a single value so the process runs once
genTrigger         = Channel.from(1)

// =====================================================
//                      PROCESSES (DSL1)
// =====================================================

/**
 * Generates N tiny files and PUBLISHES them.
 * Writes into local 'generated/' and declares outputs; publishDir copies to gen_outdir.
 */
process GENERATE_RESULTS {
  publishDir "${params.gen_outdir}", mode: 'copy', overwrite: true
  tag "generate ${params.gen_count} -> ${params.gen_outdir}"

  when:
  params.run_generator

  input:
  val t from genTrigger

  output:
  file "generated/*" into genFiles

  script:
  """
  set -euo pipefail
  mkdir -p generated
  for i in \$(seq 1 ${params.gen_count}); do
    printf "This is file %d\\n" "\$i" > "generated/result_\$(printf '%05d' "\$i").txt"
  done
  echo "Created \$(ls -1 generated | wc -l) files in generated"
  """
}

process processA {
  publishDir "${params.output}/${task.hash}", mode: 'copy'
  tag "cpus: ${task.cpus}"

  input:
  val x from processAInput
  file a_file from processAInputFiles

  output:
  val x into processAOutput
  val x into processCInput
  val x into processDInput
  file "*.txt" into processAFiles

  script:
  """
  ${params.pre_script}
  pwd=\$(basename "\$PWD" | cut -c1-6)
  echo "\$pwd"
  if command -v shuf >/dev/null 2>&1; then
    timeToWait=\$(shuf -i ${params.processATimeRange} -n 1)
  else
    lo=\$(echo ${params.processATimeRange} | cut -d- -f1)
    hi=\$(echo ${params.processATimeRange} | cut -d- -f2)
    span=\$((hi - lo + 1))
    timeToWait=\$(( (RANDOM % span) + lo ))
  fi
  for i in \$(seq 1 ${numberFilesForProcessA}); do
    dd if=/dev/urandom of="\${pwd}_file_\${i}.txt" bs=1M count=${processAWriteToDiskMb} status=none
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
  val x from processAOutput

  output:
  file "newfile" into processBFile

  script:
  """
  ${params.pre_script}
  if command -v shuf >/dev/null 2>&1; then
    timeToWait=\$(shuf -i ${params.processBTimeRange} -n 1)
  else
    lo=\$(echo ${params.processBTimeRange} | cut -d- -f1)
    hi=\$(echo ${params.processBTimeRange} | cut -d- -f2)
    span=\$((hi - lo + 1))
    timeToWait=\$(( (RANDOM % span) + lo ))
  fi
  sleep "\$timeToWait"
  dd if=/dev/urandom of=newfile bs=1M count=${params.processBWriteToDiskMb} status=none
  ${params.post_script}
  """
}

process processC {
  publishDir "${params.output}/${task.hash}", mode: 'copy'

  input:
  val x from processCInput

  output:
  val x into processCOut

  script:
  """
  ${params.pre_script}
  if command -v shuf >/dev/null 2>&1; then
    timeToWait=\$(shuf -i ${params.processCTimeRange} -n 1)
  else
    lo=\$(echo ${params.processCTimeRange} | cut -d- -f1)
    hi=\$(echo ${params.processCTimeRange} | cut -d- -f2)
    span=\$((hi - lo + 1))
    timeToWait=\$(( (RANDOM % span) + lo ))
  fi
  sleep "\$timeToWait"
  ${params.post_script}
  """
}

process processD {
  publishDir "${params.output}/${task.hash}", mode: 'copy'

  input:
  val x from processDInput

  output:
  val x into processDOut

  script:
  """
  ${params.pre_script}
  if command -v shuf >/dev/null 2>&1; then
    timeToWait=\$(shuf -i ${params.processDTimeRange} -n 1)
  else
    lo=\$(echo ${params.processDTimeRange} | cut -d- -f1)
    hi=\$(echo ${params.processDTimeRange} | cut -d- -f2)
    span=\$((hi - lo + 1))
    timeToWait=\$(( (RANDOM % span) + lo ))
  fi
  sleep "\$timeToWait"
  ${params.post_script}
  """
}

// =====================================================
//                      WORKFLOW (DSL1: implicit via channels)
// =====================================================

// Nothing to “call” here; all processes are driven by channels.
// GENERATE_RESULTS runs once via `genTrigger` when run_generator=true.
// A→B/C/D are wired through their channels.
