from functools import partial

import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from tabulate import tabulate

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
import src.plotter.plotter as Plotter
from config.constants import Const, Order
from src.forms.change_password_form import ChangePasswordForm

user_acc_form, user_acc_base = uic.loadUiType(
    uifile=Const.USER_ACCOUNT_TAB_FORM_UI_PATH
)


class ClientAccountTab(user_acc_form, user_acc_base):
    def __init__(self, user):

        super(user_acc_base, self).__init__()
        self.setupUi(self)

        self.user = user
        self.line_edits = {
            "login": self.login_line_edit,
            "first_name": self.first_name_line_edit,
            "last_name": self.last_name_line_edit,
            "phone_number": self.phone_num_line_edit,
            "email": self.email_line_edit,
            "delivery_address": self.delivery_address_line_edit,
        }

        self.change_password_form = None
        self.orders = None

        self.config_widgets()
        self.load_client_data()
        # self.load_client_orders()
        # self.load_client_stats()

    def get_client_orders(self):
        self.orders = pd.DataFrame(
            Requests.get_client_orders(self.user.connection, self.user.login),
            columns=Order.CLIENT_ORDERS_COLUMNS,
        ).fillna("-")

        print(tabulate(self.orders, headers=self.orders.columns, tablefmt="pretty"))
        self.orders.insert(0, "Book", "")

    def config_widgets(self):

        pixmap = QtGui.QPixmap(Const.IMAGES_PATH.format("client_login_icon"))
        self.client_icon_label.setPixmap(pixmap)
        self.client_icon_label.setScaledContents(True)
        # self.client_icon_label.setSizePolicy(
        #     QtWidgets.QSizePolicy.Ignored,
        #     QtWidgets.QSizePolicy.Ignored
        # )

        self.change_login_button.clicked.connect(
            partial(self.update_client_info, "login")
        )
        self.change_first_name_button.clicked.connect(
            partial(self.update_client_info, "first_name")
        )
        self.change_last_name_button.clicked.connect(
            partial(self.update_client_info, "last_name")
        )
        self.change_phone_number_button.clicked.connect(
            partial(self.update_client_info, "phone_number")
        )
        self.change_email_button.clicked.connect(
            partial(self.update_client_info, "email")
        )
        self.change_delivery_address_button.clicked.connect(
            partial(self.update_client_info, "delivery_address")
        )

        self.change_password_button.clicked.connect(self.chg_password)
        self.update_orders_button.clicked.connect(self.load_client_orders)
        self.update_stat_button.clicked.connect(self.load_client_stats)

    def load_client_data(self):
        login = self.user.login
        if login != self.login_line_edit.text() and self.login_line_edit.text():
            login = self.login_line_edit.text()

        user_info = list(self.user.information.values())
        line_edits = list(self.line_edits.values())

        for index, column in enumerate(user_info):
            line_edits[index].setText(user_info[index])
            line_edits[index].setAlignment(QtCore.Qt.AlignCenter)

    def load_client_orders(self):

        self.get_client_orders()

        rows, cols = self.orders.shape

        self.all_orders.setColumnCount(cols)
        self.all_orders.setRowCount(rows)
        self.all_orders.setHorizontalHeaderLabels(self.orders.columns)
        self.all_orders.setSortingEnabled(True)
        self.all_orders.setIconSize(QtCore.QSize(150, 100))

        header = self.all_orders.horizontalHeader()
        for header_index in range(2, cols):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        for i in range(rows):

            book_image = QtWidgets.QTableWidgetItem()
            book_image.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format(self.orders["Title"][i]))
            )
            self.all_orders.setItem(i, 0, book_image)

            for j in range(1, cols):

                item = QtWidgets.QTableWidgetItem(str(self.orders.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                self.all_orders.setItem(i, j, item)

        # self.all_orders.resizeColumnsToContents()
        self.all_orders.resizeRowsToContents()

    def load_client_stats(self):
        try:
            Plotter.order_statuses_piechart(self.web_view, self.orders)

        except Exception as e:
            msg.error_message(str(e))

    def update_client_info(self, update_subject):

        line_edit = self.line_edits.get(update_subject)
        new_value = line_edit.text()

        flag = Requests.update_client_info(
            self.user.connection, self.user.login, update_subject, new_value
        )

        if flag is not None and flag[0]:
            msg.info_message(f"{update_subject} changed succsessfully.")
            if update_subject == "login":
                self.user.login = self.login_line_edit.text()

        else:
            msg.error_message(f"Error occured while changing: {update_subject}")

    def chg_password(self):
        self.change_password_form = ChangePasswordForm(self.user)
        self.change_password_form.show()
