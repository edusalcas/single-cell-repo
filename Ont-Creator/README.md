# Adding a new project to GOREP

This README documents is a guide to introduce new projects in GOREP. In first place, the data have to be introduced in a concrete format we are describing just now. We need three files, two of them with metadata and other with the expression matrix. We are describing the format of these files:

## Metadata files

As we said, we need two documents for the metadata. The first one has the data of the project, and the other is a table with the metdata of each cell studied in the project.

### Project information

This file is a csv (with comma separator) with key - value pairs with no header. A [template](project_info_template.csv) is given in this GitHub. If a field does not have a value leave the key with a blank value.

The fields of the document are:

- **_id_**: An unique identified for the project (can be the ID of the project in array express, for example).
- **_title_**: The title of the project.
- **_short_name_**: A short name for the project (you can use it if the title is too long to identify the project quickly).
- **_description_**: A description of the project.
- **_update_date_**: The current date.
- **_load_date_**: The date when the project was uploaded.
- **_array_express_id_**: The id of the project in [Array Express](https://www.ebi.ac.uk/arrayexpress/).
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
- **_individual_**: Id of the individual of the sample.
- **_specie_**: Specie of the sample (HomoSapiens).
- **_cell_type_**: Type of the cell of the sample (DopaminergicNeuron).
- **_disease_**: Disease of the sample, or control (ParkinsonsDisease).
- **_organism_part_**: Part of the organism of the sample (Brain).
- **_biopsy_site_**: Concrete site in the organism part where the sample has been taken (Cortex).
- **_metastatic_site_**: Part of the tumor where the sample has been taken (Core).
- **_instrument_**: Instrument used for sequencing the cell (IllumiaHiSeq2000).
- **_library_**: Library used fir equencing the cell (Smart-seq).
- **_preservation_**: Preservation method used in the cell sample (Fresh).
- **_sex_**: Biological sex of the specimen (female).
- **_min_age_**: The minimun age of the group of the donors of the specimen.
- **_max_age_**: The maximun age of the group of the donors of the specimen.
- **_age_unit_**: Unit in which the age is expressed.
- **_cell_line_**: Name of the used cell line.
- **_nucleic_acid_source_**: Type of sequencing used (SingleCell or SingleNucleus)
- **_sample_type_**: CellLines, Organoids or Specimen.

If you do not want to use some of these fields just leave it blank.

If one of these fields is misspelled or does not exists, the code will throw an error and the project won't be created.

## Matrix file

On the other hand, each project needs a matrix with the expression information (normalized and filtered) of each gene for each cell of the project. Such matrix is going to be of size NxM, where we have N genes in the rows and M cells in the columns of the matrix. To keep the file size as small as possible, the .mtx format should be used to represent the matrix. In addition, two files should also be created to indicate the name of the genes and cells (in both files the delimiter will be a line break). The gene names should be in ensembl format. The files will be compressed in zip format to try to keep the file size as small as possible. The files should be named as follows:

- **Zip file**: _project_id_-normalised-files.zip
- **Matrix**: _project_id_.aggregated_filtered_normalised_counts.mtx
- **Cell names**: _project_id_.aggregated_filtered_normalised_counts.mtx_cols
- **Gene names**: _project_id_.aggregated_filtered_normalised_counts.mtx_rows

Where _project_id_ is the ID of the projects indicated in the _project_info_ file.
