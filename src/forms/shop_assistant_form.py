import src.custom_qt_widgets.message_boxes as msg
import src.database_related.psql_requests as Requests

# noinspection PyUnresolvedReferences
from PyQt5 import uic, QtWidgets, QtCore

from config.constants import Const

shop_assistant_form, shop_assistant_base = uic.loadUiType(uifile=Const.SHOP_ASSISTANT_UI_PATH)


class ShopAssistantForm(shop_assistant_form, shop_assistant_base):

    def __init__(self, user):

        super(shop_assistant_base, self).__init__()
        self.setupUi(self)

        self.user = user

