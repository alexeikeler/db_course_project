-----------------------------------------------------------------------------------------------------
--Function for getting brief info about employee
-----------------------------------------------------------------------------------------------------

DROP FUNCTION get_employee_info(shop_num integer, pos varchar);
CREATE OR REPLACE FUNCTION get_employee_info(shop_num integer, pos varchar)
RETURNS TABLE (
    employee_id_ integer,
    employee_name_ varchar,
    employee_position_ varchar,
    employee_place_of_work_ varchar
)
AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
                employee.employee_id,
                CAST(employee.firstname ||' '|| employee.lastname AS varchar) employee_name,
                employee.employee_position,
                book_shop.name_of_shop
            FROM
                book_shop, employee
            WHERE
                employee.employee_position = pos
            AND
                employee.firstname !~ '\d+$'
            AND
                employee.place_of_work = shop_num
            AND
                book_shop.shop_id = employee.place_of_work;

        END;
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_employee_info(place_of_work integer, pos varchar) FROM public;

GRANT EXECUTE ON FUNCTION get_employee_info(place_of_work integer, pos varchar) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function to get info about particular shop
-----------------------------------------------------------------------------------------------------

DROP FUNCTION get_shop_info(shop_num integer);
CREATE OR REPLACE FUNCTION get_shop_info(shop_num integer)
RETURNS TABLE (
    shop_id_ integer,
    name_of_shop_ varchar,
    employees_num_ varchar,
    post_code_ varchar,
    country_ varchar,
    city_ varchar,
    street_ varchar
) AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
                shop_id, name_of_shop, number_of_employees::varchar, post_code, country, city, street
            FROM
                book_shop
            WHERE
                book_shop.shop_id = shop_num;
        END;
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_shop_info(shop_num integer) FROM public;

GRANT EXECUTE ON FUNCTION get_shop_info(shop_num integer) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Get info about client by login
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_client_info(client_login_ varchar)
RETURNS TABLE (
    user_login varchar,
    user_first_name varchar,
    user_last_name varchar,
    user_phone_number varchar,
    user_email varchar,
    user_delivery_address varchar
) AS
    $$
    BEGIN
       RETURN QUERY

       SELECT client_login, client_firstname, client_lastname, phone_number, email, delivery_address
       FROM client
       WHERE client.client_login = client_login_;

    END
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_client_info(client_login_ varchar) FROM public;

GRANT EXECUTE ON FUNCTION get_client_info(client_login_ varchar) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function to get full info about certain book
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION concrete_book_full_info(
    book_title varchar,
    publ_date date
)
    RETURNS TABLE(
        author_ varchar,
        title_ varchar,
        genre_ varchar,
        available_amount_ int2,
        shop_ integer,
        binding_type_ varchar,
        number_of_pages_ int2,
        publishing_date_ date,
        publishing_agency_ varchar,
        paper_type_ varchar,
        price_ numeric(7, 2)
    )  AS
    $$
    BEGIN
        RETURN QUERY
            SELECT
                    author,
                    title,
                    genre,
                    available_amount,
                    shop,
                    binding_type,
                    number_of_pages,
                    publishing_date,
                    publising_agency_name,
                    paper_quality,
                    price
                FROM
                    available_books_view
                WHERE
                    available_books_view.title = book_title
                AND
                    available_books_view.publishing_date = publ_date;
    END;

$$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION concrete_book_full_info(
    book_title varchar,
    publ_date date
) FROM public;

GRANT EXECUTE ON FUNCTION concrete_book_full_info(
    book_title varchar,
    publ_date date
) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function for getting main info about books which are available for sale
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION available_books_main_info(
    author_name varchar,
    book_title varchar,
    book_genre varchar,
    min_price numeric(7, 2),
    max_price numeric(7, 2)
)
    RETURNS TABLE(
        author_info varchar,
        title_info varchar,
        genre_info varchar,
        date_of_publishing date,
        price_info numeric(7, 2)) AS
    $$
    BEGIN
        RETURN QUERY

            SELECT author, title, genre, publishing_date, price
                FROM
                    available_books_view
                WHERE
                    available_books_view.author LIKE author_name
                AND
                    available_books_view.title LIKE book_title
                AND
                    available_books_view.genre LIKE book_genre
                AND
                    available_books_view.price BETWEEN min_price AND max_price;
    END;

$$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION available_books_main_info(
    author_name varchar,
    book_title varchar,
    book_genre varchar,
    min_price numeric(7, 2),
    max_price numeric(7, 2)
) FROM public;

GRANT EXECUTE ON FUNCTION available_books_main_info(
    author_name varchar,
    book_title varchar,
    book_genre varchar,
    min_price numeric(7, 2),
    max_price numeric(7, 2)
) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function for updating client information
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_client_info(login varchar, subject varchar, new_value varchar)
RETURNS BOOL AS
    $$
    BEGIN
       CASE subject

           WHEN 'login'
               THEN
                   UPDATE client
                   SET client_login = new_value
                   WHERE client_login = login;
                   RETURN TRUE;

           WHEN 'first_name'
               THEN
                   UPDATE client
                   SET client_firstname = new_value
                   WHERE client_login = login;
                   RETURN TRUE;

           WHEN 'last_name'
               THEN
                   UPDATE client
                   SET client_lastname = new_value
                   WHERE client_login = login;
                   RETURN TRUE;

            WHEN 'phone_number'
                THEN
                    UPDATE client
                    SET phone_number = new_value
                    WHERE client_login = login;
                    RETURN TRUE;

            WHEN 'email'
                THEN
                    UPDATE client
                    SET email = new_value
                    WHERE client_login = login;
                    RETURN TRUE;

            WHEN 'delivery_address'
                THEN
                    UPDATE client
                    SET delivery_address = new_value
                    WHERE client_login = login;
                    RETURN TRUE;
           ELSE
                RAISE INFO 'Error in function update_client_info.';
                RETURN FALSE;
    END CASE;
    END
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION update_client_info(login varchar, subject varchar, new_value varchar) FROM public;

GRANT EXECUTE ON FUNCTION update_client_info(login varchar, subject varchar, new_value varchar) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function to get info about orders which must be processesed by shop assitant
DROP FUNCTION get_shop_assistant_orders(sa_login varchar);
CREATE OR REPLACE FUNCTION get_shop_assistant_orders(sa_login varchar)
RETURNS TABLE (
    order_id_ integer,
    state_ varchar,
    customer_name_ varchar,
    customer_phone_num varchar,
    customer_email varchar,
    customer_login_ varchar,
    ordered_book varchar,
    quantity_ integer,
    ordering_date_ timestamp(0)

) AS
$$
    DECLARE
        sa_id integer;
    BEGIN

        SELECT employee.employee_id INTO sa_id FROM employee WHERE employee.employee_login = sa_login;
        RAISE INFO 'sa_id %', sa_id;
        RETURN QUERY

        SELECT
            client_order.order_id,
            client_order.order_status,
            CAST(client.client_firstname ||' '|| client.client_lastname AS varchar) customer_name,
            client.phone_number,
            client.email,
            client.client_login,
            book.title,
            client_order.quantity,
            client_order.date_of_order

        FROM
            client, edition, authority, book, client_order, chosen
        WHERE
            client_order.sender = sa_id
        AND
            client.client_id = client_order.reciever
        AND
            client_order.order_status IN ('Оплачен', 'Обработан', 'Доставляется')
        AND
            client_order.order_id = chosen.order_id
        AND
            chosen.edition_number = edition.edition_number
        AND
            edition.authority_id = authority.authority_id
        AND
            book.book_id = authority.edition_book;
    END;
$$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_shop_assistant_orders(sa_place_of_work varchar) FROM public;

GRANT EXECUTE ON FUNCTION get_shop_assistant_orders(sa_place_of_work varchar) TO user_shop_assistant;

-----------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
DROP FUNCTION get_authors(author_name varchar);
CREATE OR REPLACE FUNCTION get_authors(author_name varchar)
RETURNS TABLE
(
    author_id_ integer,
    author_name_ varchar,
    date_of_birth_ date,
    date_of_death_ date
)
AS
    $$
    BEGIN
        RETURN QUERY
        SELECT
            author_id,
            CAST(firstname || ' ' || lastname AS varchar) as auth_name,
            date_of_birth,
            date_of_death
        FROM
            author
        WHERE
            author.firstname || ' ' || author.lastname LIKE author_name
        ORDER BY
            author_id;
    END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_authors(author_name varchar) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    get_authors(author_name varchar) TO user_manager;

------------------------------------------------------------------------------------------------------------------------
DROP FUNCTION get_cli_orders_statuses(client_login_ varchar);
CREATE OR REPLACE FUNCTION get_cli_orders_statuses(client_login_ varchar)
RETURNS TABLE(
    order_status_ varchar,
    couned_ integer
             )
AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    order_status, count(order_status)::int
                FROM
                    client_order, client
                WHERE
                    reciever = client.client_id
                AND
                    client.client_login = client_login_
                GROUP BY
                    order_status;
        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_cli_orders_statuses(client_login_ varchar) FROM public;
GRANT EXECUTE ON FUNCTION get_cli_orders_statuses(client_login_ varchar) TO user_client;
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_orders_distribtuion_by_month(client_login_ varchar)
RETURNS TABLE(
    date_ timestamp(0),
    counted_ integer
             )
AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
               DATE_TRUNC('month', date_of_order) AS  production_to_month,
               COUNT(order_id):: int
            FROM
                client_order, client
            WHERE
                reciever = client.client_id
            AND
                client.client_login = client_login_
            GROUP BY DATE_TRUNC('month', date_of_order);
        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_orders_distribtuion_by_month(client_id integer)FROM public;
GRANT EXECUTE ON FUNCTION get_orders_distribtuion_by_month(client_id integer) TO user_client;
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
DROP FUNCTION get_client_sales_by_genre(client_login_ varchar);
CREATE OR REPLACE FUNCTION get_client_sales_by_genre(client_login_ varchar)
RETURNS TABLE(
    genre_ varchar,
    money_spend_ numeric(10, 2)
             )
AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
               genre_type AS genre,
               SUM(SUM(sales.sum_to_pay)) OVER(PARTITION BY genre_type) AS sum_per_genre
            FROM
                sales, client_order, client, chosen
            WHERE
                sales.order_id = chosen.order_id
            AND
                chosen.order_id = client_order.order_id
            AND
                client_order.reciever = client.client_id
            AND
                client.client_login = client_login_
            GROUP BY genre_type;
        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_client_sales_by_genre(clien_login_ varchar)FROM public;
GRANT EXECUTE ON FUNCTION get_client_sales_by_genre(clien_login_ varchar) TO user_client;
------------------------------------------------------------------------------------------------------------------------
