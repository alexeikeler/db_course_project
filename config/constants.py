from dataclasses import dataclass


@dataclass
class Const:

    # UI PATH CONST #
    LOGIN_UI_PATH: str = "ui/login.ui"
    CREATE_ACCOUNT_UI_PATH: str = "ui/create_account.ui"
    SHOP_FORM_UI_PATH: str = "ui/shop_form.ui"
    BOOKS_INFO_FORM_UI_PATH: str = "ui/full_book_info.ui"
    REVIEW_FORM_UI_PATH: str = 'ui/review_dialog.ui'
    CHANGE_PSWRD_FORM_UI_PATH: str = 'ui/change_password.ui'
    BUY_BOOK_UI_PATH: str = 'ui/buy_book.ui'

    USER_ACCOUNT_TAB_FORM_UI_PATH: str = 'ui/client_account_tab.ui'
    SHOP_CART_TAB_UI_PATH: str = 'ui/shop_cart_tab.ui'
    # ROLES PATH CONST #
    USER_CHECKER_ROLE_CONFIG_PATH: str = "config/user_checker_role_config.ini"
    CLIENT_ROLE_CONFIG_PATH: str = "config/client_role_config.ini"

    # ERROR CONSTS #
    NO_LOG_OR_PASS: str = "Error! Login or password field is empty!"
    WRONG_USR_NAME_OR_PASS: str = "Wrong username or password!"

    # ELSE #
    IMAGES_PATH: str = "/home/alexeikeler/OrgDB_kp/project/images/{0}.png"


@dataclass
class Order:

    ORDER_DF_COLUMNS: tuple = (
        "Book",
        "Title",
        "Publishing date",
        "Ordering date",
        "Shop",
        "Reciever",
        "Address",
        "Status",
        "Price, UAH",
        "Payment type",
        "User info",
        "Quantity",
        "Confirm order",
        "Delete order"
    )

    ORDER_EMPTY_CELL: str = "-"

    ORDER_IN_CART: str = 'В корзине'
    ORDER_PAYED: str = 'Оплачен'
    ORDER_IN_PROCESS: str = 'Обрабатывается'
    ORDER_FINISHED: str = 'Доставлен'
    ORDER_DECLINED: str = 'Отменён'

    PAYMENT_TYPE_CASH: str = 'Наличные'
    PAYMENT_TYPE_CARD: str = 'Карта'

    ORDER_TABLE_SIZE: tuple = (0, 0, 1, 4)
    TOTAL_SUM_TABLE_SIZE: tuple = (3, 0, 4, 4)


