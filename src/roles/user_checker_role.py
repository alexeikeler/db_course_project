# noinspection PyUnresolvedReferences
import src.database_related.db_connection as db_conn
# noinspection PyUnresolvedReferences
from config.constants import Const


class UserCheckerRole:
    def __new__(cls):
        if not hasattr(cls, "instance"):
            cls.instance = super(UserCheckerRole, cls).__new__(cls)
            cls.connection = db_conn.establish_db_connection(
                Const.ROLES.USER_CHECKER_ROLE
            )

        return cls.instance
