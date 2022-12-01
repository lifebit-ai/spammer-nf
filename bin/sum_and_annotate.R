#! /usr/bin/env Rscript

library(tidyverse)

variant <- read_tsv("~{variants}", col_types = "cncccnnnnnnn", col_names = c("CHROM", "POS", "ID", "REF", "ALT", "AN", "AC","AC_Hom", "AC_Het", "AC_Hemi", "MAF", "NS")) %>%
setNames(paste0(names(.), '_variant')) %>%
group_by(ID_variant) %>%
mutate(DUP_variant = n()) %>%
ungroup()

annotation <- read_tsv("~{annotated_variants}", comment = "##", col_names = T) %>%
setNames(paste0(names(.), '_annotation')) %>%
rename("ID_variant" = `#Uploaded_variation_annotation`)

hets <- read_tsv("~{hets}", col_names = c("ID_variant", "Het_Samples"))
homs <- read_tsv("~{homs}", col_names = c("ID_variant", "Hom_Samples"))
hemis <- read_tsv("~{hemis}", col_names = c("ID_variant", "Hemi_Samples"))

if( "~{genesource}" == "gene" ) {
    variant_annotation <- variant %>%
    left_join(annotation, by = "ID_variant") %>%
    filter(SYMBOL_annotation %in% c("~{gene}")) %>%
    dplyr::select(contains("_variant"), contains("_annotation"))
}

if( "~{genesource}" == "ensembl" ) {
    variant_annotation <- variant %>%
    left_join(annotation, by = "ID_variant") %>%
    filter(Gene_annotation %in% c("~{ensembl}")) %>%
    dplyr::select(contains("_variant"), contains("_annotation"))
}

if(!is_empty(hets)){
    variant_annotation <- variant_annotation %>%
    left_join(hets, by = "ID_variant")
}
if(!is_empty(homs)){
    variant_annotation <- variant_annotation %>%
    left_join(homs, by = "ID_variant")
}
if(!is_empty(hemis)){
    variant_annotation <- variant_annotation %>%
    left_join(hemis, by = "ID_variant")
}

write.table(variant_annotation,file="~{filetag}_~{genome_version}_annotated_variants.tsv",sep="\t",col.names=T,row.names=F,quote=F)