import psycopg2 as pc2
import psycopg2.extras

# noinspection PyUnresolvedReferences
import src.custom_qt_widgets.message_boxes as msg


def check_user_existence(connection, user_login: str, user_password: str):

    try:
        with connection.cursor() as cursor:
            cursor.callproc("verify_user", (user_login, user_password))
            result = cursor.fetchone()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(repr(error))
        connection.rollback()


def create_user(
    connection,
    client_firstname_: str,
    client_lastname_: str,
    phone_number_: str,
    email_: str,
    client_login_: str,
    client_password_: str,
    delivery_address_: str,
) -> None:

    try:
        with connection.cursor() as cursor:
            cursor.callproc(
                "create_client",
                (
                    client_firstname_,
                    client_lastname_,
                    phone_number_,
                    email_,
                    client_login_,
                    client_password_,
                    delivery_address_,
                ),
            )
            result = cursor.fetchone()

            if result is not None and result[0]:
                msg.info_message(f"New user {client_login_} created succssesfully.")

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


# Selecting brief info about all books selling in shops
def available_books(
    connection,
    author_name: str,
    book_title: str,
    book_genre: str,
    min_price: float,
    max_price: float,
):

    try:
        with connection.cursor() as cursor:
            cursor.callproc(
                "available_books_main_info",
                (author_name, book_title, book_genre, min_price, max_price),
            )
            result = cursor.fetchall()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


# Select min and max price in available books view for range slider
def get_min_max_book_price(connection):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_min_max_book_prices")
            result = cursor.fetchone()
            print(result)
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


# Selecting brief info about all books selling in shops
def full_book_info(connection, book_title, publishing_date):

    try:
        with connection.cursor(cursor_factory=pc2.extras.RealDictCursor) as cursor:
            cursor.callproc("concrete_book_full_info", (book_title, publishing_date))
            result = cursor.fetchone()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_book_reviews(connection, book_title, edition_publishing_date):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_book_reviews", (book_title, edition_publishing_date))
            result = cursor.fetchall()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def add_user_review(connection, user_login, book_title, book_publ_date, review_text):
    try:
        with connection.cursor() as cursor:
            cursor.callproc(
                "insert_user_book_review",
                (user_login, book_title, book_publ_date, review_text),
            )

        connection.commit()

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_client_info(connection, user_login):
    try:
        with connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            cursor.callproc("get_client_info", (user_login,))
            result = cursor.fetchone()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def change_password(connection, login, old_pass, new_pass):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("change_password", (login, old_pass, new_pass))
            result = cursor.fetchone()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))


def update_client_info(connection, login, update_subject, new_value):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("update_client_info", (login, update_subject, new_value))
            result = cursor.fetchone()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def add_order(
    connection,
    book_title_,
    date_of_publishing_,
    ordering_time,
    shop_number,
    cli_login_,
    delivery_address_,
    order_status_,
    sum_to_pay_,
    payment_type_,
    additional_info_,
    quantity_,
):
    try:
        with connection.cursor() as cursor:

            cursor.callproc(
                "add_order",
                (
                    book_title_,
                    date_of_publishing_,
                    ordering_time,
                    shop_number,
                    cli_login_,
                    delivery_address_,
                    order_status_,
                    sum_to_pay_,
                    payment_type_,
                    additional_info_,
                    quantity_,
                ),
            )
            result = cursor.fetchone()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def update_user_order(connection, order_id, status):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("update_user_order", (order_id, status))
            result = cursor.fetchone()
            connection.commit()
            return result[0]

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_client_orders(connection, login):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_client_orders", (login,))
            result = cursor.fetchall()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_employee_info(connection, shop_number, position):
    try:
        with connection.cursor(cursor_factory=pc2.extras.RealDictCursor) as cursor:
            cursor.callproc("get_employee_info", (shop_number, position))
            result = cursor.fetchone()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_reviews_about_employee(connection, empl_id):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_reviews_about_employee", (empl_id,))
            result = cursor.fetchall()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def add_employee_review(connection, user_login, empl_id, user_review_text):
    try:
        with connection.cursor() as cursor:
            cursor.callproc(
                "add_employee_review", (user_login, empl_id, user_review_text)
            )
            result = cursor.fetchall()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_shop_info(connection, shop_id):
    try:
        with connection.cursor(cursor_factory=pc2.extras.RealDictCursor) as cursor:
            cursor.callproc("get_shop_info", (shop_id,))
            result = cursor.fetchone()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_shop_reviews(connection, shop_id):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_shop_reviews", (shop_id,))
            result = cursor.fetchall()
            connection.commit()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def add_shop_review(connection, user_login, shop_id, user_review_text):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("add_shop_review", (user_login, shop_id, user_review_text))
            connection.commit()

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_shop_assistant_orders(connection, sa_login):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_shop_assistant_orders", (sa_login,))
            results = cursor.fetchall()
            return results

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_reviews_for_shop_assistant(connection, sa_login, subject):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_reviews_for_shop_assistant", (sa_login, subject))
            results = cursor.fetchall()
            return results

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def delete_review(connection, id):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("delete_review", (id,))
            connection.commit()
    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_employee_id(connection, login):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_employee_id", (login,))
            result = cursor.fetchone()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_genre_sales(connection, manager_id, l_time_border, r_time_border):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_genre_sales", (manager_id, l_time_border, r_time_border))
            result = cursor.fetchall()
            return result

    except (Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()
