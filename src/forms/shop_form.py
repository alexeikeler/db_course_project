from datetime import datetime
from functools import partial

import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from PyQt5.QtCore import Qt
from tabulate import tabulate

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
from config.constants import Const, Order, ShopAndEmployee
from src.custom_qt_widgets import range_slider
from src.forms.book_info_form import BookInfoForm
from src.forms.buy_book_form import BuyBookForm
from src.forms.client_account_tab import ClientAccountTab
from src.forms.employee_reviews_form import EmployeeReviewForm
from src.forms.shop_reviews_form import ShopReviewForm
from src.forms.shopping_cart_tab import ShoppingCartTab

shop_form, shop_base = uic.loadUiType(uifile=Const.SHOP_FORM_UI_PATH)


class ShopForm(shop_form, shop_base):
    def __init__(self, user):

        super(shop_base, self).__init__()
        self.setupUi(self)
        self.user = user

        self.slider = None
        self.full_book_info_form = None
        self.buy_book_form = None
        self.employee_reviews_form = None
        self.shop_review_form = None

        self.shopping_cart_tab = ShoppingCartTab(self.user)
        self.client_acc_tab = ClientAccountTab(self.user)

        self.search_button.clicked.connect(self.update_form)
        self.employee_reviews_button.clicked.connect(self.show_employee_info)
        self.shop_reviews_buttons.clicked.connect(self.show_shop_info)

        self.tab_widget.setTabText(0, "Shop")
        self.tab_widget.addTab(self.shopping_cart_tab, "Shopping cart")
        self.tab_widget.addTab(self.client_acc_tab, "Account")

        self.menubar.hide()
        self.statusbar.hide()
        self.verticalLayout.setContentsMargins(0, 0, 0, 0)

        self.setup_price_slider()
        self.setup_reviews()
        self.update_form()

    def get_low_price_boundary(self) -> float:
        return float(self.low_price_label.text())

    def get_high_price_boundary(self) -> float:
        return float(self.high_price_label.text())

    def get_books_data(self) -> pd.DataFrame:

        data: pd.DataFrame = pd.DataFrame(
            Requests.available_books(
                self.user.connection,
                self.author_line_edit.text() or "%",
                self.book_line_edit.text() or "%",
                self.genre_line_edit.text() or "%",
                self.get_low_price_boundary(),
                self.get_high_price_boundary(),
            ),
            columns=["Author", "Book title", "Book genre", "Published", "Price, UAH"],
        )
        data.insert(0, "Book", "")
        data.insert(data.shape[1], "Full info", "")
        data.insert(data.shape[1], "To cart", "")

        return data

    def setup_price_slider(self) -> None:

        min_max = Requests.get_min_max_book_price(self.user.connection)
        min_ = int(min_max[0])
        max_ = int(min_max[1])

        if min_max is None:
            return

        self.update_price_labels(min_, max_)

        self.slider = range_slider.RangeSlider(QtCore.Qt.Horizontal)
        self.slider.setMinimumHeight(30)

        self.slider.setMinimum(min_)
        self.slider.setMaximum(max_)

        self.slider.setLow(min_)
        self.slider.setHigh(max_)

        self.slider.sliderMoved.connect(self.update_price_labels)
        self.user_constrains_layout.addWidget(self.slider, 9, 0)

    def setup_reviews(self):
        self.empl_shop_combo_box.addItems(ShopAndEmployee.SHOPS)
        self.empl_pos_combo_box.addItems(Const.ROLES[:-2])

        self.shop_combo_box.addItems(ShopAndEmployee.SHOPS)

    def update_price_labels(self, low: int, high: int) -> None:
        self.low_price_label.setText(str(low))
        self.high_price_label.setText(str(high))

    def update_form(self) -> None:

        books_data = self.get_books_data()
        self.load_completers(books_data)
        self.load_books_table(books_data)

    def load_completers(self, books_data: pd.DataFrame):
        uniq_auhtors = QtWidgets.QCompleter(books_data["Author"].unique())
        uniq_books = QtWidgets.QCompleter(books_data["Book title"].unique())
        uniq_genres = QtWidgets.QCompleter(books_data["Book genre"].unique())

        self.author_line_edit.setCompleter(uniq_auhtors)
        self.book_line_edit.setCompleter(uniq_books)
        self.genre_line_edit.setCompleter(uniq_genres)

    def load_books_table(self, books_data: pd.DataFrame) -> None:

        self.books_table.clear()
        self.books_table.setRowCount(0)
        self.books_table.setColumnCount(0)

        rows = books_data.shape[0]
        cols = books_data.shape[1]

        self.books_table.setRowCount(rows)
        self.books_table.setColumnCount(cols)
        self.books_table.setHorizontalHeaderLabels(books_data.columns)
        self.books_table.setIconSize(QtCore.QSize(150, 100))
        self.books_table.setSortingEnabled(True)

        for i in range(rows):
            for j in range(cols):
                item = QtWidgets.QTableWidgetItem(str(books_data.loc[i][j]))
                item.setTextAlignment(Qt.AlignHCenter)
                self.books_table.setItem(i, j, item)

        for i in range(rows):
            book_image = QtWidgets.QTableWidgetItem()
            book_image.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format(books_data.loc[i][2]))
            )
            self.books_table.setItem(i, 0, book_image)

            info_button = QtWidgets.QPushButton("")
            info_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("info")))
            info_button.setIconSize(QtCore.QSize(24, 24))
            info_button.clicked.connect(
                partial(
                    self.show_full_book_info,
                    books_data["Book title"][i],
                    books_data["Published"][i],
                )
            )

            buy_button = QtWidgets.QPushButton("")
            buy_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("cart")))
            buy_button.setIconSize(QtCore.QSize(24, 24))
            buy_button.clicked.connect(
                partial(
                    self.buy_book,
                    books_data["Book title"][i],
                    books_data["Published"][i],
                )
            )

            self.books_table.setCellWidget(i, cols - 2, info_button)
            self.books_table.setCellWidget(i, cols - 1, buy_button)

        header = self.books_table.horizontalHeader()
        for header_index in range(1, cols - 2):
            header.setSectionResizeMode(header_index, QtWidgets.QHeaderView.Stretch)

        # self.books_table.resizeColumnsToContents()
        self.books_table.resizeRowsToContents()

    def show_full_book_info(self, book_title, publishing_date):

        book_data = Requests.full_book_info(
            self.user.connection, book_title, publishing_date
        )

        self.full_book_info_form = BookInfoForm(self.user, book_data)
        self.full_book_info_form.show()

    def show_employee_info(self):

        employee_data = Requests.get_employee_info(
            self.user.connection,
            int(self.empl_shop_combo_box.currentText()),
            self.empl_pos_combo_box.currentText(),
        )

        if employee_data is None:
            msg.error_message("Employee doesn't exist.")
            return

        self.employee_reviews_form = EmployeeReviewForm(self.user, employee_data)
        self.employee_reviews_form.show()

    def show_shop_info(self):

        shop_data = Requests.get_shop_info(
            self.user.connection, int(self.shop_combo_box.currentText())
        )

        if shop_data is None:
            msg.error_message("Shop doesn't exist")
            return

        self.shop_review_form = ShopReviewForm(self.user, shop_data)
        self.shop_review_form.show()

    def buy_book(self, book_title, publishing_date):

        book_data = Requests.full_book_info(
            self.user.connection, book_title, publishing_date
        )

        self.buy_book_form = BuyBookForm(book_data["available_amount_"])

        dialog_res = self.buy_book_form.exec()
        if not dialog_res:
            return

        optional_data = self.buy_book_form.data
        print(optional_data)
        order = pd.DataFrame(
            [
                [
                    "",
                    book_data.get("title_"),
                    book_data.get("publishing_date_"),
                    datetime.now().strftime("%m-%d-%Y %H:%M:%S"),
                    book_data.get("shop_"),
                    self.user.login,
                    self.user.information.get("user_delivery_address"),
                    Order.ORDER_IN_CART,
                    book_data.get("price_"),
                    Order.PAYMENT_TYPE_CASH,
                    "",
                    1,
                    "",
                    "",
                ]
            ],
            columns=Order.ORDER_DF_COLUMNS,
        )

        order["Quantity"] = optional_data.get("quantity", 1)
        order["Price, UAH"] *= order["Quantity"]
        order["User info"] = optional_data.get(
            "additional_info", Order.ORDER_EMPTY_CELL
        )
        order["Payment type"] = optional_data.get(
            "payment_type", Order.PAYMENT_TYPE_CASH
        )
        order["Address"] = self.user.information.get(
            optional_data.get("use_cli_address", Order.ORDER_EMPTY_CELL),
            Order.ORDER_EMPTY_CELL,
        )

        order_id = self.shopping_cart_tab.add_order_in_database(order.values[0][1:-2])
        print("Order id", order_id)
        order.insert(1, "Order ID", order_id)

        print(tabulate(order, headers=order.columns, tablefmt="pretty"))
        self.shopping_cart_tab.add_order_in_qt_table(order)
