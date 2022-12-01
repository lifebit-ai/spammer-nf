#! /usr/bin/env Rscript

library(Rlabkey)
library(tidyverse)
library(readr)

labkey.setDefaults(baseUrl="https://labkey-embassy.gel.zone/labkey/")

for (build in c('~{sep="','" genome_builds}')) {

    string_1 <- "SELECT g.participant_id, platekey, delivery_id, delivery_date, type, file_path, normalised_consent_form, genome_build"
    string_1B <- ", delivery_version"
    string_2 <- paste("FROM genome_file_paths_and_types AS g
            INNER JOIN participant AS p ON p.participant_id = g.participant_id
            WHERE type IN ('rare disease germline', 'cancer germline')
            AND g.participant_id NOT IN (~{excluded_participant_ids})
            AND genome_build = '",build,"'
            AND file_sub_type = 'Standard VCF'
            AND normalised_consent_form != 'cohort-tracerx'", sep="")
    string_2B <- "AND g.delivery_version != 'Dragen_Pipeline2.0'"
    string_3 <- "AND NOT EXISTS (
                SELECT 1 FROM genome_file_paths_and_types AS g_newer
                WHERE g_newer.participant_id = g.participant_id
                AND g_newer.type = g.type
                AND g_newer.genome_build = g.genome_build
                AND g_newer.file_sub_type = g.file_sub_type
                AND g_newer.delivery_date > g.delivery_date"
    string_3B <- "AND g_newer.delivery_version != 'Dragen_Pipeline2.0'"
    string_4 <- ")"

    if( as.numeric(str_replace(unlist(str_split("~{data_version}","_"))[2],"v","")) > 9 ) {
        input_string <- paste(string_1, string_1B, string_2, string_2B, string_3, string_3B, string_4)
    } else {
        input_string <- paste(string_1, string_2, string_3, string_4)
    }

    labkey.executeSql(
        schemaName = "lists",
        colNameOpt = "rname",
        maxRows = 100000000,
        folderPath = "/main-programme/~{data_version}",
        sql = input_string
    ) %>%
    select(participant_id, platekey, genome_build, file_path) %>%
        write_tsv(paste(build,"_germline_input_vcfs.txt", sep=""), col_names = F)