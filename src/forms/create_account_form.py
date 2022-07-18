import src.custom_qt_widgets.message_boxes as msg_box
import src.database_related.db_connection as db_conn
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore
from config.constants import Const

create_acc_form, create_acc_base = uic.loadUiType(uifile=Const.CREATE_ACCOUNT_UI_PATH)


class AccountForm(create_acc_form, create_acc_base):

    def __init__(self):

        super(create_acc_base, self).__init__()
        self.setupUi(self)

        self.create_account_button.clicked.connect(self.create_acc)

        self.firstname_line_edit.setText("test_firstname"),
        self.lastname_line_edit.setText("test_lastname"),
        self.phone_number_line_edit.setText("+380999999999"),
        self.email_line_edit.setText("asd@gmail.com"),
        self.login_line_edit.setText("test_login"),
        self.password_line_edit.setText("test_password"),
        self.delivery_address_line_edit.setText("test_address")

        self.client_conn = db_conn.make_client_connection()

    def create_acc(self) -> None:

        line_edits = (
            self.firstname_line_edit.text(),
            self.lastname_line_edit.text(),
            self.phone_number_line_edit.text(),
            self.email_line_edit.text(),
            self.login_line_edit.text(),
            self.password_line_edit.text(),
            self.delivery_address_line_edit.text()
        )

        for line in line_edits[:-1]:
            if len(line) == 0:
                msg_box.error_message("There are empty lines in login form!")
                return

        Requests.create_user(self.client_conn, *line_edits)

        self.client_conn.commit()
        self.client_conn.close()
        self.close()


