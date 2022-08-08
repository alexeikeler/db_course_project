import pandas as pd
import PyQt5.QtWidgets
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from tabulate import tabulate

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
from config.constants import (Const, Errors, Order, ReviewsMessages,
                              WindowsNames, Sales)
from src.plotter import plotter
manager_form, manager_base = uic.loadUiType(
    uifile=Const.MANAGER_UI_PATH
)


class ManagerForm(manager_form, manager_base ):
    def __init__(self, user):

        super(manager_base, self).__init__()
        self.setupUi(self)

        self.user = user

        self.sales_by_genre_button.clicked.connect(self.genre_sales)

        self.my_grouped_select_button.clicked.connect(self.all_sales_by_my)
        self.my_grouped_sales_combo_box.addItems(Sales.DWMY_COMBO_BOX_FILLING)
        self.my_grouped_sales_combo_box.setCurrentText(Sales.DWMY_COMBO_BOX_FILLING[0])

    def genre_sales(self):

        l_date_border = self.sales_genre_l_datetime.dateTime().toPyDateTime()
        r_date_border = self.sales_genre_r_datetime.dateTime().toPyDateTime()

        if l_date_border > r_date_border:
            msg.error_message("First date is bigger then second!")
            return

        data = pd.DataFrame(
            Requests.get_genre_sales(
                self.user.connection,
                self.user.id,
                l_date_border,
                r_date_border
            ),
            columns=Sales.GENRE_SALES_DF_COLUMNS
        )
        print(
            tabulate(
                data,
                headers=data.columns,
                tablefmt='pretty'
            )
        )

        plotter.sales_barchar(self.web_view, data, l_date_border, r_date_border)

        if self.sales_by_genre_check_box.isChecked():
            self.to_pdf()

    def all_sales_by_my(self):
        grouped_by = self.my_grouped_sales_combo_box.currentText()
        data = pd.DataFrame(
            Requests.get_sales_by_date(
                self.user.connection,
                self.user.id,
                grouped_by
            ),
            columns=Sales.DWMY_SALES_COLUMNS
        )

        print(
            tabulate(
                data,
                headers=data.columns,
                tablefmt='pretty'
            )
        )

        plotter.date_groupped_sales(self.web_view, data, grouped_by)

        if self.sales_grouped_by_my_check_box.isChecked():
            self.to_pdf()

    def to_pdf(self):
        print("In pdf func")