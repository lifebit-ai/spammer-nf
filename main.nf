inputLocations = (params.dataLocation ?: '')
    .split(',')
    .collect { it.trim() }
    .findAll { it }

if (!inputLocations) {
    exit 1, "Missing --dataLocation. Provide one path/URI or a comma-separated list."
}

log.info "\nPARAMETERS SUMMARY"
log.info "mainScript   : ${params.mainScript}"
log.info "config       : ${params.config}"
log.info "dataLocation : ${params.dataLocation}"
log.info "inputCount   : ${inputLocations.size()}"
log.info ""

stagedInputFiles = Channel
    .fromPath(inputLocations, checkIfExists: true)
    .map { sourceFile -> tuple(sourceFile.toString(), sourceFile) }

process stage_and_print {
    tag "${source_uri}"

    input:
    tuple val(source_uri), file(staged_file) from stagedInputFiles

    script:
    """
    set -euo pipefail

    size_bytes=\$(wc -c < "${staged_file}")

    if command -v sha256sum >/dev/null 2>&1; then
      sha256=\$(sha256sum "${staged_file}" | awk '{print \$1}')
    else
      sha256=\$(shasum -a 256 "${staged_file}" | awk '{print \$1}')
    fi

    echo "source_uri=${source_uri}"
    echo "staged_name=${staged_file.name}"
    echo "staged_path=\$(pwd)/${staged_file.name}"
    echo "size_bytes=\${size_bytes}"
    echo "sha256=\${sha256}"
    """
}
