from dataclasses import dataclass


@dataclass
class Const:

    # UI PATH CONST #
    LOGIN_UI_PATH: str = "ui/login.ui"
    CREATE_ACCOUNT_UI_PATH: str = "ui/create_account.ui"
    SHOP_FORM_UI_PATH: str = "ui/shop_form.ui"
    BOOKS_INFO_FORM_UI_PATH: str = "ui/full_book_info.ui"
    REVIEW_FORM_UI_PATH: str = "ui/review_dialog.ui"
    CHANGE_PSWRD_FORM_UI_PATH: str = "ui/change_password.ui"
    BUY_BOOK_UI_PATH: str = "ui/buy_book.ui"
    EMPLOYEE_REVIEWS_UI_PATH: str = 'ui/employees_reviews.ui'

    USER_ACCOUNT_TAB_FORM_UI_PATH: str = "ui/client_account_tab.ui"
    SHOP_CART_TAB_UI_PATH: str = "ui/shop_cart_tab.ui"
    # ROLES PATH CONST #
    USER_CHECKER_ROLE_CONFIG_PATH: str = "config/user_checker_role_config.ini"
    CLIENT_ROLE_CONFIG_PATH: str = "config/client_role_config.ini"

    # ELSE #
    IMAGES_PATH: str = "/home/alexei/Uni/3_2/OrgDB_kp/db_course_project/frontend/images/{0}.png"
    HTML_FILES_PATH: str = "/home/alexei/Uni/3_2/OrgDB_kp/db_course_project/frontend/html_files/{0}.html"

    REVIEW_DELETED: str = "Review successfully deleted! Update reviews table!"

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
    POSITIONS: tuple = ("director", "manager", "admin", "shop_assistant")
    SHOPS: tuple = ("1", "2", "3", "4", "5")


@dataclass
class Errors:
    # Employee data
    EMPLOYEE_DATA_NOT_FOUNT: str = "DataNotFoundError"

    # Login errors
    NO_LOG_OR_PASS: str = "Error! Login or password field is empty!"
    WRONG_USR_NAME_OR_PASS: str = "Wrong username or password!"



