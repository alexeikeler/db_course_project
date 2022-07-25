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

GRANT EXECUTE ON FUNCTION get_shop_info(shop_num integer) TO user_client

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