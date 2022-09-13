# noinspection PyUnresol    vedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

from config.constants import Const, Order

buy_book_form, buy_book_base = uic.loadUiType(Const.BUY_BOOK_UI_PATH)


class BuyBookForm(buy_book_form, buy_book_base):
    def __init__(self, max_books):
        super(buy_book_base, self).__init__()
        self.setupUi(self)
        self.setWindowTitle("Buy book")
        self.data = {}
        self.closed = False

        self.buy_book_layout.setContentsMargins(0, 0, 0, 0)

        self.amount_spin_box.setMinimum(1)
        self.amount_spin_box.setMaximum(max_books)

        self.add_button.clicked.connect(self.add_order_button_clicked)
        self.cancel_button.clicked.connect(self.cancel_button_clicked)

        self.payment_type_combo_box.addItems(
            (Order.PAYMENT_TYPE_CASH, Order.PAYMENT_TYPE_CARD)
        )

    def add_order_button_clicked(self):
        self.data = {
            "quantity": self.amount_spin_box.value(),
            "payment_type": self.payment_type_combo_box.currentText(),
        }

        if self.cli_addr_check_box.isChecked():
            self.data.update({"use_cli_address": "user_delivery_address"})

        if self.add_info_text_edit.toPlainText():
            self.data.update({"additional_info": self.add_info_text_edit.toPlainText()})

        self.close()
        self.setResult(QtWidgets.QDialog.Accepted)

    def cancel_button_clicked(self):
        self.close()
        self.setResult(QtWidgets.QDialog.Rejected)
