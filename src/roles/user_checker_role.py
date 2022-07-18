# noinspection PyUnresolvedReferences
import src.database_related.db_connection as db_conn
# noinspection PyUnresolvedReferences
import config.constants as con


class UserCheckerRole:
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(UserCheckerRole, cls).__new__(cls)
            cls.conf = db_conn.read_config_file(con.Const.USER_CHECKER_ROLE_CONFIG_PATH)
            cls.connection = db_conn.connect_to_db(cls.conf)

        return cls.instance