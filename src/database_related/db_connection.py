import psycopg2 as pc2
import logging
from configparser import ConfigParser

# noinspection PyUnresolvedReferences
import src.database_related.psql_requests as req
# noinspection PyUnresolvedReferences
import src.roles.user_checker_role as ucr
# noinspection PyUnresolvedReferences
import config.constants as con


logging.basicConfig(level=logging.INFO)


def read_config_file(filename, section="postgresql") -> dict:
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    config_data = dict()
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            config_data[param[0]] = param[1]
    else:
        raise Exception(f"Section {section} not found in the {filename} file")

    return config_data


def connect_to_db(connection_params: dict):

    """Connect to psql database server"""

    try:
        connection = pc2.connect(**connection_params)
        return connection

    except(Exception, pc2.DatabaseError) as error:
        raise ValueError(error)


def make_client_connection():
    client_conf = read_config_file(con.Const.CLIENT_ROLE_CONFIG_PATH)
    client_conn = connect_to_db(client_conf)
    return client_conn