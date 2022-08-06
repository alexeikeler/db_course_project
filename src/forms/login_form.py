import logging
from time import sleep

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtWidgets, uic

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.db_connection as db_conn
import src.database_related.psql_requests as Requests
from config.constants import Const, Errors
from src.forms.create_account_form import AccountForm
from src.forms.shop_assistant_form import ShopAssistantForm
from src.forms.shop_form import ShopForm
from src.forms.manager_form import ManagerForm
from src.roles.client_role import ClientRole
from src.roles.shop_assistant_role import ShopAssistantRole
from src.roles.user_checker_role import UserCheckerRole
from src.roles.manager_role import ManagerRole

login_form, login_base = uic.loadUiType(uifile=Const.LOGIN_UI_PATH)


class LoginForm(login_form, login_base):
    def __init__(self):

        super(login_base, self).__init__()
        self.setupUi(self)

        self.account_form = None
        self.role_form = None

        self.menubar.hide()
        self.statusbar.hide()

        self.login_button.clicked.connect(self.login_user)
        self.create_new_account_button.clicked.connect(self.create_account)
        self.eyepassword_button.clicked.connect(self.toggle_password_visibility)

        self.roles = {
            Const.ROLES.CLIENT_ROLE: ClientRole,
            Const.ROLES.SHOP_ASSISTANT_ROLE: ShopAssistantRole,
            Const.ROLES.MANAGER_ROLE: ManagerRole
        }

        self.forms = {
            Const.ROLES.CLIENT_ROLE: ShopForm,
            Const.ROLES.SHOP_ASSISTANT_ROLE: ShopAssistantForm,
            Const.ROLES.MANAGER_ROLE: ManagerForm
        }

        # For client test
        # self.username_line_edit.setText('test_login')
        # self.password_line_edit.setText('test_password')

        # For shop_assistant test
        # self.username_line_edit.setText("petrov_vasilii")
        # self.password_line_edit.setText("ptrvV1988")

        # For manager test
        self.username_line_edit.setText("ekaterina_makarchuck")
        self.password_line_edit.setText("ekaterina98765")

    def __role_start(self, login, role):
        conn = db_conn.establish_db_connection(role)
        logging.info(f"Logging in as {login} - {role}.")

        if conn is None:
            msg.error_message(Errors.ERROR_DB_CONNECTION)
            return

        self.close()

        self.role_form = self.forms.get(role)(self.roles.get(role)(login, conn))
        self.role_form.show()

    def login_user(self):

        user_login: str = self.username_line_edit.text()
        user_password: str = self.password_line_edit.text()

        if not (user_login and user_password):
            msg.error_message(Errors.NO_LOG_OR_PASS)
            return

        user_checker = UserCheckerRole()
        user_role = Requests.check_user_existence(
            user_checker.connection, user_login, user_password
        )

        # To assure that user checker exists.
        # sleep(10)

        if user_role is None:
            msg.error_message(Errors.WRONG_USR_NAME_OR_PASS)

        else:
            user_checker.connection.close()

            logging.info(f"\n user_checker logged off successfully.\n")
            self.__role_start(user_login, user_role[0])

    def toggle_password_visibility(self):
        if self.password_line_edit.echoMode() == QtWidgets.QLineEdit.Normal:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Password)
        else:
            self.password_line_edit.setEchoMode(QtWidgets.QLineEdit.Normal)

    def create_account(self):
        self.account_form = AccountForm()
        self.account_form.show()
