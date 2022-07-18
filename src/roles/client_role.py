# noinspection PyUnresolvedReferences
import src.database_related.psql_requests as req
# noinspection PyUnresolvedReferences
import src.custom_qt_widgets.message_boxes as msg


class ClientRole:

    def __init__(self, client_name, connection):
        self.login = client_name
        self.connection = connection
        self.information = req.get_client_info(connection, client_name)
