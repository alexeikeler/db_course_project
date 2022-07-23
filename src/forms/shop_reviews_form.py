import pandas as pd

import src.custom_qt_widgets.message_boxes as msg

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from PyQt5.QtCore import Qt
from functools import partial

from config.constants import Const, Errors
from src.database_related import psql_requests as Requests
from src.forms.add_review_form import ReviewForm

shop_review_form, shop_review_base = uic.loadUiType(Const.SHOP_REVIEWS_UI_PATH)


class ShopReviewForm(shop_review_form, shop_review_base):

    def __init__(self, user, shop_info):

        super(shop_review_base, self).__init__()
        self.setupUi(self)
        self.user = user
        self.shop_info = shop_info

        self.review_form = None

        self.add_review_button.clicked.connect(self.add_review)
        self.update_reviews_button.clicked.connect(self.load_reviews)
        self.return_button.clicked.connect(self.close)

        self.__setup_line_edits()
        self.load_reviews()

    def __setup_line_edits(self):
        self.shop_line_edit.setText(
            self.shop_info.get("name_of_shop_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.shop_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.number_of_employees_line_edit.setText(
            self.shop_info.get("employees_num_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.number_of_employees_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.post_code_line_edit.setText(
            self.shop_info.get("post_code_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.post_code_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.country_line_edit.setText(
            self.shop_info.get("country_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.country_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.city_line_edit.setText(
            self.shop_info.get("city_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.city_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.street_line_edit.setText(
            self.shop_info.get("street_", Errors.SHOP_DATA_NOT_FOUND)
        )
        self.street_line_edit.setAlignment(QtCore.Qt.AlignCenter)

    def load_reviews(self):

        reviews = Requests.get_shop_reviews(
            self.user.connection,
            self.shop_info.get("shop_id_")
        )

        rev_df = pd.DataFrame(
            reviews,
            columns=["User", "Date", "Review"]
        )
        rev_df.insert(rev_df.shape[1], "Delete", "")
        rows, cols = rev_df.shape

        self.reviews_table.clear()
        self.reviews_table.setRowCount(rows)
        self.reviews_table.setColumnCount(cols)
        self.reviews_table.setHorizontalHeaderLabels(rev_df.columns)
        self.reviews_table.setSortingEnabled(True)

        for i in range(rows):
            for j in range(cols):
                item = QtWidgets.QTableWidgetItem(str(rev_df.loc[i][j]))
                item.setTextAlignment(Qt.AlignHCenter)
                self.reviews_table.setItem(i, j, item)

            if self.reviews_table.item(i, 0).text() == self.user.login:
                delete_review_button = QtWidgets.QPushButton("")
                delete_review_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format('delete_review')))
                delete_review_button.clicked.connect(
                    partial(
                        self.delete_review,
                        self.shop_info.get("shop_id_"),
                        rev_df["User"][i],
                        rev_df["Date"][i],
                        rev_df["Review"][i]
                    )
                )
                self.reviews_table.setCellWidget(i, cols - 1, delete_review_button)

        header = self.reviews_table.horizontalHeader()
        header.setSectionResizeMode(0, QtWidgets.QHeaderView.Stretch)
        header.setSectionResizeMode(2, QtWidgets.QHeaderView.Stretch)

        self.reviews_table.resizeRowsToContents()

    def add_review(self):

        self.review_form = ReviewForm()
        self.review_form.exec()

        review = self.review_form.user_review_text

        if review is not None and len(review):

            Requests.add_shop_review(
                self.user.connection,
                self.user.login,
                self.shop_info.get("shop_id_"),
                review
            )

    def delete_review(self, shop_id, user_login, review_date, review_text):
        Requests.delete_shop_review(
            self.user.connection,
            shop_id,
            user_login,
            review_date,
            review_text
        )
        msg.info_message(Const.REVIEW_DELETED)