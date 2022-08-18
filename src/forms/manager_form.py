import os
import subprocess

import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from tabulate import tabulate

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
from config.constants import (Const, Errors, Sales, ShopAndEmployee,
                              WindowsNames)
from src.forms.add_copies import AddCopiesForm
from src.plotter import plotter

manager_form, manager_base = uic.loadUiType(uifile=Const.MANAGER_UI_PATH)


class ManagerForm(manager_form, manager_base):
    def __init__(self, user):

        super(manager_base, self).__init__()
        self.setupUi(self)

        self.user = user
        self.add_copies_form = None
        self.reports_folder = Const.PDF_REPORTS_FOLDER.format(
            f"m{self.user.place_of_work}_reports"
        )

        self.tab_widget.setTabText(0, WindowsNames.MANAGER_REPORTS_TAB)
        self.tab_widget.setTabText(1, WindowsNames.MANAGER_ADD_BOOKS)

        self._config_input_widgets()
        self.load_reports()
        self.load_authors_table()
        self.load_unsold_books_table()
        self.load_available_books_table()

        # Test data
        self.title_line_edit.setText("Лекции по философии постмодерна")
        self.genre_combo_box.setCurrentText("Философия")
        self.author_id_spin_box.setValue(30)
        self.price_double_spin_box.setValue(450.00)
        self.available_copies_spin_box.setValue(250)

        self.paper_qualitly_combo_box.setCurrentText("Для глубокой печати")
        self.binding_type_combo_box.setCurrentText("Твёрдый")
        self.publisging_agencies_combo_box.setCurrentText("BookChef")
        self.pages_number_spin_box.setValue(300)

    @staticmethod
    def _config_table(
        table: QtWidgets.QTableWidget, rows, cols, columns, areas_to_stretch
    ):

        table.setRowCount(rows)
        table.setColumnCount(cols)
        table.setHorizontalHeaderLabels(columns)
        table.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)

        table.resizeRowsToContents()

        header = table.horizontalHeader()
        for area, mode in areas_to_stretch:
            header.setSectionResizeMode(area, mode)

        table.resizeRowsToContents()

    def _config_input_widgets(self):
        # Buttons tab 1
        self.sales_by_genre_button.clicked.connect(self.genre_sales)

        self.my_grouped_select_button.clicked.connect(self.all_sales_by_my)
        self.update_reports_table_button.clicked.connect(self.load_reports)
        self.top_selling_books_button.clicked.connect(self.top_selling_books)

        # Buttons tab 2
        self.add_book_button.clicked.connect(self.add_book)
        self.update_available_books_button.clicked.connect(
            self.load_available_books_table
        )
        self.update_unsold_books.clicked.connect(self.load_unsold_books_table)

        self.add_author_button.clicked.connect(self.add_author)
        self.update_authors_table_button.clicked.connect(self.load_authors_table)

        # Check box tab 1
        self.use_dob_check_box.stateChanged.connect(
            lambda status: self.dod_date_edit.setEnabled(status)
        )

        # Combo boxes tab 1
        self.my_grouped_sales_combo_box.addItems(Sales.MY_COMBO_BOX_FILLING)
        self.my_grouped_sales_combo_box.setCurrentText(Sales.MY_COMBO_BOX_FILLING[0])

        # Combo boxes tab 2
        self.genre_combo_box.addItems(ShopAndEmployee.BOOK_GENRE_TYPES)
        self.paper_qualitly_combo_box.addItems(ShopAndEmployee.PAPER_QUALITY_TYPES)
        self.binding_type_combo_box.addItems(ShopAndEmployee.BINDING_TYPES)

        agencies = Requests.get_publishing_agencies(self.user.connection)
        self.publisging_agencies_combo_box.addItems(agencies)

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
                self.user.place_of_work,
                l_date_border,
                r_date_border,
            ),
            columns=Sales.GENERAL_GENRE_SALES_DF_COLUMNS,
        )

        fig = plotter.sales_canvas(
            self.web_view, general_sales_data, l_date_border, r_date_border
        )

        if to_pdf:
            plotter.save_pdf(fig, self.reports_folder, Sales.GENRE_SALES)

    def all_sales_by_my(self):
        to_pdf = self.sales_grouped_by_my_check_box.isChecked()
        grouped_by = self.my_grouped_sales_combo_box.currentText()
        data = pd.DataFrame(
            Requests.get_sales_by_date(
                self.user.connection, self.user.place_of_work, grouped_by
            ),
            columns=Sales.MY_SALES_COLUMNS,
        )

        fig = plotter.date_groupped_sales(self.web_view, data, grouped_by)

        if to_pdf:
            plotter.save_pdf(
                fig, self.reports_folder, Sales.MY_SALES.format(grouped_by)
            )

    def top_selling_books(self):
        to_pdf = self.top_selling_books_check_box.isChecked()
        n_top = self.top_selling_books_spin_box.value()
        l_date = self.top_books_l_date_edit.dateTime().toPyDateTime()
        r_date = self.top_books_r_date_edit.dateTime().toPyDateTime()

        data = pd.DataFrame(
            Requests.get_top_selling_books(
                self.user.connection, self.user.place_of_work, l_date, r_date, n_top
            ),
            columns=Sales.TOP_SOLD_BOOKS,
        )

        fig = plotter.top_selling_books(self.web_view, data, l_date, r_date)

        if to_pdf:
            plotter.save_pdf(fig, self.reports_folder, Sales.TOP_BOOKS_SALES)

    def load_reports(self):

        reports_df = pd.DataFrame(
            os.listdir(self.reports_folder), columns=Sales.REPORTS_DF_COLUMNS
        )
        reports_df.sort_values(by=["Report"], inplace=True)
        reports_df.insert(0, "Delete", "")
        reports_df.insert(0, "Open", "")

        rows, cols = reports_df.shape
        self._config_table(
            self.reports_table,
            rows,
            cols,
            reports_df.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.ResizeToContents),
                (2, QtWidgets.QHeaderView.Stretch),
            ],
        )

        self.reports_table.resizeRowsToContents()

        for i in range(rows):

            del_button = QtWidgets.QPushButton("")
            del_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon")))
            del_button.clicked.connect(self.delete_report)

            open_button = QtWidgets.QPushButton("")
            open_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("open_file_icon")))
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
        subprocess.call(["xdg-open", self.reports_folder + "/" + filename])

    def delete_report(self):
        curr_row = self.reports_table.currentRow()
        filename = self.reports_table.item(curr_row, 2).text()

        try:
            os.remove(self.reports_folder + "/" + filename)
            msg.info_message(f"File {filename} deleted succsesfully.")
            self.load_reports()
        except Exception as e:
            msg.error_message(f"File {filename} deletion error.\n{str(e)}")

    def load_authors_table(self):
        data = pd.DataFrame(
            Requests.get_authors(
                self.user.connection, self.author_name_line_edit.text() or "%"
            ),
            columns=Sales.AUTHORS_DF_COLUMNS,
        ).fillna(value=Const.EMPTY_CELL)

        data.insert(data.shape[1], "Delete", "")

        author_completer = QtWidgets.QCompleter(data["Author"].unique())
        self.author_name_line_edit.setCompleter(author_completer)

        rows, cols = data.shape
        self._config_table(
            self.authors_table,
            rows,
            cols,
            data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.Stretch),
                (cols - 1, QtWidgets.QHeaderView.ResizeToContents),
            ],
        )

        for i in range(rows):

            delete_button = QtWidgets.QPushButton("")
            delete_button.setMinimumSize(30, 20)
            delete_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("delete_review"))
            )
            delete_button.clicked.connect(self.delete_author)

            for j in range(cols - 1):
                item = QtWidgets.QTableWidgetItem(str(data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.authors_table.setItem(i, j, item)

            self.authors_table.setCellWidget(i, cols - 1, delete_button)

    def add_author(self):

        fname = self.author_firstname_line_edit.text()
        lname = self.author_lastname_line_edit.text()

        dob = self.dob_date_edit.dateTime().toPyDateTime().strftime("%Y-%m-%d")
        dod = None

        if not (fname and lname):
            msg.error_message("Author first or last name is empty!")
            return

        if self.use_dob_check_box.isChecked():
            dod = self.dod_date_edit.dateTime().toPyDateTime().strftime("%Y-%m-%d")

        print(fname, lname, dob, dod)
        new_auth_id = Requests.add_author(self.user.connection, fname, lname, dob, dod)

        if new_auth_id is not None:
            msg.info_message(
                f"New author {fname} {lname} with ID {new_auth_id} added succsesfully."
            )
        else:
            msg.error_message(
                f"Error occured while adding new author ({fname} {lname})."
            )

    def delete_author(self):

        current_row = self.authors_table.currentRow()
        author_id = int(self.authors_table.item(current_row, 0).text())
        returning = Requests.delete_author(self.user.connection, author_id)

        if not returning:
            msg.error_message(
                Errors.AUTHOR_DELETION_ERROR.format(
                    self.authors_table.item(current_row, 1).text(), author_id
                )
            )
            return

        msg.info_message(f"Author with ID {author_id} was succsesfully deleted.")

    def add_book(self):

        title = self.title_line_edit.text()

        if not title:
            msg.error_message(Errors.EMPTY_TITLE)
            return

        author_id = self.author_id_spin_box.value()

        ids = [self.authors_table.item(i, 0).text for i in range(self.authors_table.rowCount())]

        if str(author_id) not in ids:
            msg.error_message(Errors.NO_AUTHOR_ID.format(author_id))
            return

        del ids

        genre = self.genre_combo_box.currentText()
        price = self.price_double_spin_box.value()
        available_copies = self.available_copies_spin_box.value()
        publ_date = self.publ_date_edit.dateTime().toPyDateTime().strftime("%Y-%m-%d")
        paper_qual = self.paper_qualitly_combo_box.currentText()
        binding_type = self.binding_type_combo_box.currentText()
        publ_agency = self.publisging_agencies_combo_box.currentText()
        pages_number = self.pages_number_spin_box.value()

        new_edition_id = Requests.add_edition(
            self.user.connection,
            self.user.place_of_work,
            title,
            genre,
            author_id,
            publ_agency,
            price,
            publ_date,
            available_copies,
            pages_number,
            binding_type,
            paper_qual,
        )

        if new_edition_id is None:
            Errors.NEW_EDITION_ERROR.format(title)
            return

        msg.info_message(f"New edition with id {new_edition_id} created succsesfully.")

    def delete_book(self):
        current_row = self.unsold_books_table.currentRow()
        edition_id = int(self.unsold_books_table.item(current_row, 0).text())
        Requests.delete_edition(self.user.connection, edition_id)
        msg.info_message(f"Edition # {edition_id} deleted!")

    def load_unsold_books_table(self):

        data = pd.DataFrame(
            Requests.get_not_sold_books(self.user.connection, self.user.place_of_work),
            columns=Sales.NOT_SOLD_BOOKS_DF_COLUMNS,
        )
        data.insert(data.shape[1], "Delete", "")
        rows, cols = data.shape

        self._config_table(
            self.unsold_books_table,
            rows,
            cols,
            data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.ResizeToContents),
                (2, QtWidgets.QHeaderView.Stretch),
                (3, QtWidgets.QHeaderView.ResizeToContents),
            ],
        )

        for i in range(rows):

            delete_button = QtWidgets.QPushButton("")
            delete_button.setMinimumSize(30, 20)
            delete_button.setIcon(
                QtGui.QIcon(Const.IMAGES_PATH.format("delete_review"))
            )
            delete_button.clicked.connect(self.delete_book)

            for j in range(cols - 1):
                item = QtWidgets.QTableWidgetItem(str(data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.unsold_books_table.setItem(i, j, item)

            self.unsold_books_table.setCellWidget(i, cols - 1, delete_button)

    def load_available_books_table(self):
        data = pd.DataFrame(
            Requests.get_number_of_books(self.user.connection, self.user.place_of_work),
            columns=Sales.AVAILABLE_BOOKS_DF_COLUMNS,
        )
        data.insert(data.shape[1], "Add", "")

        rows, cols = data.shape

        self._config_table(
            self.available_books_table,
            rows,
            cols,
            data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.ResizeToContents),
                (2, QtWidgets.QHeaderView.Stretch),
                (3, QtWidgets.QHeaderView.ResizeToContents),
                (4, QtWidgets.QHeaderView.ResizeToContents),
            ],
        )

        for i in range(rows):

            add_copies = QtWidgets.QPushButton("")
            add_copies.setMinimumSize(30, 20)
            add_copies.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("add_icon")))
            add_copies.clicked.connect(self.add_book_copies)

            for j in range(cols - 1):
                item = QtWidgets.QTableWidgetItem(str(data.loc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.available_books_table.setItem(i, j, item)

            self.available_books_table.setCellWidget(i, cols - 1, add_copies)

    def add_book_copies(self):

        current_row = self.available_books_table.currentRow()
        edition_id = int(self.available_books_table.item(current_row, 0).text())
        self.add_copies_form = AddCopiesForm()
        self.add_copies_form.exec()

        update_by = self.add_copies_form.update_val

        if update_by is None:
            return

        Requests.update_editions_number(self.user.connection, edition_id, update_by)
        msg.info_message(f"Edition # {edition_id} copies number updated")
