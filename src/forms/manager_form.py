import pandas as pd
import subprocess
import os
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
        self.my_grouped_sales_combo_box.addItems(Sales.MY_COMBO_BOX_FILLING)
        self.my_grouped_sales_combo_box.setCurrentText(Sales.MY_COMBO_BOX_FILLING[0])

        self.update_reports_table.clicked.connect(self.load_reports)
        self.top_selling_books_button.clicked.connect(self.top_selling_books)

        self.load_reports()

    def genre_sales(self):
        to_pdf = self.sales_by_genre_check_box.isChecked()
        l_date_border = self.sales_genre_l_datetime.dateTime().toPyDateTime()
        r_date_border = self.sales_genre_r_datetime.dateTime().toPyDateTime()

        if l_date_border > r_date_border:
            msg.error_message("First date is bigger then second!")
            return

        general_sales_data = pd.DataFrame(
            Requests.get_genre_sales(
                self.user.connection,
                self.user.id,
                l_date_border,
                r_date_border
            ),
            columns=Sales.GENERAL_GENRE_SALES_DF_COLUMNS
        )

        plotter.sales_canvas(
            self.web_view,
            general_sales_data,
            l_date_border,
            r_date_border,
            to_pdf
        )

    def all_sales_by_my(self):
        to_pdf = self.sales_grouped_by_my_check_box.isChecked()
        grouped_by = self.my_grouped_sales_combo_box.currentText()
        data = pd.DataFrame(
            Requests.get_sales_by_date(
                self.user.connection,
                self.user.id,
                grouped_by
            ),
            columns=Sales.MY_SALES_COLUMNS
        )

        plotter.date_groupped_sales(self.web_view, data, grouped_by, to_pdf)

    def top_selling_books(self):
        to_pdf = self.top_selling_books_check_box.isChecked()
        n_top = self.top_selling_books_spin_box.value()
        l_date = self.top_books_l_date_edit.dateTime().toPyDateTime()
        r_date = self.top_books_r_date_edit.dateTime().toPyDateTime()

        data = pd.DataFrame(
            Requests.get_top_selling_books(
                self.user.connection,
                self.user.id,
                l_date,
                r_date,
                n_top
            ),
            columns=Sales.TOP_SOLD_BOOKS
        )

        print(
            tabulate(
                data,
                headers=data.columns,
                tablefmt='pretty'
            )
        )

        plotter.top_selling_books(self.web_view, data, l_date, r_date, to_pdf)

    def load_reports(self):
        reports_df = pd.DataFrame(
            os.listdir(Const.PDF_REPORTS_FOLDER),
            columns=Sales.REPORTS_DF_COLUMNS
        )
        reports_df.sort_values(by=["Report"], inplace=True)
        reports_df.insert(0, "Delete", "")
        reports_df.insert(0, "Open", "")

        rows, cols = reports_df.shape
        self.reports_table.setColumnCount(len(Sales.REPORTS_DF_COLUMNS) + 2)
        self.reports_table.setRowCount(rows)

        self.reports_table.setHorizontalHeaderLabels(reports_df.columns)
        self.reports_table.setSizeAdjustPolicy(
            QtWidgets.QAbstractScrollArea.AdjustToContents
        )

        self.reports_table.resizeColumnsToContents()
        header = self.reports_table.horizontalHeader()
        header.setSectionResizeMode(2, QtWidgets.QHeaderView.Stretch)

        self.reports_table.resizeRowsToContents()

        for i in range(rows):

            del_button = QtWidgets.QPushButton("")
            del_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon"))
            )
            del_button.clicked.connect(self.delete_report)

            open_button = QtWidgets.QPushButton("")
            open_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("open_file_icon"))
            )
            open_button.clicked.connect(self.open_report)

            item = QtWidgets.QTableWidgetItem(str(reports_df.loc[i][2]))
            item.setTextAlignment(QtCore.Qt.AlignCenter)
            item.setFlags(QtCore.Qt.ItemIsEnabled)

            self.reports_table.setCellWidget(i, 0, open_button)
            self.reports_table.setCellWidget(i, 1, del_button)
            self.reports_table.setItem(i, 2, item)

    def open_report(self):
        curr_row = self.reports_table.currentRow()
        filename = self.reports_table.item(curr_row, 2).text()
        print(f"Opening {filename}...")
#        subprocess.Popen([Const.PDF_REPORTS_FOLDER+filename], shell=True)
        subprocess.call(["xdg-open", Const.PDF_REPORTS_FOLDER+filename])

    def delete_report(self):
        curr_row = self.reports_table.currentRow()
        filename = self.reports_table.item(curr_row, 2).text()

        try:
            os.remove(Const.PDF_REPORTS_FOLDER+filename)
            msg.info_message(f"File {filename} deleted succsesfully.")
            self.load_reports()
        except Exception as e:
            msg.error_message(f"File {filename} deletion error.\n{str(e)}")

