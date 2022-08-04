import pandas as pd

import src.custom_qt_widgets.message_boxes as msg

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from PyQt5.QtCore import Qt
from functools import partial

from config.constants import Const, Errors, ReviewsMessages
from src.database_related import psql_requests as Requests
from src.forms.add_review_form import ReviewForm

empl_review_form, empl_review_base = uic.loadUiType(Const.EMPLOYEE_REVIEWS_UI_PATH)


class EmployeeReviewForm(empl_review_form, empl_review_base):
    def __init__(self, user, empl_info):

        super(empl_review_base, self).__init__()
        self.setupUi(self)
        self.user = user
        self.empl_info = empl_info

        self.review_form = None


        self.add_review_button.clicked.connect(self.add_review)
        self.update_reviews_button.clicked.connect(self.load_reviews)
        self.return_button.clicked.connect(self.close)

        self.__setup_line_edits()
        self.load_reviews()

    def __setup_line_edits(self):
        self.employee_name_line_edit.setText(
            self.empl_info.get("employee_name_", Errors.EMPLOYEE_DATA_NOT_FOUND)
        )
        self.employee_name_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.position_line_edit.setText(
            self.empl_info.get("employee_position_", Errors.EMPLOYEE_DATA_NOT_FOUND)
        )
        self.position_line_edit.setAlignment(QtCore.Qt.AlignCenter)

        self.place_of_work_line_edit.setText(
            self.empl_info.get("employee_place_of_work_", Errors.EMPLOYEE_DATA_NOT_FOUND)
        )
        self.place_of_work_line_edit.setAlignment(QtCore.Qt.AlignCenter)

    def load_reviews(self):
        reviews = Requests.get_reviews_about_employee(
            self.user.connection,
            self.empl_info.get("employee_id_")
        )

        rev_df = pd.DataFrame(
            reviews,
            columns=["Id", "User", "Date", "Review"]
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

            if self.reviews_table.item(i, 1).text() == self.user.login:
                delete_review_button = QtWidgets.QPushButton("")
                delete_review_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format('delete_review')))
                delete_review_button.clicked.connect(
                    partial(
                        self.delete_review,
                        rev_df["Id"][i]
                    )
                )
                self.reviews_table.setCellWidget(i, cols - 1, delete_review_button)

        header = self.reviews_table.horizontalHeader()
        header.setSectionResizeMode(1, QtWidgets.QHeaderView.Stretch)
        header.setSectionResizeMode(2, QtWidgets.QHeaderView.Stretch)

        self.reviews_table.resizeRowsToContents()

    def add_review(self):
        self.review_form = ReviewForm()
        self.review_form.exec()

        review = self.review_form.user_review_text

        if review is not None and len(review):

            Requests.add_employee_review(
                self.user.connection,
                self.user.login,
                self.empl_info.get("employee_id_"),
                review
            )

    def delete_review(self, review_id):
        Requests.delete_review(
            self.user.connection,
            int(review_id)
        )
        msg.info_message(ReviewsMessages.REVIEW_DELETED)