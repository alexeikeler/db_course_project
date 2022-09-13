# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

from config.constants import Const

form, base = uic.loadUiType(uifile=Const.ADD_COPIES_UI_PATH)


class AddCopiesForm(form, base):
    def __init__(self):
        super(base, self).__init__()
        self.setupUi(self)
        self.setWindowTitle("Add book copies")
        self.add_button.clicked.connect(self.update_value)
        self.cancel_button.clicked.connect(self.close)

        self.update_val = None

    def update_value(self):
        self.update_val = self.amount_spin_box.value()
        self.close()
