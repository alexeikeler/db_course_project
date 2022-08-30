import logging
from functools import partial

import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

import src.custom_qt_widgets.functionality as widget_funcs
import src.database_related.psql_requests as Requests
from config.constants import Const, Errors, Order, Sales, ShopAndEmployee
from src.custom_qt_widgets import message_boxes as msg
from src.forms.orders_history_form import OrdersHistoryForm

admin_form, admin_base = uic.loadUiType(uifile=Const.ADMIN_UI_PATH)


class AdminForm(admin_form, admin_base):
    def __init__(self, user):

        super(admin_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.tab_widget.setTabText(0, "Admin panel")
        self.orders_history_form = None

        self.update_employees_table.clicked.connect(self.load_employees_table)
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

        self.criterias_combo_box.addItems(ShopAndEmployee.EMPLOYEE_ACTIVITY_DF_COLUMNS)
        self.criterias_combo_box.currentTextChanged.connect(
            lambda criteria: self.search_line_edit.setCompleter(
                QtWidgets.QCompleter(
                    self._get_empl_data()[criteria].unique().astype(str)
                )
            )
        )
        self.criterias_combo_box.setCurrentText("Login")
        self.search_employee_button.clicked.connect(self.search_employees)

        self.load_clients_table()
        self.load_employees_table()
        #       self.prep_autocompler()

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

    def _get_empl_data(self):
        return pd.DataFrame(
            Requests.employee_activity(self.user.connection),
            columns=ShopAndEmployee.EMPLOYEE_ACTIVITY_DF_COLUMNS,
        ).fillna(0)

    def _get_cli_data(self):
        return pd.DataFrame(
            Requests.client_activity(self.user.connection),
            columns=ShopAndEmployee.CLIENT_ACTIVITY_DF_COLUMNS,
        ).fillna(Errors.NO_ORDER)

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
        data = self._get_cli_data()
        self.fill_clients_table(data)

    def fill_clients_table(self, cli_data: pd.DataFrame):

        cli_data.insert(cli_data.shape[1], "Orders history", "")
        cli_data.insert(cli_data.shape[1], "Delete account", "")

        rows, cols = cli_data.shape
        oldest_order_col = 2
        newest_order_col = 3

        widget_funcs.config_table(
            self.clients_table,
            rows,
            cols,
            cli_data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.Stretch),
                (2, QtWidgets.QHeaderView.Stretch),
                (3, QtWidgets.QHeaderView.Stretch),
                (4, QtWidgets.QHeaderView.ResizeToContents),
                (5, QtWidgets.QHeaderView.ResizeToContents),
            ],
            enable_column_sort=True,
        )

        for i in range(rows):

            review_orders_button = QtWidgets.QPushButton("")
            review_orders_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("order_icon"))
            )
            review_orders_button.clicked.connect(self.view_client_orders)

            delete_acc_button = QtWidgets.QPushButton("")
            delete_acc_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon"))
            )
            delete_acc_button.clicked.connect(self.delete_client_account)

            for j in range(cols - 2):
                item = QtWidgets.QTableWidgetItem(str(cli_data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)

                if j == oldest_order_col or j == newest_order_col:
                    if cli_data.loc[i][j] == Errors.NO_ORDER:
                        item.setBackground(QtGui.QColor("red"))
                    else:
                        item.setBackground(QtGui.QColor("green"))

                self.clients_table.setItem(i, j, item)

            self.clients_table.setCellWidget(i, cols - 2, review_orders_button)
            self.clients_table.setCellWidget(i, cols - 1, delete_acc_button)

    def delete_client_account(self):

        current_row = self.clients_table.currentRow()
        id = int(self.clients_table.item(current_row, 0).text())

        if id in ShopAndEmployee.DUMMY_ACC_IDS:
            msg.error_message(Errors.DUMMY_ACC_DEL_ERROR)
            return

        result = Requests.delete_client(self.user.connection, id)

        if not result:
            msg.error_message(Errors.CLIENT_DEL_ERROR.format(id))
            return

        msg.info_message(f"Account with {id=} deleted.")

    def view_client_orders(self):

        current_row = self.clients_table.currentRow()
        client_login = self.clients_table.item(current_row, 1).text()
        having_orders = self.clients_table.item(current_row, 2).text()

        if having_orders == Errors.NO_ORDER:
            msg.error_message(Errors.CLIENT_NO_ORDERS.format(client_login))
            return

        data = pd.DataFrame(
            Requests.get_client_orders(self.user.connection, client_login),
            columns=Order.CLIENT_ORDERS_COLUMNS,
        ).fillna(Const.EMPTY_CELL)

        self.orders_history_form = OrdersHistoryForm(data)
        self.orders_history_form.exec()

    def load_employees_table(self):
        data = self._get_empl_data()
        self.fill_employees_table(data)

    def fill_employees_table(self, empl_data: pd.DataFrame):

        self.employees_table.disconnect()

        empl_data["Reviews"] = empl_data["Reviews"].astype(int)
        empl_data.insert(empl_data.shape[1], "Delete", "")

        rows, cols = empl_data.shape
        widget_funcs.config_table(
            self.employees_table,
            rows,
            cols,
            empl_data.columns,
            [
                *[(i, QtWidgets.QHeaderView.ResizeToContents) for i in range(cols - 1)],
                (cols - 1, QtWidgets.QHeaderView.Stretch),
            ],
            enable_column_sort=False,
        )

        for i in range(rows):

            delete_button = QtWidgets.QPushButton("")
            delete_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon"))
            )
            delete_button.clicked.connect(self.delete_employee_account)

            for j in range(cols - 1):
                item = QtWidgets.QTableWidgetItem(str(empl_data.iloc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)

                if j == ShopAndEmployee.EMPL_REVIEW_COL:
                    item.setFlags(QtCore.Qt.ItemIsEnabled)

                self.employees_table.setItem(i, j, item)

            self.employees_table.setCellWidget(i, cols - 1, delete_button)

        self.employees_table.itemChanged.connect(self.change_employee_data)

    def change_employee_data(self, item):

        row, col = item.row(), item.column()

        hor_name = self.employees_table.horizontalHeaderItem(col).text()
        update_subject = ShopAndEmployee.EMPLOYEE_ACTIVITY_DF_COLUMNS.get(
            hor_name, None
        )

        data = self.employees_table.item(row, col).text()
        id = int(self.employees_table.item(row, 0).text())

        if update_subject is None:
            msg.error_message(Errors.ERROR_UPD_SUBJ)
            return

        result = Requests.update_employee_data(
            self.user.connection, update_subject, data, id
        )

        if not result:
            msg.error_message(
                Errors.ERROR_EMPL_UPDATE.format(id, row, col, data, update_subject)
            )

    def search_employees(self):
        criteria = self.criterias_combo_box.currentText()
        search_text = self.search_line_edit.text()

        match criteria:
            case "ID":
                search_text = int(search_text)
            case "Salary":
                search_text = float(search_text)

        data = self._get_empl_data()
        data = data[data[criteria] == search_text]

        self.fill_employees_table(data)

    def delete_employee_account(self):
        curr_row = self.employees_table.currentRow()
        empl_id = int(self.employees_table.item(curr_row, 0).text())
        pow = int(self.employees_table.item(curr_row, 5).text()[-1])
        pos = self.employees_table.item(curr_row, 6).text()

        if self.user.id == empl_id:
            msg.error_message(Errors.SELF_ACC_DEL_ERROR)
            return

        if empl_id in ShopAndEmployee.DUMMY_ACC_IDS:
            msg.error_message(Errors.DUMMY_ACC_DEL_ERROR)
            return

        logging.info(
            f"Deleting employee with {empl_id=}, {type(empl_id)}, {pos=}, {pow=}."
        )

        msg.warning_message(
            "Warning! All reviews about this employee also will be deleted!"
        )

        result = Requests.delete_employee(self.user.connection, empl_id, pos, pow)

        if not result:
            msg.error_message(Errors.ERROR_EMPL_DELETION.format(empl_id))
            return

        msg.info_message(f"Employee #{empl_id} deleted successfully")
