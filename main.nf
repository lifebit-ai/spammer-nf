processATimeRange = params.processATimeRange
processANumberFiles = params.filesProcessA
processATimeBetweenFileCreationInSecs = params.processATimeBetweenFileCreationInSecs
processANumberRepetitions = params.repsProcessA
processAInput = Channel.from([1] * processANumberRepetitions)

processBTimeRange = params.processBTimeRange
processBWriteToDiskMb = params.processBWriteToDiskMb

processCTimeRange = params.processCTimeRange

processDTimeRange = params.processDTimeRange

process processA {
	publishDir "${params.output}/${task.hash}", mode: 'copy'

	input:
	val x from processAInput

	output:
	val x into processAOutput
	val x into processCInput
	val x into processDInput
	file "*.txt"

	script:
	"""
	# Simulate the time the processes takes to finish
	timeToWait=\$(shuf -i ${processATimeRange} -n 1)
	for i in {1..${processANumberFiles}};
	do echo teste > file_\${i}.txt
	sleep ${processATimeBetweenFileCreationInSecs}
	done;
	sleep \$timeToWait
	"""
}

process processB {

	input:
	val x from processAOutput


	"""
    # Simulate the time the processes takes to finish
    timeToWait=\$(shuf -i ${processBTimeRange} -n 1)
    sleep \$timeToWait
	dd if=/dev/urandom of=newfile bs=1M count=${processBWriteToDiskMb}
	"""
}

process processC {

	input:
	val x from processCInput

	"""
    # Simulate the time the processes takes to finish
    timeToWait=\$(shuf -i ${processCTimeRange} -n 1)
    sleep \$timeToWait
	"""
}


process processD {

	input:
	val x from processDInput

	"""
    # Simulate the time the processes takes to finish
    timeToWait=\$(shuf -i ${processDTimeRange} -n 1)
    sleep \$timeToWait
	"""
}
