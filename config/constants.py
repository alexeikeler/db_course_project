from dataclasses import dataclass
from collections import namedtuple

@dataclass
class Const:

    CONFIG_SECTION: str = "postgresql"

    # UI PATH CONST #
    LOGIN_UI_PATH: str = "ui/login.ui"
    CREATE_ACCOUNT_UI_PATH: str = "ui/create_account.ui"
    SHOP_FORM_UI_PATH: str = "ui/shop_form.ui"
    BOOKS_INFO_FORM_UI_PATH: str = "ui/full_book_info.ui"
    REVIEW_FORM_UI_PATH: str = "ui/review_dialog.ui"
    CHANGE_PSWRD_FORM_UI_PATH: str = "ui/change_password.ui"
    BUY_BOOK_UI_PATH: str = "ui/buy_book.ui"
    EMPLOYEE_REVIEWS_UI_PATH: str = 'ui/employees_reviews.ui'
    SHOP_REVIEWS_UI_PATH: str = 'ui/shop_reviews.ui'

    USER_ACCOUNT_TAB_FORM_UI_PATH: str = "ui/client_account_tab.ui"
    SHOP_CART_TAB_UI_PATH: str = "ui/shop_cart_tab.ui"

    SHOP_ASSISTANT_UI_PATH: str = "ui/shop_assistant_form.ui"
    # ROLES PATH CONST #
    SHOP_ASSISTANT_CONFIG_PATH: str = "config/shop_assistant_role_config.ini"
    CLIENT_ROLE_CONFIG_PATH: str = "config/client_role_config.ini"
    USER_CHECKER_ROLE_CONFIG_PATH: str = "config/user_checker_role_config.ini"

    # ELSE #
    IMAGES_PATH: str = "/home/alexei/Uni/3_2/OrgDB_kp/db_course_project/frontend/images/{0}.png"
    HTML_FILES_PATH: str = "/home/alexei/Uni/3_2/OrgDB_kp/db_course_project/frontend/html_files/{0}.html"

    REVIEW_DELETED: str = "Review successfully deleted! Update reviews table!"

    ROLES_NMD_TPL: namedtuple = namedtuple(
        "ROLES_NMD_TPL", "DIRECTOR_ROLE ADMIN_ROLE MANAGER_ROLE SHOP_ASSISTANT_ROLE CLIENT_ROLE USER_CHECKER_ROLE"
    )
    ROLES = ROLES_NMD_TPL("director", "admin", "manager", "shop_assistant", "client", "user_checker")


@dataclass
class Order:

    ORDER_DF_COLUMNS: tuple = (
        "Book",
        "Title",
        "Published",
        "Ordered",
        "Shop",
        "Reciever",
        "Address",
        "Status",
        "Price, UAH",
        "Payment type",
        "User info",
        "Quantity",
        "Pay order",
        "Delete order"
    )

    CLIENT_ORDERS_COLUMNS: tuple = (
        "Title",
        "Genre",
        "Quantity",
        "Paid price",
        "Order status",
        "Ordering date",
        "Returning date"
    )

    ORDER_EMPTY_CELL: str = "-"

    ORDER_IN_CART: str = "В корзине"
    ORDER_PAYED: str = "Оплачен"
    ORDER_IN_PROCESS: str = "Обрабатывается"
    ORDER_FINISHED: str = "Доставлен"
    ORDER_DECLINED: str = "Отменён"

    PAYMENT_TYPE_CASH: str = "Наличные"
    PAYMENT_TYPE_CARD: str = "Карта"

    ORDER_TABLE_SIZE: tuple = (0, 0, 1, 4)
    TOTAL_SUM_TABLE_SIZE: tuple = (3, 0, 4, 4)


@dataclass
class HtmlFiles:
    CLIENT_ORDER_STATUSES_HTML: str = Const.HTML_FILES_PATH.format("order_statuses_piechart")


@dataclass
class ShopAndEmployee:
    SHOPS: tuple = ("1", "2", "3", "4", "5")


@dataclass
class Errors:
    # Employee data
    EMPLOYEE_DATA_NOT_FOUND: str = "EmployeeDataNotFoundError"
    SHOP_DATA_NOT_FOUND: str = "ShopDataNotFound"

    # Login errors
    NO_LOG_OR_PASS: str = "Error! Login or password field is empty!"
    WRONG_USR_NAME_OR_PASS: str = "Wrong username or password!"
    ERROR_DB_CONNECTION: str = "Error! Couldn't connect to database!"



