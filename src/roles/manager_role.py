import src.database_related.psql_requests as Requests


class ManagerRole:
    def __init__(self, login, connection):
        self.connection = connection
        self.login = login
        self.id = Requests.get_employee_id(self.connection, self.login)
        print(self.id)
