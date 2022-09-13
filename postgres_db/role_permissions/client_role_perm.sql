--Client role for client session
------------------------------------------------------------------

CREATE USER user_client WITH PASSWORD 'DPZKSVMTbT23';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_client;
GRANT USAGE ON SCHEMA public TO user_client;

------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION delete_user() TO user_client;

GRANT EXECUTE ON FUNCTION update_users_table() TO user_client;

GRANT EXECUTE ON FUNCTION create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
    TO user_client;

GRANT EXECUTE ON FUNCTION get_min_max_book_prices() TO user_client;

GRANT EXECUTE ON FUNCTION available_books_main_info(
    author_name varchar,
    book_title varchar,
    book_genre varchar,
    min_price numeric(7, 2),
    max_price numeric(7, 2)
)
    TO user_client;

GRANT EXECUTE ON FUNCTION concrete_book_full_info(book_title varchar,publ_date date) TO user_client;

GRANT EXECUTE ON FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date) TO user_client;

GRANT EXECUTE ON FUNCTION insert_user_book_review(
    user_login varchar,
    book_title varchar,
    book_publishing_date date,
    user_review_text text
)
    TO user_client;

GRANT EXECUTE ON FUNCTION delete_user_review_about_book(
    review_date_ timestamp(0),
    user_login_ varchar,
    review_text_ text
)
    TO user_client;


GRANT EXECUTE ON FUNCTION get_client_info(client_login_ varchar) TO user_client;

GRANT EXECUTE ON FUNCTION add_order(
    book_title_ varchar,
    date_of_publishing_ date,
    ordering_date timestamp(0),
    shop_number integer,
    cli_login_ varchar,
    delivery_address_ varchar,
    order_status_ varchar,
    sum_to_pay_ numeric(6, 2),
    payment_type_ varchar,
    additional_info_ varchar,
    quantity_ integer
)
    TO user_client;

GRANT EXECUTE ON FUNCTION reduce_available_books() TO user_client;

GRANT EXECUTE ON FUNCTION update_client_info(login varchar, subject varchar, new_value varchar) TO user_client;

GRANT EXECUTE ON FUNCTION update_user_order(ordering_date timestamp(0), status varchar) TO user_client;

GRANT EXECUTE ON FUNCTION return_ordered_books() TO user_client;

GRANT EXECUTE ON FUNCTION get_client_orders(client_login varchar) TO user_client;

GRANT EXECUTE ON FUNCTION get_employee_info(place_of_work integer, pos varchar) TO user_client;

GRANT EXECUTE ON FUNCTION get_reviews_about_employee(employee_id integer)TO user_client;

GRANT EXECUTE ON FUNCTION add_employee_review(user_login varchar, employee_id integer, review_text text) TO user_client;

GRANT EXECUTE ON FUNCTION get_shop_info(shop_num integer) TO user_client;

GRANT EXECUTE ON FUNCTION get_shop_reviews(shop_num integer) TO user_client;

GRANT EXECUTE ON FUNCTION delete_shop_review(
shop_id_ integer,
user_login_ varchar,
review_date_ timestamp(0),
review_text_ text
)
    TO user_client;

GRANT EXECUTE ON FUNCTION add_shop_review(
user_login_ varchar,
shop_id_ integer,
user_review_text_ text
)
    TO user_client;

GRANT EXECUTE ON FUNCTION
    delete_review(id integer) TO user_client;