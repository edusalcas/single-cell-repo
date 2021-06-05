# API

In this part of the project there is the RESTful API of GOREP. The API is buildt in Python with the Flask library. In the file [resources](app/projects/api_v1_0/resources.py) the paths of the API specified. To connect the API with the database we have the class [Postgres_Controller](app/db_conn/Postgres_Controller.py) and with the class [fuseki_con](app/db_conn/fuseki_con.py) with the ontology.

