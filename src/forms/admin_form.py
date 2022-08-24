import pandas as pd

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from functools import partial

import src.custom_qt_widgets.functionality as widget_funcs
import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests

from src.forms.orders_history_form import OrdersHistoryForm
from config.constants import Const, Sales, Errors, Order


admin_form, admin_base = uic.loadUiType(uifile=Const.ADMIN_UI_PATH)


class AdminForm(admin_form, admin_base):
    def __init__(self, user):

        super(admin_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.orders_history_form = None

        self.create_acc_button.clicked.connect(self.create_employee_account)
        self.hide_password_button.clicked.connect(
            partial(widget_funcs.hide_password, self.empl_password_line_edit)
        )

        self.position_combo_box.addItems(
            (
                Const.ROLES.DIRECTOR_ROLE,
                Const.ROLES.ADMIN_ROLE,
                Const.ROLES.MANAGER_ROLE,
                Const.ROLES.SHOP_ASSISTANT_ROLE,
            )
        )

        self.load_clients_table()

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
            self.pow_spin_box.value(),
        )

    def load_clients_table(self):
        data = pd.DataFrame(
            Requests.client_activity(self.user.connection),
            columns=Sales.CLIENT_ACTIVITY_DF_COLUMNS
        ).fillna(value=Errors.NO_ORDER)

        data.insert(data.shape[1], "Orders history", "")
        data.insert(data.shape[1], "Delete account", "")

        rows, cols = data.shape
        oldest_order_col = 2
        newest_order_col = 3

        widget_funcs.config_table(
            self.clients_table,
            rows,
            cols,
            data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.Stretch),
                (2, QtWidgets.QHeaderView.Stretch),
                (3, QtWidgets.QHeaderView.Stretch),
                (4, QtWidgets.QHeaderView.ResizeToContents),
                (5, QtWidgets.QHeaderView.ResizeToContents)
            ],
            enable_column_sort=True
        )

        for i in range(rows):

            review_orders_button = QtWidgets.QPushButton("")
            review_orders_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("order_icon")))
            review_orders_button.clicked.connect(self.view_client_orders)

            delete_acc_button = QtWidgets.QPushButton("")
            delete_acc_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon")))
            delete_acc_button.clicked.connect(self.delete_client_account)

            for j in range(cols - 2):
                item = QtWidgets.QTableWidgetItem(str(data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)

                if j == oldest_order_col or j == newest_order_col:
                    if data.loc[i][j] == Errors.NO_ORDER:
                        item.setBackground(QtGui.QColor("red"))
                    else:
                        item.setBackground(QtGui.QColor("green"))

                self.clients_table.setItem(i, j, item)

            self.clients_table.setCellWidget(i, cols - 2, review_orders_button)
            self.clients_table.setCellWidget(i, cols - 1, delete_acc_button)

    def delete_client_account(self):
        pass

    def view_client_orders(self):

        current_row = self.clients_table.currentRow()
        client_login = self.clients_table.item(current_row, 1).text()
        having_orders = self.clients_table.item(current_row, 2).text()

        if having_orders == Errors.NO_ORDER:
            msg.error_message(Errors.CLIENT_NO_ORDERS.format(client_login))
            return

        data = pd.DataFrame(
            Requests.get_client_orders(
                self.user.connection,
                client_login
            ),
            columns=Order.CLIENT_ORDERS_COLUMNS
        ).fillna(Const.EMPTY_CELL)

        self.orders_history_form = OrdersHistoryForm(data)
        self.orders_history_form.exec()

    def load_employees_table(self):
        pass
