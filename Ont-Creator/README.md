# Adding a new proyect to GOREP

This README documents is a guide to introduce new projects in GOREP. In first place, the data have to be introduced in a concrete format we are describing just now. We need three files, two of them with metadata and other with the expression matrix. We are describing the format of these files:

## Metadata files

As we said, we need two documents for the metadata. The first one has the data of the project, and the other is a table with the metdata of each cell studied in the project.

### Project information

This file is a csv (with comma separator) with key - value pairs with no header. A template is given in this GitHub called `project_info_template.csv`. If a field does not have a value, it should be empty in the file too, but the pair has to exist.

The fields of the document are:

- id
- title
- short_name
- description
- update_date
- load_date
- array_express_id
- ENA_id
- GEO_id
- INSD_project_id
- INSD_stufy_id
- institution
- collection
- repository
- publication_title
- publication_link

If one of these fields is not present in the file or some one is misspelled, the code will throw an error and the project won't be created.

### Metadata table

Once again, this file is a csv with header. This table has a number of rows equals to the number of cells studied in the project and a number of columns equals to the number of metadata variables used to characterize the cells. Once again, a template of the file is given in the repository, called `metadata_table_template.csv`. In this table, the values of the metadata has to have the same names as the values of the instances in the ontology. You can use the metadata searching tool in the REST API of the respository.

On the other hand, the column names (metadata) are:

- assay
- specie
- cell_type
- disease
- organism_part
- biopsy_site
- metastatic_site
- model
- instrument
- library
- preservation
- sex
- min_age
- max_age
- age_unit
- cell_line
- genotype
- growth_condition
- nucleic_acid_source
- organism_status
- phenotype
- sample_type
- stimulus
- strain
- experimental_factor

If you do not want to use some of these fields just leave it blank.

If one of these fields or values is not present in the file or some one is misspelled, the code will throw an error and the project won't be created.
