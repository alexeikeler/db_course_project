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

        self.select_button.clicked.connect(self.genre_sales)
        self.use_date_checkbox.stateChanged.connect(self.show_dates)

    def l_date(self):
        return self.sales_genre_l_datetime.dateTime().toPyDateTime()

    def r_date(self):
        return self.sales_genre_r_datetime.dateTime().toPyDateTime()

    def get_date_use_state(self):
        return self.use_date_checkbox.isChecked()

    def show_dates(self, enable: int):
        self.sales_genre_l_datetime.setEnabled(enable)
        self.sales_genre_r_datetime.setEnabled(enable)

    def genre_sales(self):

        data = pd.DataFrame(
            Requests.get_genre_sales(
                self.user.connection, self.user.id, self.l_date(), self.r_date()
            ),
            columns=Sales.SALES_DF_COLUMNS
        )

        print(
            tabulate(
                data,
                headers=data.columns,
                tablefmt='pretty'
            )
        )

        plotter.sales_barchar(self.web_view, data, self.l_date(), self.r_date())