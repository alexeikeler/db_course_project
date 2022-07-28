import pandas as pd

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from tabulate import tabulate

from config.constants import Order, Const

shop_assistant_form, shop_assistant_base = uic.loadUiType(uifile=Const.SHOP_ASSISTANT_UI_PATH)


class ShopAssistantForm(shop_assistant_form, shop_assistant_base):

    def __init__(self, user):

        super(shop_assistant_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.sa_orders_table.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)
        self.sa_orders_table.setIconSize(QtCore.QSize(150, 100))

        self.load_orders_table()

    def load_orders_table(self):

        orders = pd.DataFrame(
            Requests.get_shop_assistant_orders(
                self.user.connection,
                self.user.login
            ),
            columns=Order.SA_ORDER_DF_COLUMNS
        )
        orders.insert(0, "Book", "")
        print(
            tabulate(
                orders, headers=orders.columns, tablefmt='pretty'
            )
        )

        rows, cols = orders.shape
        self.sa_orders_table.setRowCount(rows)
        self.sa_orders_table.setColumnCount(cols)

        header = self.sa_orders_table.horizontalHeader()
        for header_index in range(2, len(Order.SA_ORDER_DF_COLUMNS)-3):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        self.sa_orders_table.setHorizontalHeaderLabels(orders.columns)

        for i in range(rows):

            book_image = QtWidgets.QTableWidgetItem()
            book_image.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format(orders["Title"][i])))

            order_states = QtWidgets.QComboBox()
            order_states.addItems((Order.ORDER_PAYED, Order.ORDER_PROCESSED, Order.ORDER_DELIVERING, Order.ORDER_FINISHED))
            print(orders["State"][i])
            order_states.setCurrentText(orders["State"][i])


            self.sa_orders_table.setItem(i, 0, book_image)
            self.sa_orders_table.setCellWidget(i, 1, order_states)


            for j in range(2, cols):
                item = QtWidgets.QTableWidgetItem(str(orders.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.sa_orders_table.setItem(i, j, item)

        self.sa_orders_table.resizeColumnsToContents()
        self.sa_orders_table.resizeRowsToContents()

    def load_reviews_table(self):
        pass

