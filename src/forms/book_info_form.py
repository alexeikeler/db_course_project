import pandas as pd
from tabulate import  tabulate
import src.database_related.psql_requests as Requests
import src.custom_qt_widgets.message_boxes as msg

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui
from PyQt5.QtCore import Qt
from functools import partial

from config.constants import Const, ReviewsMessages
from src.forms.add_review_form import ReviewForm

book_info_form, book_info_base = uic.loadUiType(Const.BOOKS_INFO_FORM_UI_PATH)


class BookInfoForm(book_info_form, book_info_base):

    def __init__(self, user, book_data):

        super(book_info_base, self).__init__()
        self.setupUi(self)

        self.user = user
        self.book_data = book_data

        self.review_form = None

        self.fields = (
            self.author_line_edit,
            self.title_line_edit,
            self.genre_line_edit,
            self.available_copies_line_edit,
            self.available_in_shop_line_edit,
            self.binding_type_line_edit,
            self.number_of_pages_line_edit,
            self.publishing_date_line_edit,
            self.publishing_agency_line_edit,
            self.paper_type_line_edit,
            self.book_price_line_edit
        )

        self.add_review_button.clicked.connect(self.add_review)
        self.update_reviews_button.clicked.connect(self.update_reviews)
        self.return_button.clicked.connect(self.close)

        self.menubar.hide()
        self.statusbar.hide()

        self.update_info()
        self.update_reviews()

    def update_info(self):

        for i, val in enumerate(self.book_data.values()):
            self.fields[i].setText(str(val))
            self.fields[i].setAlignment(QtCore.Qt.AlignCenter)

        pixmap = QtGui.QPixmap(Const.IMAGES_PATH.format(self.book_data['title_']))
        self.book_image_label.setPixmap(pixmap)
        self.book_image_label.setScaledContents(True)
        self.book_image_label.setSizePolicy(
            QtWidgets.QSizePolicy.Ignored,
            QtWidgets.QSizePolicy.Ignored
        )

    def add_review(self):

        self.review_form = ReviewForm()
        self.review_form.exec()

        review = self.review_form.user_review_text
        if review is not None and len(review):
            Requests.add_user_review(
                self.user.connection,
                self.user.login,
                self.book_data.get('title_'),
                self.book_data.get('publishing_date_'),
                review
            )

    def delete_review(self, review_id):

        Requests.delete_review(
            self.user.connection,
            int(review_id)
        )

        msg.info_message(ReviewsMessages.REVIEW_DELETED)

    def update_reviews(self):
        reviews = Requests.get_book_reviews(
            self.user.connection,
            self.book_data.get('title_'),
            self.book_data.get('publishing_date_')
        )

        rev = pd.DataFrame(
            reviews,
            columns=["Id", "User", "Date", "Review"]
        )
        rev.insert(rev.shape[1], "Delete", "")

        self.reviews_table.clear()
        self.reviews_table.setRowCount(0)
        self.reviews_table.setColumnCount(0)

        rows = rev.shape[0]
        cols = rev.shape[1]

        self.reviews_table.setRowCount(rows)
        self.reviews_table.setColumnCount(cols)
        self.reviews_table.setHorizontalHeaderLabels(rev.columns)
        self.reviews_table.setSortingEnabled(True)

        for i in range(rows):
            for j in range(cols):
                item = QtWidgets.QTableWidgetItem(str(rev.loc[i][j]))
                item.setTextAlignment(Qt.AlignHCenter)
                self.reviews_table.setItem(i, j, item)

            if self.reviews_table.item(i, 1).text() == self.user.login:

                delete_review_button = QtWidgets.QPushButton("")
                delete_review_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format('delete_review')))
                delete_review_button.clicked.connect(
                    partial(
                        self.delete_review,
                        rev["Id"][i]
                    )
                )
                self.reviews_table.setCellWidget(i, cols - 1, delete_review_button)

        header = self.reviews_table.horizontalHeader()
        header.setSectionResizeMode(1, QtWidgets.QHeaderView.Stretch)
        header.setSectionResizeMode(2, QtWidgets.QHeaderView.Stretch)

        self.reviews_table.resizeRowsToContents()