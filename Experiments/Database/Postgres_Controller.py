import psycopg2
from Postgres_connection import PostgresConnection


class PostgresController(object):

    def __init__(self):
        super()

    def test_con(self):
        with PostgresConnection() as conn:
            cur = conn.cursor()

            print('PostgreSQL database version:')

            cur.execute('SELECT version()')
            db_version = cur.fetchone()
            print(db_version)

            cur.close()

    def add_percentile(self, project_id, gene_name, percentile, number_genes, number_cells, metadata={}):
        percentile_id = -1
        metadata_str = str(metadata).replace("'", '"')

        command = f"""
            INSERT INTO percentiles (project_id,
                                     metadata,
                                     gene_name,
                                     percentile,
                                     number_genes,
                                     number_cells)
            VALUES ('{project_id}', 
                    '{metadata_str}',
                    '{gene_name}',
                    {percentile},
                    {number_genes},
                    {number_cells})
    
            RETURNING id;
        """

        with PostgresConnection() as conn:
            # create cursor of the connection
            cur = conn.cursor()
            # run command
            cur.execute(command)
            percentile_id = cur.fetchone()
            # close communication with the PostgreSQL database server
            cur.close()
            # commit the changes
            conn.commit()

        return percentile_id
