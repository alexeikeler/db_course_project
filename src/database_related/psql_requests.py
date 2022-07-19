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

    except(Exception, pc2.DatabaseError) as error:
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
    delivery_address_: str
) -> None:

    try:
        with connection.cursor() as cursor:
            cursor.callproc("create_client", (
                    client_firstname_,
                    client_lastname_,
                    phone_number_,
                    email_,
                    client_login_,
                    client_password_,
                    delivery_address_
                )
            )
            result = cursor.fetchone()

            if result is not None and result[0]:
                msg.info_message(f"New user {client_login_} created succssesfully.")

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


# Selecting brief info about all books selling in shops
def available_books(
        connection,
        author_name: str,
        book_title: str,
        book_genre: str,
        min_price: float,
        max_price: float
):

    try:
        with connection.cursor() as cursor:
            cursor.callproc("available_books_main_info", (
                author_name,
                book_title,
                book_genre,
                min_price,
                max_price
            )
        )
            result = cursor.fetchall()
            return result

    except(Exception, pc2.DatabaseError) as error:
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

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


# Selecting brief info about all books selling in shops
def full_book_info(
        connection,
        book_title,
        publishing_date
):

    try:
        with connection.cursor(cursor_factory = pc2.extras.RealDictCursor) as cursor:
            cursor.callproc("concrete_book_full_info", (
                book_title,
                publishing_date
            )
        )
            result = cursor.fetchone()
            return result

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_book_reviews(connection, book_title, edition_publishing_date):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_book_reviews", (
                book_title,
                edition_publishing_date
            )
        )
            result = cursor.fetchall()
            return result

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def add_user_review(connection, user_login, book_title, book_publ_date, review_text):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("insert_user_book_review", (
                user_login,
                book_title,
                book_publ_date,
                review_text
                )
            )

        connection.commit()

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def delete_user_book_review(connection, user_login, review_date, review_text):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("delete_user_review_about_book", (
                review_date,
                user_login,
                review_text,
                )
            )
        connection.commit()

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_client_info(connection, user_login):
    try:
        with connection.cursor(cursor_factory = psycopg2.extras.RealDictCursor) as cursor:
            cursor.callproc("get_client_info", (user_login,))
            result = cursor.fetchone()
            return result

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def change_client_password(connection, client_login, client_old_password, client_new_password):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("change_client_password", (client_login, client_old_password, client_new_password))
            result = cursor.fetchone()
            connection.commit()
            return result

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))


def update_client_info(connection, login, update_subject, new_value):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("update_client_info", (login, update_subject, new_value))
            result = cursor.fetchone()
            connection.commit()
            return result

    except(Exception, pc2.DatabaseError) as error:
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

            cursor.callproc("add_order", (
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
            )
        )
            connection.commit()

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def update_user_order(connection, ordering_date, status):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("update_user_order", (ordering_date, status))
            connection.commit()

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()


def get_client_orders(connection, login):
    try:
        with connection.cursor() as cursor:
            cursor.callproc("get_client_orders", (login,))
            result = cursor.fetchall()
            connection.commit()
            return result

    except(Exception, pc2.DatabaseError) as error:
        msg.error_message(str(error))
        connection.rollback()
