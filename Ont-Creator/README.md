# Adding a new project to GOREP

This README documents is a guide to introduce new projects in GOREP. In first place, the data have to be introduced in a concrete format we are describing just now. We need three files, two of them with metadata and other with the expression matrix. We are describing the format of these files:

## Metadata files

As we said, we need two documents for the metadata. The first one has the data of the project, and the other is a table with the metdata of each cell studied in the project.

### Project information

This file is a csv (with comma separator) with key - value pairs with no header. A [template](project_info_template.csv) is given in this GitHub. If a field does not have a value, you can remove the row or leave the key with a blank value.

The fields of the document are:

- **_id_**: An unique identified for the project (can be the ID of the project in array express, for example).
- **_title_**: The title of the project.
- **_short_name_**: A short name for the project (you can use it if the title is too long to identify the project quickly).
- **_description_**: A description of the project.
- **_update_date_**: The current date.
- **_load_date_**: The date when the project was uploaded.
- **_array_express_id_**: The id of the project in [_Array Express_](https://www.ebi.ac.uk/arrayexpress/).
- **_ENA_id_**: The id of the project in [ENA](https://www.ebi.ac.uk/ena/browser/home).
- **_GEO_id_**: The id of the project in [GEO](https://www.ncbi.nlm.nih.gov/geo/).
- **_INSD_project_id_**: The id of the project in the INSD. 
- **_INSD_study_id_**: The id of the study in the INSD.
- **_institution_**: The institution in which the project has been created.
- **_collection_**: Collection from where the project has been taken. You can specificaate GOREP if the project has not got a collection.
- **_repository_**: Same as collection but with the repository.
- **_publication_title_**: The title(s) of the publication(s) of the project.
- **_publication_link_**: The link(s) of the publication(s) of the project.

If one of these fields is misspelled or does not exists, the code will throw an error and the project won't be created.

### Metadata table

Once again, this file is a csv with header. This table has a number of rows equals to the number of cells studied in the project and a number of columns equals to the number of metadata variables used to characterize the cells. Once again, a [template](metadata_table_template.csv) of the file is given in the repository. In this table, the values of the metadata has to have the same names as the values of the instances in the ontology. You can use the [metadata searching tool in the REST API](http://77.83.99.74:5000/swagger#/metadata) of the respository.

The column names (metadata) are:

- **_assay_**: Name of the cell.
- **_specie_**: Specie of the sample.
- **_cell_type_**: Type of the cell of the sample.
- **_disease_**: Disease of the sample, or control.
- **_organism_part_**: Part of the organism of the sample.
- **_biopsy_site_**:
- **_metastatic_site_**:
- **_model_**:
- **_instrument_**:
- **_library_**:
- **_preservation_**_
- **__sex__**_
- **_min_age_**_
- **_max_age_**:
- **_age_unit_**:
- **_cell_line_**:
- **_genotype_**:
- **_growth_condition_**:
- **_nucleic_acid_source_**:
- **_organism_status_**:
- **_phenotype_**:
- **_sample_type_**:
- **_stimulus_**:
- **_strain_**:
- **_experimental_factor_**:

If you do not want to use some of these fields just leave it blank or remove the column.

If one of these fields is misspelled or does not exists, the code will throw an error and the project won't be created.
