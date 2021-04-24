import psycopg2 as psql
from Postgres_connection import PostgresConnection

#region Create table commands

percentiles_table = '''
    DROP TABLE IF EXISTS percentiles;

    CREATE TABLE percentiles (
        id SERIAL PRIMARY KEY,
        project_id VARCHAR(255) NOT NULL,
        metadata JSON,
        gene_name VARCHAR(255) NOT NULL,
        percentile float NOT NULL,
        number_genes INTEGER NOT NULL,
        number_cells INTEGER NOT NULL
    );
'''

modules_table = '''
    DROP TABLE IF EXISTS modules CASCADE;

    CREATE TABLE modules (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL
    );
'''

module_membership_table = '''
    DROP TABLE IF EXISTS module_membership CASCADE;

    CREATE TABLE module_membership (
        id SERIAL PRIMARY KEY,
        project_id VARCHAR(255) NOT NULL,
        correction VARCHAR(255) NOT NULL,
        iter_pseudocells INTEGER NOT NULL,
        metadata JSON,
        module INTEGER NOT NULL,
        gene_name VARCHAR(255) NOT NULL,
        MM float NOT NULL,
        FOREIGN KEY (module) 
            REFERENCES modules (id) 
            ON UPDATE CASCADE ON DELETE CASCADE
    );
'''

notation_table = '''
    DROP TABLE IF EXISTS notation CASCADE;

    CREATE TABLE notation (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        notation_id VARCHAR(255) NOT NULL,
        source VARCHAR(255) NOT NULL,
        IC float NULL
    );
'''

phenotype_notation_table = '''
    DROP TABLE IF EXISTS phenotype_notation CASCADE;

    CREATE TABLE phenotype_notation (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        notation_id VARCHAR(255) NOT NULL,
        source VARCHAR(255) NOT NULL
    );
'''

notation_bridge_table = '''
    DROP TABLE IF EXISTS notation_bridge CASCADE;

    CREATE TABLE notation_bridge (
        module_id INTEGER,
        notation_id INTEGER,
        PRIMARY KEY (module_id, notation_id),
        FOREIGN KEY (module_id) 
            REFERENCES modules (id) 
            ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (notation_id) 
            REFERENCES notation (id) 
            ON UPDATE CASCADE ON DELETE CASCADE
    );
'''

phenotype_notation_bridge_table = '''
    DROP TABLE IF EXISTS phenotype_notation_bridge CASCADE;

    CREATE TABLE phenotype_notation_bridge (
        module_id INTEGER,
        phenotype_notation_id INTEGER,
        PRIMARY KEY (module_id, phenotype_notation_id),
        FOREIGN KEY (module_id) 
            REFERENCES modules (id) 
            ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (phenotype_notation_id) 
            REFERENCES phenotype_notation (id) 
            ON UPDATE CASCADE ON DELETE CASCADE
    );
'''
#endregion

commands = [
    percentiles_table,
    modules_table,
    module_membership_table,
    notation_table,
    phenotype_notation_table,
    notation_bridge_table,
    phenotype_notation_bridge_table
]

# Running all commands in postgres
with PostgresConnection() as conn:
    cur = conn.cursor()

    # create table one by one
    for command in commands:
        cur.execute(command)
    # commit the changes
    conn.commit()

    # read tables
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables
        WHERE table_schema = 'public'
    """)

    tables = cur.fetchall()

    if len(tables) == len(commands):
        print('Tables have been correctly created')
    else:
        print('Some error has occur during tables creation')

    # close communication with the PostgreSQL database server
    cur.close()
