import pandas as pd

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from tabulate import tabulate

from config.constants import Order, Const
from functools import partial
shop_assistant_form, shop_assistant_base = uic.loadUiType(uifile=Const.SHOP_ASSISTANT_UI_PATH)


class ShopAssistantForm(shop_assistant_form, shop_assistant_base):

    def __init__(self, user):

        super(shop_assistant_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.orders_data = None
        self.reviews_data = None

        self.reload_orders_button.clicked.connect(self.load_orders_table)
        self.update_orders_button.clicked.connect(self.update_orders_state)

        self.sa_orders_qtable.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)
        self.sa_orders_qtable.setIconSize(QtCore.QSize(150, 100))
        self.load_orders_table()

        self.tab_widget_layout.setContentsMargins(0, 0, 0, 0)
        self.menubar.hide()
        self.statusbar.hide()

    def get_orders_data(self):
        self.orders_data = pd.DataFrame(
            Requests.get_shop_assistant_orders(
                self.user.connection,
                self.user.login
            ),
            columns=Order.SA_ORDER_DF_COLUMNS
        )
        self.orders_data.insert(0, "Book", "")
        self.orders_data.insert(self.orders_data.shape[1], "Update order", "")

    def get_reviews_data(self):
        pass

    def load_orders_table(self):

        self.get_orders_data()
        self.sa_orders_qtable.clear()

        rows, cols = self.orders_data.shape
        self.sa_orders_qtable.setRowCount(rows)
        self.sa_orders_qtable.setColumnCount(cols)

        header = self.sa_orders_qtable.horizontalHeader()
        for header_index in range(3, len(Order.SA_ORDER_DF_COLUMNS) - 2):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        self.sa_orders_qtable.setHorizontalHeaderLabels(self.orders_data.columns)

        for i in range(rows):

            book_image = QtWidgets.QTableWidgetItem()
            book_image.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format(self.orders_data["Title"][i])))

            order_states = QtWidgets.QComboBox()
            order_states.addItems(
                (Order.ORDER_PAYED, Order.ORDER_PROCESSED, Order.ORDER_DELIVERING, Order.ORDER_FINISHED)
            )
            order_states.setCurrentText(self.orders_data["State"][i])

            self.sa_orders_qtable.setCellWidget(i, 2, order_states)

            update_order = QtWidgets.QPushButton("")
            update_order.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("update_icon")))
            update_order.setIconSize(QtCore.QSize(16, 16))
            update_order.clicked.connect(
                partial(
                    self.update_orders_state,
                    int(self.orders_data["Order ID"][i]),
                    i
                )
            )

            self.sa_orders_qtable.setItem(i, 0, book_image)

            self.sa_orders_qtable.setCellWidget(i, cols-1, update_order)

            for j in range(1, cols-1):
                item = QtWidgets.QTableWidgetItem(str(self.orders_data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.sa_orders_qtable.setItem(i, j, item)

        self.sa_orders_qtable.resizeColumnsToContents()
        self.sa_orders_qtable.resizeRowsToContents()

    def load_reviews_table(self):
        pass

    def update_orders_state(self, order_id, row_index):
        print(self.sa_orders_qtable.cellWidget(row_index, 2).currentText())
        #Requests.update_user_order(self.user.connection, order_id, order_state)