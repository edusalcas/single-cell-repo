# GOREP installation

This is a guide to install GOREP infrastucture in your machines. It is a very easy to follow guide in which the installation consists of a step by step as the services are virtualized and all the scripts and files are in this repository.

## Virtualized services

[Here](https://github.com/edusalcas/single-cell-repo/blob/main/docker-compose.yml) we can download the docker-compose file. In this file we can modify the password of the Fuseki service, as well as the user, password and the name of the database. In addition, we can indicate the path for the local volume of Postgres service, or remove the volume in you do not want a persintent database. 

By placing yourself in the same directory as the docker-compose file, we can execute the command `docker-compose up -d` to launch the three services. -d option runs the services in background. With the command `docker-compose down` we can remove all the containers created.

- In localhost:5000 you can access to the swagger of the API.
- In localhost:3030 you can access to the Fuseki service.
- Postgres service is in its standard port (5432).

Note: docker-compose will automaticaly download the images of the services if you do not have them in your machine.

## Add ontology to fuseki

Go to localhost:3030, "add file" and upload your ontology in owl format under the graph with the name you want.

### Creating ontology with the correct format

TODO

## Initialize Postgres database

First, you will have to configure [Postgres Controller](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Database/Postgres_Controller.py) file with the user, password and database name. Then, run the [database initialization](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Database/Create_tables.py) script. Finally, you can populate the database with the percentiles with this [notebook](https://github.com/edusalcas/single-cell-repo/blob/Experiments/Experiments/Percentiles/Percentile_generation.ipynb).
