# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

from config.constants import Const

review_form, review_base = uic.loadUiType(uifile=Const.SHOW_REVIEW_UI_PATH)


class ShowReview(review_form, review_base):
    def __init__(self):

        super(review_base, self).__init__()
        self.setupUi(self)
        self.setWindowTitle("Review text")
        self.ok_button.clicked.connect(self.close)

    def set_text(self, review_text):
        self.user_review_pte.setPlainText(review_text)
