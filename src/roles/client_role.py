# noinspection PyUnresolvedReferences
# noinspection PyUnresolvedReferences
import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as req


class ClientRole:
    def __init__(self, client_name, connection):
        self.login = client_name
        self.connection = connection
        self.information = req.get_client_info(connection, client_name)

    def update_information(self, new_login):

        if new_login != self.login and new_login is not None:
            self.information = req.get_client_info(self.connection, new_login)
