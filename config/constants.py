import os.path
from collections import namedtuple
from dataclasses import dataclass


@dataclass
class Const:

    EMPTY_CELL: str = "-"
    CONFIG_SECTION: str = "postgresql"

    # UI PATH CONST #
    LOGIN_UI_PATH: str = "ui/login.ui"
    CREATE_ACCOUNT_UI_PATH: str = "ui/create_account.ui"
    SHOP_FORM_UI_PATH: str = "ui/shop_form.ui"
    BOOKS_INFO_FORM_UI_PATH: str = "ui/full_book_info.ui"
    REVIEW_FORM_UI_PATH: str = "ui/review_dialog.ui"
    CHANGE_PSWRD_FORM_UI_PATH: str = "ui/change_password.ui"
    BUY_BOOK_UI_PATH: str = "ui/buy_book.ui"
    EMPLOYEE_REVIEWS_UI_PATH: str = "ui/employees_reviews.ui"
    SHOP_REVIEWS_UI_PATH: str = "ui/shop_reviews.ui"
    SHOW_REVIEW_UI_PATH: str = "ui/review_show.ui"
    ADD_COPIES_UI_PATH: str = "ui/add_copies.ui"
    VIEW_CLIENT_ORDERS_UI_PATH: str = "ui/view_client_orders.ui"

    USER_ACCOUNT_TAB_FORM_UI_PATH: str = "ui/client_account_tab.ui"
    SHOP_CART_TAB_UI_PATH: str = "ui/shop_cart_tab.ui"
    SHOP_ASSISTANT_UI_PATH: str = "ui/shop_assistant_form.ui"
    MANAGER_UI_PATH: str = "ui/manager_form.ui"
    ADMIN_UI_PATH: str = "ui/admin_form.ui"
    DIRECTOR_UI_PATH: str = "ui/director_form.ui"

    # ROLES PATH CONST #
    SHOP_ASSISTANT_CONFIG_PATH: str = "config/shop_assistant_role_config.ini"
    CLIENT_ROLE_CONFIG_PATH: str = "config/client_role_config.ini"
    USER_CHECKER_ROLE_CONFIG_PATH: str = "config/user_checker_role_config.ini"
    MANAGER_ROLE_CONFIG_PATH: str = "config/manager_role_config.ini"
    ADMIN_ROLE_CONFIG_PATH: str = "config/admin_role_config.ini"
    DIRECTOR_ROLE_CONFIG_PATH: str = "config/director_role_config.ini"

    # IMAGE AND HTML FILES PATH
    IMAGES_PATH: str = "frontend/images/{0}.png"
    HTML_FILES_PATH: str = "frontend/html_files/{0}.html"

    PDF_REPORTS_FOLDER: str = "pdf_reports/{0}/"
    PDF_REPORTS_FILE: str = "{0}.pdf"
    ABS_REPORTS_PATH: str = os.path.abspath("pdf_reports")
    REPORTS_REGEX: str = "^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}).*"
    FOLDERS_REGEX: str = "^(m\d*)_reports"

    ROLES_NMD_TPL: namedtuple = namedtuple(
        "ROLES_NMD_TPL",
        "DIRECTOR_ROLE ADMIN_ROLE MANAGER_ROLE SHOP_ASSISTANT_ROLE CLIENT_ROLE USER_CHECKER_ROLE",
    )
    ROLES = ROLES_NMD_TPL(
        "director", "admin", "manager", "shop_assistant", "client", "user_checker"
    )


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
        "Delete order",
    )

    CLIENT_ORDERS_COLUMNS: tuple = (
        "Title",
        "Genre",
        "Quantity",
        "Paid price",
        "Order status",
        "Ordering date",
        "Returning date",
        "Delivering date",
    )

    ORDER_IN_CART: str = "В корзине"
    ORDER_PAYED: str = "Оплачен"
    ORDER_PROCESSED: str = "Обработан"
    ORDER_DELIVERING: str = "Доставляется"
    ORDER_FINISHED: str = "Доставлен"
    ORDER_DECLINED: str = "Отменён"

    PAYMENT_TYPE_CASH: str = "Наличные"
    PAYMENT_TYPE_CARD: str = "Карта"

    ORDER_TABLE_SIZE: tuple = (0, 0, 1, 4)
    TOTAL_SUM_TABLE_SIZE: tuple = (3, 0, 4, 4)

    SA_ORDER_DF_COLUMNS: tuple = (
        "Order ID",
        "State",
        "Customer name",
        "Phone number",
        "Email",
        "Login",
        "Title",
        "Quantity",
        "Ordering date",
    )

    ORDER_STATE_CHANGED: str = "Order # {0} state changed to {1}."

 #   get_client_orders_statuses_distribution
    ORDER_STATUSES_DISTR_DF_COLUMNS: tuple = ("Status", "Counted")
    ORDERS_DISTR_BY_MONTH_DF_COLUMNS: tuple = ("Month", "Counted")
    GENRE_SALES_DF_COLUMNS: tuple = ("Genre", "Sum per genre")


@dataclass
class HtmlFiles:
    CLIENT_ORDER_STATUSES_HTML: str = Const.HTML_FILES_PATH.format(
        "order_statuses_piechart"
    )


@dataclass
class ShopAndEmployee:
    SHOPS: tuple = ("1", "2", "3", "4", "5")
    BOOK_GENRE_TYPES: tuple = (
        "Детектив",
        "Роман",
        "Фантастика",
        "Фэнтези",
        "Психология",
        "Философия",
        "Программирование",
        "Триллер",
        "Научная литература",
        "Мемуары",
        "Проза",
        "Поэзия",
    )
    PAPER_QUALITY_TYPES: tuple = ("Для глубокой печати", "Типографическая", "Офсетная")
    BINDING_TYPES: tuple = ("Твёрдый", "Мягкий")

    DUMMY_ACC_IDS: tuple = (106, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69)
    CLIENT_ACTIVITY_DF_COLUMNS: tuple = (
        "Client ID",
        "Login",
        "Oldest order",
        "Newest order",
    )
    # EMPLOYEE_ACTIVITY_DF_COLUMNS: dict = dict(
    #    "ID":"", "Name": "", "Login": "", "Reviews": "", "Place of work": "", "Position": "", "Salary": "", "Phone number": "", "Email": ""
    # )
    # employee_id,lastname,firstname,employee_position,salary,phone_number,email,employee_login,place_of_work

    EMPLOYEE_ACTIVITY_DF_COLUMNS = {
        "ID": "employee_id",
        "Firstname": "firstname",
        "Lastname": "lastname",
        "Login": "employee_login",
        "Reviews": "",
        "Place of work": "place_of_work",
        "Position": "employee_position",
        "Salary": "salary",
        "Phone number": "phone_number",
        "Email": "email",
    }
    EMPL_REVIEW_COL = 4

    EMPLOYEE_SALARY_DF_COLUMNS: tuple = ("ID", "Name", "Position", "Salary", "Place of work")


@dataclass
class WindowsNames:

    ORDERS_TAB: str = "Orders"
    EMPLOYEES_REVIEWS_TAB: str = "Employees reviews"

    SHOPS_REVIEWS_TAB: str = "Shops reviews"
    BOOKS_REVIEWS_TAB: str = "Books reviews"

    MANAGER_REPORTS_TAB: str = "Reprorts"
    MANAGER_ADD_BOOKS: str = "Books and Authors"


@dataclass
class Errors:
    # Employee data
    EMPLOYEE_DATA_NOT_FOUND: str = "EmployeeDataNotFoundError"
    SHOP_DATA_NOT_FOUND: str = "ShopDataNotFound"

    # Login errors
    NO_LOG_OR_PASS: str = "Error! Login or password field is empty!"
    WRONG_USR_NAME_OR_PASS: str = "Wrong username or password!"
    ERROR_DB_CONNECTION: str = "Error! Couldn't connect to database!"

    # Order status changing error
    ORDER_STATUS_ERROR: str = "Error occurred while updating order # {0} state."

    # Author deletion error
    AUTHOR_DELETION_ERROR: str = (
        "Cannot delete author | {0} | with ID {1}."
        "\nOnly authors without books in shop can be removed!"
    )

    NO_AUTHOR_ID: str = "There is no author with ID {0}."

    # Empty book title
    EMPTY_TITLE: str = "Book title is empty!"

    # New edition creation error
    NEW_EDITION_ERROR: str = "Error occurred while adding new edition of {0} book."

    # Error no such folder
    NO_SUCH_FOLDER: str = "Error adding report. No such folder {0}."

    # No order
    NO_ORDER: str = "NO_ORDERS"
    CLIENT_NO_ORDERS: str = "Client |{0}| doesn't have any orders to reivew!"

    # Same criteria selected again
    ERROR_SAME_CRITERIA: str = "This criteria ({0}) is alredy selected!"

    # No sorting criteria were selected
    NO_SORT_CRITERIA: str = "No sorting criterias were selected!"

    # Client deletion error
    CLIENT_DEL_ERROR: str = (
        "Error deleting account with ID={0}. Client have unfinished orders."
    )

    # Attemt to delete dummy account
    DUMMY_ACC_DEL_ERROR: str = "You cannot delete special account!"

    # Attemp to delete yout own account
    SELF_ACC_DEL_ERROR: str = "You cannot delete your own account!"

    # Wrong update_subject
    ERROR_UPD_SUBJ: str = "Wrong update subject!"

    # Error updating employee data
    ERROR_EMPL_UPDATE: str = (
        "Error occurred while trying to update data for employee #{0}. "
        "Row: {1}, Col: {2}, Update value: {3}, Update subject: {4}"
    )

    ERROR_EMPL_DELETION: str = "Error deleting employee #{0}."

    ERROR_SALARY_UPDATE: str = "Error updating salary for employee # {0}."


@dataclass
class ReviewsMessages:
    # REVIEWS CONST
    REVIEW_DELETED: str = "Review successfully deleted! Update reviews table!"
    EMPLOYEES_REVIEWS: str = "Employees"
    BOOKS_REVIEWS: str = "Books"
    SHOPS_REVIEWS: str = "Shops"

    REVIEWS_DF_COLUMNS: tuple = ("ID", "Date", "By", "About", "Text")


@dataclass
class Sales:
    GENERAL_GENRE_SALES_DF_COLUMNS: tuple = ("Genre", "Sum", "Sold copies")
    IN_DEPTH_SALES: tuple = ("Genre", "Price", "Quantity", "Ordering date")
    MY_SALES_COLUMNS: tuple = ("Date", "Sum")
    MY_COMBO_BOX_FILLING: tuple = ("Month", "Year")
    REPORTS_DF_COLUMNS: tuple = ("Report",)
    TOP_SOLD_BOOKS: tuple = ("Title", "Quantity")
    AUTHORS_DF_COLUMNS: tuple = ("Id", "Author", "Date of birth", "Date of death")
    NOT_SOLD_BOOKS_DF_COLUMNS: tuple = ("Id", "Author", "Title")
    AVAILABLE_BOOKS_DF_COLUMNS: tuple = ("Id", "Author", "Title", "Available")

    ORDERS_STATUSES_COUNT_DF_COLUMNS: tuple = ("State", "Counted")
    PAYMENT_TYPES_COUNT_DF_COLUMNS: tuple = ("Payment type", "Counted")

    GENRE_SALES: str = "_genre_sales"
    MY_SALES: str = "_all_sales_by_{0}"
    TOP_BOOKS_SALES: str = "_top_selling_books"
    ORDERS_AND_PAY_PIECHART: str = "_orders_statuses_and_payment_piechart"
