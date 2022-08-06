from functools import partial

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
from config.constants import Const

chg_pswd_form, chg_pswd_base = uic.loadUiType(uifile=Const.CHANGE_PSWRD_FORM_UI_PATH)


class ChangePasswordForm(chg_pswd_form, chg_pswd_base):
    def __init__(self, user):

        super(chg_pswd_form, self).__init__()
        self.setupUi(self)

        self.old_password = ""
        self.new_password = ""
        self.user = user

        self.change_button.clicked.connect(self.change)
        self.exit_button.clicked.connect(self.close_app)

        self.show_old_password_button.clicked.connect(
            partial(self.toggle_password_visibility, self.old_password_line_edit)
        )
        self.show_new_password_button.clicked.connect(
            partial(self.toggle_password_visibility, self.new_password_line_edit)
        )

    @staticmethod
    def toggle_password_visibility(password_line):

        if password_line.echoMode() == QtWidgets.QLineEdit.Normal:
            password_line.setEchoMode(QtWidgets.QLineEdit.Password)
        else:
            password_line.setEchoMode(QtWidgets.QLineEdit.Normal)

    def change(self):

        self.old_password = self.old_password_line_edit.text()
        self.new_password = self.new_password_line_edit.text()

        if not (self.old_password and self.new_password):
            msg.error_message("Cannot change password when one of lines is empty!")
        else:
            pswrd_flag = Requests.change_password(
                self.user.connection,
                self.user.login,
                self.old_password,
                self.new_password,
            )
            if pswrd_flag[0]:
                msg.info_message("Password changed!")
                self.close_app()
            else:
                msg.error_message("Wrong old password!")

    def close_app(self):
        self.close()
