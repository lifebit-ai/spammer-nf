// main.nf

nextflow.enable.dsl=2

// ---------- Params ----------
params.count  = params.count  ?: 3000       // how many files
params.outdir = params.outdir ?: 'results'  // output folder

// ---------- Workflow ----------
workflow {
    GENERATE_RESULTS(params.count, params.outdir)
}

// ---------- Processes ----------
process GENERATE_RESULTS {
    tag "count=${count}"
    cpus 1
    // publish results/ so CloudOS collects it as an output directory
    publishDir "${outdir}", mode: 'copy', overwrite: true

    input:
    val count
    val outdir

    output:
    path outdir, emit: results_dir

    script:
    """
    mkdir -p ${outdir}
    # Create <count> files named result_00001.txt ... result_<count>.txt
    i=1
    while [ \$i -le ${count} ]; do
      printf "This is file %d\\n" "\$i" > "${outdir}/result_$(printf '%05d' \$i).txt"
      i=\$((i+1))
    done
    echo "Created \$(ls -1 ${outdir} | wc -l) files in ${outdir}"
    """
}
