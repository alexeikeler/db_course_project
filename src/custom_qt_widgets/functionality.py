import pandas as pd
from tabulate import tabulate
from PyQt5 import QtWidgets
from typing import List, Tuple, Iterable


def config_table(
    table: QtWidgets.QTableWidget,
    rows: int,
    cols: int,
    columns: Iterable,
    areas_to_stretch: List[Tuple[int, QtWidgets.QHeaderView.ResizeMode]],
    enable_column_sort: bool
) -> None:

    table.setRowCount(rows)
    table.setColumnCount(cols)
    table.setHorizontalHeaderLabels(columns)
    table.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)
    table.setSortingEnabled(enable_column_sort)

    table.resizeRowsToContents()

    header = table.horizontalHeader()
    for area, mode in areas_to_stretch:
        header.setSectionResizeMode(area, mode)

    table.resizeRowsToContents()


def hide_password(password_line_edit: QtWidgets.QLineEdit) -> None:
    if password_line_edit.echoMode() == QtWidgets.QLineEdit.Normal:
        password_line_edit.setEchoMode(QtWidgets.QLineEdit.Password)
    else:
        password_line_edit.setEchoMode(QtWidgets.QLineEdit.Normal)


def print_dataframe(df: pd.DataFrame) -> None:
    print(
        tabulate(
            df,
            headers=df.columns,
            tablefmt="pretty"
        )
    )