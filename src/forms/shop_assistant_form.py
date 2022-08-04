import PyQt5.QtWidgets
import pandas as pd

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from tabulate import tabulate

from config.constants import Order, Const, WindowsNames, ReviewsMessages, Errors
from src.forms.show_review_form import ShowReview
from functools import partial
shop_assistant_form, shop_assistant_base = uic.loadUiType(uifile=Const.SHOP_ASSISTANT_UI_PATH)


class ShopAssistantForm(shop_assistant_form, shop_assistant_base):

    def __init__(self, user):

        super(shop_assistant_base, self).__init__()
        self.setupUi(self)

        self.tab_widget.setTabText(0, WindowsNames.ORDERS_TAB)
        self.tab_widget.setTabText(1, WindowsNames.EMPLOYEES_REVIEWS_TAB)
        self.tab_widget.setTabText(2, WindowsNames.BOOKS_REVIEWS_TAB)
        self.tab_widget.setTabText(3, WindowsNames.SHOPS_REVIEWS_TAB)

        self.show_review_form = ShowReview()

        self.user = user
        self.orders_data = None
        self.reviews_data = None

        self.reload_orders_button.clicked.connect(self.load_orders_table)
        self.reload_reviews_employees_button.clicked.connect(self.load_employees_reviews_table)
        self.reload_books_reviews_button.clicked.connect(self.load_books_reviews_table)
        self.reload_shops_reviews_button.clicked.connect(self.load_shops_reviews_table)

        self.__config_tables()
        self.load_orders_table()
        self.load_employees_reviews_table()
        self.load_books_reviews_table()
        self.load_shops_reviews_table()

        self.tab_widget_layout.setContentsMargins(0, 0, 0, 0)
        self.menubar.hide()
        self.statusbar.hide()

    def __config_tables(self):

        tables = (
            self.sa_orders_qtable,
            self.employees_reviews_table,
            self.books_reviews_table,
            self.shops_reviews_table
        )
        for table in tables:
            table.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)
            table.setIconSize(QtCore.QSize(150, 100))
            table.resizeColumnsToContents()
            table.resizeRowsToContents()

    def load_employees_reviews_table(self):
        self.get_reviews_data(ReviewsMessages.EMPLOYEES_REVIEWS)
        self.load_reviews_tables(self.employees_reviews_table)

    def load_books_reviews_table(self):
        self.get_reviews_data(ReviewsMessages.BOOKS_REVIEWS)
        self.load_reviews_tables(self.books_reviews_table)

    def load_shops_reviews_table(self):
        self.get_reviews_data(ReviewsMessages.SHOPS_REVIEWS)
        self.load_reviews_tables(self.shops_reviews_table)

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

    def get_reviews_data(self, subject: str):

        self.reviews_data = pd.DataFrame(
            Requests.get_reviews_for_shop_assistant(
                self.user.connection,
                self.user.login,
                subject
            ),
            columns=ReviewsMessages.REVIEWS_DF_COLUMNS
        )
        self.reviews_data.insert(self.reviews_data.shape[1], "Delete review", "")

    def load_orders_table(self):

        self.get_orders_data()
        self.sa_orders_qtable.clear()

        rows, cols = self.orders_data.shape
        self.sa_orders_qtable.setRowCount(rows)
        self.sa_orders_qtable.setColumnCount(cols)

        header = self.sa_orders_qtable.horizontalHeader()
        for header_index in range(2, len(Order.SA_ORDER_DF_COLUMNS) - 2):
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

        self.sa_orders_qtable.resizeRowsToContents()

    def update_orders_state(self, order_id: int, row_index: int):
        order_state = self.sa_orders_qtable.cellWidget(row_index, 2).currentText()
        is_updated = Requests.update_user_order(self.user.connection, order_id, order_state)
        print(is_updated)

        if is_updated:
            msg.info_message(Order.ORDER_STATE_CHANGED.format(order_id, order_state))
        else:
            msg.error_message(Errors.ORDER_STATUS_ERROR.format(order_id))

    def load_reviews_tables(self, table: PyQt5.QtWidgets.QTableWidget):

        table.clear()

        rows, cols = self.reviews_data.shape
        table.setRowCount(rows)
        table.setColumnCount(cols)

        header = table.horizontalHeader()
        for header_index, _ in enumerate(ReviewsMessages.REVIEWS_DF_COLUMNS[1:-1], 1):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        table.setHorizontalHeaderLabels(self.reviews_data.columns)

        for i in range(rows):
            for j in range(cols - 2):
                item = QtWidgets.QTableWidgetItem(str(self.reviews_data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                table.setItem(i, j, item)

            show_review_button = QtWidgets.QPushButton("")
            show_review_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("info")))
            show_review_button.setIconSize(QtCore.QSize(16, 16))
            show_review_button.clicked.connect(
                partial(
                    self.show_review,
                    self.reviews_data.loc[i][cols-2]
                )
            )

            delete_review_button = QtWidgets.QPushButton("")
            delete_review_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("delete_review")))
            delete_review_button.setIconSize(QtCore.QSize(16, 16))
            delete_review_button.clicked.connect(
                partial(
                    self.delete_review,
                    self.reviews_data.loc[i][0]
                )
            )

            table.setCellWidget(i, cols-2, show_review_button)
            table.setCellWidget(i, cols-1, delete_review_button)

    def delete_review(self, review_id):
        Requests.delete_review(
            self.user.connection,
            int(review_id)
        )
        msg.info_message(ReviewsMessages.REVIEW_DELETED)

    def show_review(self, review_text):
        self.show_review_form.set_text(review_text)
        self.show_review_form.show()
