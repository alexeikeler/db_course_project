from config.constants import Const
# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore, QtGui


review_form, review_base = uic.loadUiType(uifile=Const.SHOW_REVIEW_UI_PATH)


class ShowReview(review_form, review_base):
    def __init__(self):

        super(review_base, self).__init__()
        self.setupUi(self)

        self.ok_button.clicked.connect(self.close)

    def set_text(self, review_text):
        self.user_review_pte.setPlainText(review_text)
