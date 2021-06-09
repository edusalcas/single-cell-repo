# ¿What is GOREP?

GOREP (Global Omics REPository) aims to be a single-entry point for computational biologists, data analysts and clinicians working with single-cell data as a source of evidence for their investigations. GOREP is a set of meta-databases on single-cell that, currently, can be accessed through Web interfaces. GOREP integrate the Human Cell Atlas (HCA) https://www.humancellatlas.org/ databases of single cell repositories and the Single Cell Expression Atlas (SCEA), https://www.ebi.ac.uk/gxa/sc/home all in one.

# GOREP installation

This is a guide to install GOREP system in your machines. It is a very easy to follow guide in which the installation consists of a step by step as the services are virtualized and all the scripts and files are in this repository. The three services of the system are:

- **secoresearch/fuseki**: Image of Fuseki in which we are going to upload our ontology, and that will allow us to make queries in the ontology through the API.
- **edusalcas/sc-api**: This is the image of the RESTful API. This image implements a Python progam using Flask. We will be able to access to all the data of the repository using this.
- **postgres**: Relational database in which we save all the percentiles and the coexpression nets created.

Prerequisites:

- Docker.
- Python 3.7 or higher.
  - Pyscopg2 2.8.6 or higher.
  - Requests 2.10.0 or higher

## Deploy system

[Here](https://github.com/edusalcas/single-cell-repo/blob/main/docker-compose.yml) we can download the docker-compose file. In this file we can modify the password of the Fuseki service, as well as the user, password and the name of the database. In addition, we can indicate the path for the local volume of Postgres service, or remove the volume in you do not want a persintent database. 

By placing yourself in the same directory as the docker-compose file, we can execute the command `docker-compose up -d` to launch the three services. -d option runs the services in background. With the command `docker-compose down` we can remove all the containers created. In addition, you can stop all the services with the command `docker-compose stop`.

We can access the services created with the docker-compose as follows:

- In localhost:5000/swagger you can access to the swagger of the API.
- In localhost:3030 you can access to the Fuseki service.
- Postgres service is in its standard port (5432).

Both the database and the Fuseki service are initialized empty. The following sections explain how to add instances to these databases.

Note: docker-compose will automaticaly download the images of the services if you do not have them in your machine.

## Add ontology to Fuseki

The ontology that Fuseki uses needs to have a concrete structure. In this repository you can find the [empty ontology](https://github.com/edusalcas/single-cell-repo/blob/Ont-Creator/Ont-Creator/JavaWorkspace-OntCreator/single_cell/files/singleCellRepositoriesv6_withURIs.owl) that you can use to add instances and then upload it to Fuseki.

Go to localhost:3030, "add file" in the dataset "ds" and upload your ontology in owl format under the graph with the name you want.

## Creating ontology with the correct format

TODO

## Initialize Postgres database

First, you will have to configure [Postgres Controller](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Database/Postgres_Controller.py) file with the user, password and database name. Then, run the [database initialization](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Database/Create_tables.py) script, which will create the schema of the database for the percentiles and the coexpression networks. Finally, you can populate the database with the percentiles with this [notebook](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Percentiles/Percentile_generation.ipynb), or use it as an example of how to make use of the functions. It is important to note that the projects for which you want to create the percentiles must be uploaded to the fuseki service.

# GOREP usage

This is an index of the content of the repository:

- [Data acquisition](https://github.com/edusalcas/single-cell-repo/tree/Ont-Creator/Ont-Creator): Explain the way to download the data from the repositories, process it and add all the information to the ontology.
- [GOREP content](https://github.com/edusalcas/single-cell-repo/tree/Experiments/Experiments): Explain percentile creation, database schema creation and insert instances to the database.
- [API-REST](https://github.com/edusahttps://github.com/edusalcas/single-cell-repo/blob/Ont-Creator/Ont-Creator/JavaWorkspace-OntCreator/single_cell/files/singleCellRepositoriesv6_withURIs.owllcas/single-cell-repo/tree/API-REST/API-REST): Explain the API, buildt in Python with Flask, and how to use it.

# Credits

Developer: Eduardo Salmerón Castaño - eduardo.salmeronc@um.es
Computational biologist: Alicia Gómez Pascual - alicia.gomez1@um.es
AI specialist: Juan A. Botía - juanbotiablaya@gmail.com
