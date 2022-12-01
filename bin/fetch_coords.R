#! /usr/bin/env Rscript

suppressPackageStartupMessages({library(optparse)})
suppressPackageStartupMessages({library(readr)})
suppressPackageStartupMessages({library(tidyverse)})


option_list = list(
  make_option(c("--gene_input"), action="store", default='gene_input.tsv', type='character',
              help="Input file with gene names.")
)

args = parse_args(OptionParser(option_list=option_list))

genes <- readr::read_tsv(args$gene_input, col_names = F, "c") %>% 
    head(10) %>% 
    dplyr::pull(X1)

res_37 <- str_split('~{sep=" " grch37_resources}', " ")
res_38 <- str_split('~{sep=" " grch38_resources}', " ")

for (build in c(res_37, res_38)) {
    genome_build <- build[2]
    coords_file <- readr::read_tsv(build[1], col_names = F, "cnncc")

# [ Search gene ] 
    gene_output <- coords_file %>% 
    filter(X4 %in% genes) %>% 
    add_column(type_input = "gene") %>% 
    unite(., X1, X4, X5, sep = "_", col = "internalID", remove = F) 

    # [ Search ensembl ]
    ensembl_output <- coords_file %>% 
    filter(X5 %in% genes) %>% 
    add_column(type_input = "ensembl") %>% 
    unite(., X1, X4, X5, sep = "_", col = "internalID", remove = F) 

    # [ Produce initial list ]
    list_output <- 
    bind_rows(gene_output, ensembl_output) %>% 
    rename("chr" = X1, 
        "start" = X2, 
        "end" = X3,
        "gene" = X4,
        "ensemblID" = X5,
        "originalInput" = type_input,
        "internalID" = internalID) %>%
    unite(., chr, start, end, sep = "_", col = "posTag", remove = F) %>% 
    select(chr, start, end, gene, ensemblID, internalID, posTag, originalInput)

    # [ Handle duplicate locations and filter ]
    list_output_dedup <- 
    list_output %>% 
    select(posTag) %>% 
    filter(duplicated(.) == T) %>% 
    distinct() %>% 
    left_join(list_output, by = c("posTag")) %>% 
    group_by(posTag) %>% 
        summarise(
        "entryDuplicate" = paste0(internalID, collapse = ", ")
        ) %>% 
    full_join(list_output, ., by = c("posTag")) %>% 
    distinct(posTag, .keep_all = T)

    # Temporary hard filter on autosomes, sex-chromosomes and mitochondrial genome
    restricted_chr_b37 <- c(1:22, "X","Y","MT") # b37
    restricted_chr_b38 <- paste0("chr",c(1:22, "X","Y","M"), sep = "") # b38
    hardRestrict <- c(restricted_chr_b37, restricted_chr_b38)
    list_output_dedup <- list_output_dedup %>% filter(chr %in% hardRestrict)

    non_detected_genes <- genes[(!genes %in% list_output_dedup$gene & !genes %in% list_output_dedup$ensemblID)] 
    if(length(non_detected_genes) != 0) {
    as.data.frame(non_detected_genes) %>% 
        write_tsv(paste("Genes_not_search_",genome_build,"_~{timestamp}.txt", sep=""), col_names=FALSE)
    }

list_output_dedup %>%
    write_tsv(paste("adjustedInput_",genome_build,"_~{timestamp}.tsv", sep=""), col_names = T)

list_output_dedup %>%
    write_tsv(paste(genome_build,"_coordinates.tsv", sep=""), col_names = F)
            