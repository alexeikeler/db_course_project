# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

import src.custom_qt_widgets.message_boxes as msg
from config.constants import Const

review_form_review, review_base = uic.loadUiType(Const.REVIEW_FORM_UI_PATH)


class ReviewForm(review_form_review, review_base):
    def __init__(self):
        super(review_base, self).__init__()
        self.setupUi(self)
        self.user_review_text = None
        self.add_review_button.clicked.connect(self.add_review)
        self.cancel_review_button.clicked.connect(self.cancel_review)

    def add_review(self):
        self.user_review_text = self.user_review_text_edit.toPlainText()
        if not self.user_review_text:
            msg.error_message("Cannot add empty review!")
        else:
            msg.info_message("Review successfully added! Update reviews table!")
            self.close()

    def cancel_review(self):
        self.user_review_text = None
        self.close()
