import logging

import src.custom_qt_widgets.message_boxes as msg_box
import src.database_related.db_connection as db_conn
import src.roles.client_role as cr
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore

from src.roles.user_checker_role import UserCheckerRole
from src.forms.create_account_form import AccountForm
from src.forms.shop_form import ShopForm

from config.constants import Const

login_form, login_base = uic.loadUiType(uifile=Const.LOGIN_UI_PATH)


class LoginForm(login_form, login_base):

    def __init__(self):

        super(login_base, self).__init__()
        self.setupUi(self)
        self.account_form = None
        self.shop_form = None
        self.menubar.hide()
        self.statusbar.hide()
        self.login_button.clicked.connect(self.login_user)
        self.create_new_account_button.clicked.connect(self.create_account)
        self.eyepassword_button.clicked.connect(self.toggle_password_visibility)

        # For test
        self.username_line_edit.setText('test_login')
        self.password_line_edit.setText('test_password')

    def login_user(self):

        user_login: str = self.username_line_edit.text()
        user_password: str = self.password_line_edit.text()

        if not (user_login and user_password):
            msg_box.error_message(Const.NO_LOG_OR_PASS)
            return

        user_checker = UserCheckerRole()
        user_role = Requests.check_user_existence(user_checker.connection, user_login, user_password)
        print(user_role)
#        user_role = db_conn.check_user(user_name, user_password)

        if user_role is None:
            msg_box.error_message(Const.WRONG_USR_NAME_OR_PASS)

        else:
            user_checker.connection.close()
            logging.info(f"\nUser {user_login} logged in successfully.\n")
            logging.info(f"\n user_checker logged off successfully.\n")

            if user_role[0] == "client":

                client_conn = db_conn.make_client_connection()
                client = cr.ClientRole(user_login, client_conn)

                self.close()

                self.shop_form = ShopForm(client)
                self.shop_form.update_form()
                self.shop_form.show()

    def toggle_password_visibility(self):
        if self.password_line_edit.echoMode() == QtWidgets.QLineEdit.Normal:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Password)
        else:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Normal)

    def create_account(self):

        self.account_form = AccountForm()
        self.account_form.show()