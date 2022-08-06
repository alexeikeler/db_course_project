import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

from config.constants import Const, Order
from src.custom_qt_widgets import message_boxes as msg
from src.database_related import psql_requests as Requests

cart_form, cart_base = uic.loadUiType(uifile=Const.SHOP_CART_TAB_UI_PATH)


class ShoppingCartTab(QtWidgets.QWidget):
    def __init__(self, user):
        super(ShoppingCartTab, self).__init__()

        self.user = user
        self.main_layout = QtWidgets.QGridLayout(self)

        self.orders_table = QtWidgets.QTableWidget()

        self.orders_table.setColumnCount(len(Order.ORDER_DF_COLUMNS) + 1)
        header = self.orders_table.horizontalHeader()
        for header_index in range(1, len(Order.ORDER_DF_COLUMNS) - 2):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        self.main_layout.addWidget(self.orders_table, *Order.ORDER_TABLE_SIZE)

        self.main_layout.setContentsMargins(0, 0, 0, 0)

    def add_order_in_database(self, order_values):
        order_id = Requests.add_order(self.user.connection, *order_values)
        return order_id[0]

    def add_order_in_qt_table(self, order: pd.DataFrame):

        rows, cols = order.shape

        self.orders_table.setHorizontalHeaderLabels(order.columns)
        self.orders_table.setSizeAdjustPolicy(
            QtWidgets.QAbstractScrollArea.AdjustToContents
        )

        self.orders_table.insertRow(self.orders_table.rowCount())

        book_image = QtWidgets.QTableWidgetItem()
        book_image.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format(order["Title"][0])))
        self.orders_table.setItem(self.orders_table.rowCount() - 1, 0, book_image)
        self.orders_table.setIconSize(QtCore.QSize(150, 100))

        self.orders_table.resizeColumnsToContents()
        header = self.orders_table.horizontalHeader()
        for header_index in range(2, len(Order.ORDER_DF_COLUMNS) - 2):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)
        self.orders_table.resizeRowsToContents()

        confirm_order_button = QtWidgets.QPushButton("")
        confirm_order_button.setIcon(
            QtGui.QIcon(Const.IMAGES_PATH.format("check_mark"))
        )
        confirm_order_button.clicked.connect(self.confirm_order)

        decline_order_button = QtWidgets.QPushButton("")
        decline_order_button.setIcon(
            QtGui.QIcon(Const.IMAGES_PATH.format("delete_review"))
        )
        decline_order_button.clicked.connect(self.decline_order)

        self.orders_table.setCellWidget(
            self.orders_table.rowCount() - 1, cols - 1, decline_order_button
        )
        self.orders_table.setCellWidget(
            self.orders_table.rowCount() - 1, cols - 2, confirm_order_button
        )

        for i in range(1, cols - 2):
            item = QtWidgets.QTableWidgetItem(str(order.loc[0][i]))
            item.setTextAlignment(QtCore.Qt.AlignCenter)
            item.setFlags(QtCore.Qt.ItemIsEnabled)
            self.orders_table.setItem(self.orders_table.rowCount() - 1, i, item)

    def decline_order(self):
        try:
            current_row = self.orders_table.currentRow()
            # ordering_date = self.orders_table.item(current_row, 3).text()
            order_id = int(self.orders_table.item(current_row, 1).text())
            Requests.update_user_order(
                self.user.connection, order_id, Order.ORDER_DECLINED
            )
            self.orders_table.removeRow(current_row)

            msg.info_message("Order successfully declined.")

        except Exception as e:
            msg.error_message(str(e))

    def confirm_order(self):
        try:
            current_row = self.orders_table.currentRow()
            order_id = int(self.orders_table.item(current_row, 1).text())
            Requests.update_user_order(
                self.user.connection, order_id, Order.ORDER_PAYED
            )
            self.orders_table.removeRow(current_row)

            msg.info_message("Order successfully payed.")

        except Exception as e:
            msg.error_message(str(e))
