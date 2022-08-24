import logging
from functools import partial
from time import sleep

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtWidgets, uic

import src.custom_qt_widgets.functionality as widget_funcs
import src.custom_qt_widgets.message_boxes as msg
import src.database_related.db_connection as db_conn
import src.database_related.psql_requests as Requests
from config.constants import Const, Errors
from src.forms.admin_form import AdminForm
from src.forms.create_account_form import AccountForm
from src.forms.manager_form import ManagerForm
from src.forms.shop_assistant_form import ShopAssistantForm
from src.forms.shop_form import ShopForm
from src.roles.admin_role import AdminRole
from src.roles.client_role import ClientRole
from src.roles.manager_role import ManagerRole
from src.roles.shop_assistant_role import ShopAssistantRole
from src.roles.user_checker_role import UserCheckerRole

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
        self.eyepassword_button.clicked.connect(
            partial(widget_funcs.hide_password, self.password_line_edit)
        )

        self.roles = {
            Const.ROLES.CLIENT_ROLE: ClientRole,
            Const.ROLES.SHOP_ASSISTANT_ROLE: ShopAssistantRole,
            Const.ROLES.MANAGER_ROLE: ManagerRole,
            Const.ROLES.ADMIN_ROLE: AdminRole,
        }

        self.forms = {
            Const.ROLES.CLIENT_ROLE: ShopForm,
            Const.ROLES.SHOP_ASSISTANT_ROLE: ShopAssistantForm,
            Const.ROLES.MANAGER_ROLE: ManagerForm,
            Const.ROLES.ADMIN_ROLE: AdminForm,
        }

        # ----------------------------------------------------------
        # For client test
        # ----------------------------------------------------------

        #self.username_line_edit.setText("test_login")
       # self.password_line_edit.setText("test_password")

        # self.username_line_edit.setText("TamaraKanaeva605")
        # self.password_line_edit.setText("dnFfoXzs06WX")

        # ----------------------------------------------------------

        # ----------------------------------------------------------
        # For shop_assistant test
        # ----------------------------------------------------------

        # SHOP 1
        self.username_line_edit.setText("petrov_vasilii")
        self.password_line_edit.setText("ptrvV1988")

        # SHOP 2
        # self.username_line_edit.setText("PavlovSergei")
        # self.password_line_edit.setText("IqmKAOZTbT38")

        # SHOP 3
        # self.username_line_edit.setText("anastasijaKutuzova")
        # self.password_line_edit.setText("2Jm0mmC9OyXb")

        # SHOP 4
        # self.username_line_edit.setText("colcevaleksei")
        # self.password_line_edit.setText("GtImkfbccufq")

        # SHOP 5
        # self.username_line_edit.setText("BrejnewDmitro")
        # self.password_line_edit.setText("Yl4DNzNpqNpM")

        # ----------------------------------------------------------
        # For manager test
        # ----------------------------------------------------------

        # SHOP 1
        # self.username_line_edit.setText("ekaterina_makarchuck")
        # self.password_line_edit.setText("ekaterina98765")

        # SHOP 2
        # self.username_line_edit.setText("evelinaKOJINA")
        # self.password_line_edit.setText("bh68Lloo3cYg")

        # SHOP 3
        # self.username_line_edit.setText(arnoldEgorov)
        # self.password_line_edit.setText(xBreZcu8VI5D)

        # SHOP 4
        # self.username_line_edit.setText(lilianaOst)
        # self.password_line_edit.setText(tyhM0VIzxM5S)

        # SHOP 5
        # self.username_line_edit.setText(IsaevNikita)
        # self.password_line_edit.setText(48wRADXq1b2d)

        # ----------------------------------------------------------
        # For admin test
        # ----------------------------------------------------------
        # SHOP 1

        # self.username_line_edit.setText("makarov_daniiL")
        # self.password_line_edit.setText("mkrvdnl83492")

        # SHOP 2
        #self.username_line_edit.setText("eleonora_kruj")
        #self.password_line_edit.setText("JUKSeKdDG6v6")

        # SHOP 3
        # self.username_line_edit.setText("ribakova_marija")
        # self.password_line_edit.setText("YkZzMo1cCst8")

        # SHOP 4
        # self.username_line_edit.setText("ribakova_marija")
        # self.password_line_edit.setText("jc7fRWsAmGUS")

        # SHOP 5
        # self.username_line_edit.setText("kropotovAndrei")
        # self.password_line_edit.setText("MdRKPBpzkuWM")

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

    def create_account(self):
        self.account_form = AccountForm()
        self.account_form.show()
