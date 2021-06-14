import psycopg2


class PostgresConnection(object):

    def __enter__(self):
        # connect to the PostgreSQL server
        self.conn = psycopg2.connect(
            host="194.4.103.57",
            database="sc-db",
            user="sc-user",
            password="single-cell21."
        )

        return self.conn

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.conn.close()
