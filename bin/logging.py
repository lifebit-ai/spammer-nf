#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
Script for logging input parameters + logging workflow metadata
"""

from datetime import datetime

SCRIPT_DESCRIPTION = """
#==================================================================================
# script for logging input parameters + pipeline metadata for Gene Variant Workflow
#
# Date: 2022-06-24
# Version: 0.0.1
#==================================================================================
"""

r_ver = "~{R_container}".split("/")[-1]
bcftools_ver = "~{bcftools_container}".split("/")[-1]
vep_ver = "~{vep_container}".split("/")[-1]
vep_options = "~{vep_config_file}"
vep_extra_options = ~{vep_conf}

timestamp = datetime.now()
with open (f"gene_variant_logfile_{timestamp}".replace(" ", "_").replace(":", "_"), "w") as outfile:
    outfile.write(f"The timestamp on this workflow was: {timestamp}")
    outfile.write(f"\nThis workflow was run on the ~{data_version}\n")
    outfile.write("\nProgram and database versions used in this workflow:")
    outfile.write(f"\n R version: {r_ver}")
    outfile.write(f"\n bcftools version: {bcftools_ver}")
    outfile.write(f"\n VEP version: {vep_ver}")
    outfile.write(f"\n VEP cache version: ~{vep_cache_version}")
    outfile.write("\n\nVEP options file content:\n")
    with open(vep_options, "r") as vep_file:
    for line in vep_file.readlines():
        outfile.write(line)
outfile.write("\nExtra configs for VEP annotation:")
for key, value in vep_extra_options.items():
    outfile.write(f"\n* Extra configs for {key}...\n")
    for entry in value:
        outfile.write(f"{entry}\n")