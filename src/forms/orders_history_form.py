import pandas as pd
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic

import src.custom_qt_widgets.functionality as widget_funcs
import src.custom_qt_widgets.message_boxes as msg

from config.constants import Const, Errors, Order

orders_hist_form, orders_hist_base = uic.loadUiType(Const.VIEW_CLIENT_ORDERS_UI_PATH)


class OrdersHistoryForm(orders_hist_form, orders_hist_base):
    def __init__(self, data: pd.DataFrame):

        super(orders_hist_base, self).__init__()
        self.setupUi(self)

        self._data = data

        self.sort_criteria_table.setColumnCount(2)
        widget_funcs.config_table(
            self.sort_criteria_table,
            self.sort_criteria_table.rowCount(),
            self.sort_criteria_table.columnCount(),
            ("Criteria", "Delete"),
            [(0, QtWidgets.QHeaderView.ResizeToContents), (1, QtWidgets.QHeaderView.Stretch)],
            enable_column_sort=True
        )

        self.states_combo_box.addItems(
            (
                Order.ORDER_PAYED,
                Order.ORDER_PROCESSED,
                Order.ORDER_DELIVERING,
                Order.ORDER_FINISHED,
                Order.ORDER_DECLINED
            )
        )
        self.find_orders_by_state_button.clicked.connect(self.state_search)

        self.columns_combo_box.addItems(data.columns)
        self.sort_button.clicked.connect(self.sort_table)
        self.add_sort_criteria_button.clicked.connect(self._add_sort_criteria)

        self.exit_button.clicked.connect(self.close)
        self.load_orders_history(self._data)

    def _get_criterias(self):
        return [
                    self.sort_criteria_table.item(i, 0).text()
                    for i in range(self.sort_criteria_table.rowCount())
               ]

    def _add_sort_criteria(self):
        criteria = self.columns_combo_box.currentText()

        if criteria in self._get_criterias():
            msg.error_message(Errors.ERROR_SAME_CRITERIA.format(criteria))
            return

        criteria_row = self.sort_criteria_table.rowCount()
        self.sort_criteria_table.insertRow(criteria_row)

        delete_criteria_button = QtWidgets.QPushButton("")
        delete_criteria_button.setIcon(QtGui.QIcon(Const.IMAGES_PATH.format("del_file_icon")))
        delete_criteria_button.clicked.connect(self._detele_sort_criteria)

        item = QtWidgets.QTableWidgetItem(criteria)
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        item.setFlags(QtCore.Qt.ItemIsEnabled)

        self.sort_criteria_table.setItem(criteria_row, 0, item)
        self.sort_criteria_table.setCellWidget(criteria_row, 1, delete_criteria_button)

    def _detele_sort_criteria(self):
        self.sort_criteria_table.removeRow(self.sort_criteria_table.currentRow())

    def sort_table(self):

        asc = self.asc_check_box.isChecked()
        sorting_criterias = self._get_criterias()

        if not sorting_criterias:
            msg.error_message(Errors.NO_SORT_CRITERIA)
        print(sorting_criterias)
        sorted_data = self._data.sort_values(by=sorting_criterias, ascending=asc)

        self.load_orders_history(sorted_data)

    def state_search(self):
        data = self._data[self._data["Order status"] == self.states_combo_box.currentText()]
        print(data
        )
        self.load_orders_history(data)

    def load_orders_history(self, orders_history: pd.DataFrame):
        self.all_client_orders_table.setRowCount(0)
        rows, cols = orders_history.shape

        widget_funcs.config_table(
            self.all_client_orders_table,
            rows,
            cols,

            orders_history.columns,
            [
                (0, QtWidgets.QHeaderView.Stretch),
                (1, QtWidgets.QHeaderView.ResizeToContents),
                (2, QtWidgets.QHeaderView.ResizeToContents),
                (3, QtWidgets.QHeaderView.ResizeToContents),
                (4, QtWidgets.QHeaderView.ResizeToContents),
                (5, QtWidgets.QHeaderView.ResizeToContents),
                (6, QtWidgets.QHeaderView.ResizeToContents),
                (7, QtWidgets.QHeaderView.ResizeToContents),
            ],
            enable_column_sort=False
        )

        for i in range(rows):
            for j in range(cols):
                item = QtWidgets.QTableWidgetItem(str(orders_history.iloc[i][j]))
                item.setTextAlignment(QtCore.Qt.AlignCenter)
                item.setFlags(QtCore.Qt.ItemIsEnabled)
                self.all_client_orders_table.setItem(i, j, item)
