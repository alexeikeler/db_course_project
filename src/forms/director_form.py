import pandas as pd
import re
import subprocess
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from config.constants import Const, ShopAndEmployee, Errors
import src.database_related.psql_requests as Requests
import src.custom_qt_widgets.functionality as widget_funcs
import src.custom_qt_widgets.message_boxes as msg
director_form, director_base = uic.loadUiType(uifile=Const.DIRECTOR_UI_PATH)


class DirectorForm(director_form, director_base):
    def __init__(self, user):

        super(director_base, self).__init__()
        self.setupUi(self)

        self.user = user
        self.dirs = []

        self.model = QtWidgets.QFileSystemModel()
        self.model.setRootPath(Const.ABS_REPORTS_PATH)
        self.model.directoryLoaded.connect(self.on_dir_load)

        self.reports_tree.setModel(self.model)
        self.reports_tree.setRootIndex(self.model.index(Const.ABS_REPORTS_PATH))
        self.reports_tree.clicked.connect(self.on_item_clicked)
        self.reports_tree.setSortingEnabled(True)

        header = self.reports_tree.header()
        header.setSectionResizeMode(QtWidgets.QHeaderView.ResizeToContents)
        header.setStretchLastSection(False)
        header.setSectionResizeMode(0, QtWidgets.QHeaderView.Stretch)

        self.employees_salary_table.itemChanged.connect(self.on_salary_changed)
        self.load_employees_salary_table()

    def on_dir_load(self):
        root = self.model.index(self.model.rootPath())
        for i in range(self.model.rowCount(root)):
            index = self.model.index(i, 0, root)
            f_name = self.model.fileName(index)
 
    def on_item_clicked(self, item):
        file_name: str = item.data()

        if re.match(Const.REPORTS_REGEX, file_name):
            subprocess.call(
                [
                    "xdg-open",
                    Const.PDF_REPORTS_FOLDER.format(self.dirs[0]) + file_name
                ]
            )

        elif re.match(Const.FOLDERS_REGEX, file_name):
            if len(self.dirs):
                self.dirs.pop()
            self.dirs.append(file_name)

    def load_employees_salary_table(self):

        self.employees_salary_table.disconnect()

        data = pd.DataFrame(
            Requests.get_employees_salary(self.user.connection),
            columns=ShopAndEmployee.EMPLOYEE_SALARY_DF_COLUMNS
        )

        rows, cols = data.shape
        salary_col = 3

        widget_funcs.config_table(
            self.employees_salary_table,
            rows,
            cols,
            data.columns,
            [
                (0, QtWidgets.QHeaderView.ResizeToContents),
                (1, QtWidgets.QHeaderView.ResizeToContents),
                (2, QtWidgets.QHeaderView.ResizeToContents),
                (3, QtWidgets.QHeaderView.ResizeToContents),
                (4, QtWidgets.QHeaderView.Stretch),
            ],
            enable_column_sort=False
        )

        for i in range(rows):
            for j in range(cols):

                item = QtWidgets.QTableWidgetItem(str(data.iloc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                if j != salary_col: item.setFlags(QtCore.Qt.ItemIsEnabled)

                self.employees_salary_table.setItem(i, j, item)

        self.employees_salary_table.itemChanged.connect(self.on_salary_changed)

    def on_salary_changed(self, salary):
        new_salary = float(salary.text())
        id = int(self.employees_salary_table.item(salary.row(), 0).text())

        result = Requests.change_employee_salary(self.user.connection, id, new_salary)

        if not result:
            msg.error_message(Errors.ERROR_SALARY_UPDATE.format(id))
            return

        self.load_employees_salary_table()

        msg.info_message(f"Salary for employee # {id} updated to {new_salary}")
