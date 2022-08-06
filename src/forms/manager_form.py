import PyQt5.QtWidgets
# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from tabulate import tabulate

import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests
from config.constants import (Const, Errors, Order, ReviewsMessages,
                              WindowsNames)

manager_form, manager_base = uic.loadUiType(
    uifile=Const.MANAGER_UI_PATH
)


class ManagerForm(manager_form, manager_base ):
    def __init__(self, user):

        super(manager_base, self).__init__()
        self.setupUi(self)

        self.user = user
