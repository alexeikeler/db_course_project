import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from config.constants import Const
from functools import partial
import src.custom_qt_widgets.functionality as widget_funcs

admin_form, admin_base = uic.loadUiType(uifile=Const.ADMIN_UI_PATH)


class AdminForm(admin_form, admin_base):
    def __init__(self, user):

        super(admin_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.create_acc_button.clicked.connect(self.create_employee_account)
        self.hide_password_button.clicked.connect(
            partial(
                widget_funcs.hide_password,
                self.empl_password_line_edit
            )
        )

        # TEST
        self.position_combo_box.addItems(
            (
                Const.ROLES.DIRECTOR_ROLE,
                Const.ROLES.ADMIN_ROLE,
                Const.ROLES.MANAGER_ROLE,
                Const.ROLES.SHOP_ASSISTANT_ROLE
            )
        )
        # TETS DATA
        self.empl_login_line_edit.setText("test_admin_role")
        self.empl_password_line_edit.setText("123123")
        self.empl_firstname_line_edit.setText("test_firstname")
        self.empl_lastname_line_edit.setText("test_lastname")
        self.empl_email_line_edit.setText("123123@gmail.com")
        self.empl_phone_line_edit.setText("+380977681111")
        self.position_combo_box.setCurrentText("admin")
        self.pow_spin_box.setValue(4)
        self.salary_double_spin_box.setValue(15000.00)

    def create_employee_account(self):

        Requests.create_employee(
            self.user.connection,
            self.empl_lastname_line_edit.text(),
            self.empl_firstname_line_edit.text(),
            self.position_combo_box.currentText(),
            self.salary_double_spin_box.value(),
            self.empl_phone_line_edit.text(),
            self.empl_email_line_edit.text(),
            self.empl_login_line_edit.text(),
            self.empl_password_line_edit.text(),
            self.pow_spin_box.value()
        )

    def load_clients_table(self):
        pass

    def load_employees_table(self):
        pass