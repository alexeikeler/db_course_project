import logging
from configparser import ConfigParser

import psycopg2 as pc2

import src.custom_qt_widgets.message_boxes as msg
from config.constants import Const

logging.basicConfig(level=logging.INFO)

ROLE_CONFIG_FILES: dict = {
    Const.ROLES.SHOP_ASSISTANT_ROLE: Const.SHOP_ASSISTANT_CONFIG_PATH,
    Const.ROLES.CLIENT_ROLE: Const.CLIENT_ROLE_CONFIG_PATH,
    Const.ROLES.USER_CHECKER_ROLE: Const.USER_CHECKER_ROLE_CONFIG_PATH,
    Const.ROLES.MANAGER_ROLE: Const.MANAGER_ROLE_CONFIG_PATH,
    Const.ROLES.ADMIN_ROLE: Const.ADMIN_ROLE_CONFIG_PATH
}


def establish_db_connection(role: str):

    config_file = ROLE_CONFIG_FILES.get(role, None)
    if config_file is None:
        return

    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(config_file)

    # get section, default to postgresql
    config_data = dict()

    if parser.has_section(Const.CONFIG_SECTION):
        params = parser.items(Const.CONFIG_SECTION)
        for param in params:
            config_data[param[0]] = param[1]
    else:
        return

    try:
        connection = pc2.connect(**config_data)
        return connection

    except (Exception, pc2.DatabaseError) as error:
        raise ValueError(error)
