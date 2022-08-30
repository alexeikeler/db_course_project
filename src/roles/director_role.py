import src.database_related.psql_requests as Requests


class DirectorRole:
    def __init__(self, login, connection):
        self.connection = connection
        self.login = login
        self.id, self.place_of_work = Requests.get_employee_main_data(
            self.connection, self.login
        )