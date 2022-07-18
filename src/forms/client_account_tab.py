import src.database_related.psql_requests as Requests
import src.custom_qt_widgets.message_boxes as msg

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from typing import Tuple
from functools import partial

from src.forms.change_password_form import ChangePasswordForm

from config.constants import Const

user_acc_form, user_acc_base = uic.loadUiType(uifile=Const.USER_ACCOUNT_TAB_FORM_UI_PATH)


class ClientAccountTab(user_acc_form, user_acc_base):

    def __init__(self, user):

        super(user_acc_base, self).__init__()
        self.setupUi(self)

        self.user = user
        self.line_edits = {
            'login': self.login_line_edit,
            'first_name': self.first_name_line_edit,
            'last_name': self.last_name_line_edit,
            'phone_number': self.phone_num_line_edit,
            'email': self.email_line_edit,
            'delivery_address': self.delivery_address_line_edit
        }

        self.change_password_form = None

        self.config_widgets()
        self.load_user_data()

    def config_widgets(self):

        pixmap = QtGui.QPixmap(Const.IMAGES_PATH.format("client_login_icon"))
        self.client_icon_label.setPixmap(pixmap)
        self.client_icon_label.setScaledContents(True)
        self.client_icon_label.setSizePolicy(
            QtWidgets.QSizePolicy.Ignored,
            QtWidgets.QSizePolicy.Ignored
        )

        self.change_login_button.clicked.connect(
            partial(self.update_client_info, 'login')
        )
        self.change_first_name_button.clicked.connect(
            partial(self.update_client_info, 'first_name')
        )
        self.change_last_name_button.clicked.connect(
            partial(self.update_client_info, 'last_name')
        )
        self.change_phone_number_button.clicked.connect(
            partial(self.update_client_info, 'phone_number')
        )
        self.change_email_button.clicked.connect(
            partial(self.update_client_info, 'email')
        )
        self.change_delivery_address_button.clicked.connect(
            partial(self.update_client_info, 'delivery_address')
        )

        self.change_password_button.clicked.connect(self.chg_password)

    #@staticmethod
    #def get_user_data(connection, login) -> Tuple:
    #    data = Requests.get_client_info(connection, login)
    #    return data

    def load_user_data(self):
        login = self.user.login

        if login != self.login_line_edit.text() and self.login_line_edit.text():
            login = self.login_line_edit.text()

        user_info = list(self.user.information.values())
        line_edits = list(self.line_edits.values())

        for index, column in enumerate(user_info):
            line_edits[index].setText(user_info[index])
            line_edits[index].setAlignment(QtCore.Qt.AlignCenter)

    def update_client_info(self, update_subject):

        line_edit = self.line_edits.get(update_subject)
        new_value = line_edit.text()

        flag = Requests.update_client_info(self.user.connection, self.user.login, update_subject, new_value)

        if flag is not None and flag[0]:
            msg.info_message(f"{update_subject} changed succsessfully.")
            self.load_user_data()
        else:
            msg.error_message(f"Error occured while changing: {update_subject}")

    def chg_password(self):
        self.change_password_form = ChangePasswordForm(self.user)
        self.change_password_form.show()