# API

In this part of the project there is the RESTful API of GOREP. The API is buildt in Python with the Flask library. In the file [resources](app/projects/api_v1_0/resources.py) the paths of the API specified. To connect the API with the database we have the class [Postgres_Controller](app/db_conn/Postgres_Controller.py) and with the class [fuseki_con](app/db_conn/fuseki_con.py) with the ontology.

# API usage

Here we are going to explain how to use the API, what does eaxch path do and several forms of access to the data. First of all, note we are going to use 127.0.0.1 as the IP, but you have to use the IP of the machine you are hosting the system. By default the API uses port 5000, we will use this port in the examples.

## The paths of the API

- 127.0.0.1:5000/**swagger**: This path opens the Swagger documentation of the API. Here we can see all the paths, parameters and examples of use.
- 127.0.0.1:5000/**percentiles**: This is the path we will use to query for the percentiles. We will indicate a filter in JSON format and the API will return the percentiles that meet this filter. The parameters we can add to the filters are: gene_names, cell_types, disease, specie and project_ID.
- 127.0.0.1:5000/**project**: With this path we can get aa subset of the projects in Fuseki server that meets some specifications. We can specificate the disease, cell type and sex studied on the project.
- 127.0.0.1:5000/**project/info/{project_id}**: Using this URL we can get the information of a project in the Fuseki service indicating the ID of the project.
- 127.0.0.1:5000/**project/downloads/{project_id}**: The download links of a project can be obtain using this path.
- 127.0.0.1:5000/**project/metadata/{param}**: Giving a metadata name, we can get all the values available in the ontology. This path can be useful for getting values which we are using in other queries as _percentiles_ or _project/info_.

## Examples and output of each path

In this examples we are going to use the `curl` command from UNIX terminal, but you can use anythink you want, like requests library for Python.

### Percentiles 

Since curly braces, brackets and other characters cannot appear in the URL, we have to encode the JSON of the filter to put it in curl. So given this JSON filter:

```json
{
	"project_IDs": [
		"E-MTAB-7303"
	],
	"gen_names": [
		"ENSG00000116288"
	],
	"cell_types": [
		"DopaminergicNeuron"
	],
	"disease": [
		"ParkinsonsDisease",
		"Control"
	]
}
```
We get the following curl command:

```bash
curl -X GET "http://localhost:5001/percentiles?filters=%7B++%0D%0A%09%22project_IDs%22%3A+%5B%0D%0A%09%09%22E-MTAB-7303%22%0D%0A%09%5D%2C%0D%0A%09%22gen_names%22%3A+%5B%0D%0A%09%09%22ENSG00000116288%22%0D%0A%09%5D%2C%0D%0A%09%22cell_types%22%3A+%5B%0D%0A%09%09%22DopaminergicNeuron%22%0D%0A%09%5D%2C%0D%0A%09%22disease%22%3A+%5B%0D%0A%09%09%22ParkinsonsDisease%22%2C%0D%0A%09%09%22Control%22%0D%0A%09%5D%0D%0A%7D" -H  "accept: application/json"
```

And we obtain the response with the percentiles that fulfill the filter:

```json
[
  {
    "gene_name": "ENSG00000116288", 
    "metadata": {
      "cell type": "DopaminergicNeuron", 
      "developmental stage": "Adult", 
      "disease": "ParkinsonsDisease", 
      "organism": "HomoSapiens", 
      "organism part": "Skin"
    }, 
    "number_cells": 37, 
    "number_genes": 15892, 
    "percentile": 98.03045557513215, 
    "project_id": "E-MTAB-7303"
  }, 
  {
    "gene_name": "ENSG00000116288", 
    "metadata": {
      "cell type": "DopaminergicNeuron", 
      "developmental stage": "Adult", 
      "disease": "Control", 
      "organism": "HomoSapiens", 
      "organism part": "Skin"
    }, 
    "number_cells": 86, 
    "number_genes": 17035, 
    "percentile": 98.21543880246551, 
    "project_id": "E-MTAB-7303"
  }
]
```

### Project

This is a simpler one. There we just have to specifie one or more parameters. For example, if we cant to query for Parkinson's Disease projects in male:

```bash
curl -X GET "http://localhost:5001/project?disease=Melanoma&cell_type=Bcell" -H  "accept: application/json"
```

Giving the following response:

```json
[
  {
    "cellType": [
      "InnateLymphoidCell",
      "Tcell",
      "CD8+AlphaBetaTcell",
      "CD11b+CD11c+DC",
      "Bcell",
      "CD11c+DC",
      "CD11b+Macrophages/Monocytes",
      "Cancer-associatedFibroblasts(CAFs)",
      "CD31+Endothelial"
    ],
    "collection": "HumanCellAtlas",
    "description": "The cancer microenvironment is a complex ecosystem characterized by dynamic interactions between diverse cell types, including malignant, immune and stromal cells. Here, we performed single-cell RNA sequencing on CD45+ and CD45- cells isolated from tumour and lymph nodes during a mouse model of melanoma. The transcriptional profiles of these individual cells taken at different time points coupled with assembled T cell receptor sequences, allowed us to identify distinct immune subpopulations and delineate their developmental trajectory. Our study provides insights into the complex interplay among cells within the tumour microenvironment and presents a valuable resource for future translational applications.",
    "disease": "Melanoma",
    "institution": [
      "EMBL-EBI",
      "Newcastle University",
      "Wellcome Trust Sanger Institute",
      "University of Cambridge",
      "University of Helsinki",
      "DKFZ German Cancer Research Center"
    ],
    "laboratory": [
      "Human Cell Atlas Data Coordination Platform",
      "Institute of Cellular Medicine",
      "Sarah Teichmann",
      "MRC Cancer Unit"
    ],
    "organismPart": [
      "Skin",
      "LymphNode",
      "Tumor"
    ],
    "projectTitle": "Melanoma infiltration of stromal and immune cells",
    "project_ID": "8c3c290d-dfff-4553-8868-54ce45f4ba7f",
    "repository": "HumanCellAtlas",
    "sex": "female",
    "specimenCount": "54"
  }
]
```

### Project/info

Here we just have to specify the id of a project in the Fuseki service:

```bash
curl -X GET "http://localhost:5001/project/info/E-CURD-55" -H  "accept: application/json"
```

The API returns this answer:

```json
{
  "cellType": null,
  "disease": [
    "COVID-19",
    "Control"
  ],
  "instrument": null,
  "library": "10X5v2Sequencing",
  "organismPart": "Blood",
  "projectLink": "https://www.ebi.ac.uk/gxa/sc/experiments/E-CURD-55/results/tsne",
  "projectTitle": "Immune cell profiling of COVID-19 patients in the recovery stage by single-cell sequencing",
  "publicationLink": "https://europepmc.org/abstract/MED/32780218",
  "publicationTitle": "A human circulating immune cell landscape in aging and COVID-19.",
  "specie": "HomoSapiens"
}
```

### Project/downloads

Just as the last path, we just jave to indicate the ID:

```bash
curl -X GET "http://localhost:5001/project/downloads/E-CURD-55" -H  "accept: application/json"
```

These are the download links of the projects specified:

```json
[
  {
    "clusteringLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download?fileType=cluster&accessKey=",
    "experimentDesignLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download?fileType=experiment-design&accessKey=",
    "experimentMetadataLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download/zip?fileType=experiment-metadata&accessKey=",
    "markerGenesLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download/zip?fileType=marker-genes&accessKey=",
    "normalisedCountsLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download/zip?fileType=normalised&accessKey=",
    "project_ID": "E-CURD-55",
    "rawCountsLink": "https://www.ebi.ac.uk/gxa/sc/experiment/E-CURD-55/download/zip?fileType=quantification-raw&accessKey="
  }
]
```
### Project/metadata

Lastly, we can use the metadata query to get, for example, all the values for the metadata 'specie':

```bash
curl -X GET "http://localhost:5001/project/metadata/specie" -H  "accept: application/json"
```

And these are all the species we have on the ontology:

```json
[
  "AnophelesGambiae",
  "ArabidopsisThaliana",
  "CaenorhabditisElegans",
  "CallithrixJacchus",
  "DanioRerio",
  "DrosophilaMelanogaster",
  "GallusGallus",
  "HomoSapiens",
  "MusMusculus",
  "PlasmodiumBerghei",
  "PlasmodiumFalciparum",
  "RattusNorvegicus",
  "SaccharomycesCerevisiae",
  "SchistosomaMansoni",
  "Specie"
]
```
