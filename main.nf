processATimeRange = params.processATimeRange
processANumberFiles = params.filesProcessA
processATimeBetweenFileCreationInSecs = params.processATimeBetweenFileCreationInSecs
processANumberRepetitions = params.repsProcessA
processAInput = Channel.from([1] * processANumberRepetitions)

processBTimeRange = params.processBTimeRange
processBWriteToDiskMb = params.processBWriteToDiskMb

processCTimeRange = params.processCTimeRange

processDTimeRange = params.processDTimeRange

c1 = Channel.fromPath("s3://lifebit-featured-datasets/HLA-LA/PRG_MHC_GRCh38_withIMGT/serializedGRAPH")
c2 = Channel.fromPath("s3://lifebit-featured-datasets/IGV/crg-covid/BAM/8F6N9_Korea_IVT.Wuhan_Hu_1_NanoPreprocess_alignment_Guppy3.1.5_Minimap2Default.minimap2.sorted.bam")
c3 = Channel.fromPath("s3://lifebit-featured-datasets/destiny/reference/GRCh37/human_g1k_v37_decoy.fasta")
c4 = Channel.fromPath("s3://lifebit-featured-datasets/pipelines/RepeatExpansion/Bams/NA19657.mapped.ILLUMINA.bwa.MXL.exome.20120522.bam")
c5 = Channel.fromPath("s3://lifebit-featured-datasets/pipelines/RepeatExpansion/Bams/NA19726.mapped.ILLUMINA.bwa.MXL.exome.20120522.bam")

process processA {
	publishDir "${params.output}/${task.hash}", mode: 'copy'

	input:
	val x from processAInput
	file f1 from c1
	file f2 from c2
	file f3 from c3
	file f4 from c4
	file f5 from c5

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
