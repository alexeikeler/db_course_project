import logging

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.db_connection as db_conn
import src.roles.client_role as cr
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore

from src.roles.user_checker_role import UserCheckerRole
from src.forms.create_account_form import AccountForm
from src.forms.shop_form import ShopForm

from config.constants import Const, Errors, ShopAndEmployee

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

        self.role_action = {
            Const.ROLES.CLIENT_ROLE: self.__client_role_start
        }

        # For client test
        self.username_line_edit.setText('test_login')
        self.password_line_edit.setText('test_password')

    def __client_role_start(self, client_login, client_role):
        client_conn = db_conn.establish_db_connection(client_role)

        if client_conn is None:
            msg.error_message(Errors.ERROR_DB_CONNECTION)
            return

        client = cr.ClientRole(client_login, client_conn)

        self.close()

        self.shop_form = ShopForm(client)
        self.shop_form.update_form()
        self.shop_form.show()

    def __shop_assistant_role_start(self, shop_assistant_login):
        pass


    def login_user(self):

        user_login: str = self.username_line_edit.text()
        user_password: str = self.password_line_edit.text()

        if not (user_login and user_password):
            msg.error_message(Errors.NO_LOG_OR_PASS)
            return

        user_checker = UserCheckerRole()
        user_role = Requests.check_user_existence(user_checker.connection, user_login, user_password)

        if user_role is None:
            msg.error_message(Errors.WRONG_USR_NAME_OR_PASS)

        else:
            user_checker.connection.close()

            logging.info(f"\n user_checker logged off successfully.\n")
            logging.info(f"\nUser {user_login} ({user_role[0]}) logged in successfully.\n")

            role_function = self.role_action.get(user_role[0])
            role_function(user_login, user_role[0])


    def toggle_password_visibility(self):
        if self.password_line_edit.echoMode() == QtWidgets.QLineEdit.Normal:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Password)
        else:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Normal)

    def create_account(self):
        self.account_form = AccountForm()
        self.account_form.show()