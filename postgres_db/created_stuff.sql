--Function for updating password
--------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION change_client_password(login varchar, old_password varchar, new_password varchar)
RETURNS boolean AS
    $$

    BEGIN

        IF EXISTS(
            SELECT *
            FROM client
            WHERE
                client.client_login = login
            AND
                client.client_password = encode(digest(old_password, 'sha256'), 'hex')
            )
            THEN
                UPDATE client
                SET
                    client_password = new_password
                WHERE
                    client_login = login;
                RETURN TRUE;

        ELSE
            RAISE WARNING 'Wrong password!';
            RETURN FALSE;

        END IF;

    END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    change_client_password(login varchar, old_password varchar, new_password varchar)
    FROM public;

GRANT EXECUTE ON FUNCTION
    change_client_password(login varchar, old_password varchar, new_password varchar)
    TO user_client;

--------------------------------------------------------------------------------------


------------------------------------------------------------------
--When client / employee account deleted delete it from users table
CREATE OR REPLACE FUNCTION delete_user()
RETURNS TRIGGER AS
    $$
    BEGIN
        IF (TG_TABLE_NAME = 'client')
        THEN

            DELETE FROM
                       users
                   WHERE
                       users.user_login = OLD.client_login
                    AND
                       users.user_password = OLD.client_password;
            RAISE INFO 'Deleted client %', OLD.client_login;

        ELSIF (TG_TABLE_NAME = 'employee')
            THEN
                DELETE FROM
                        users
                WHERE
                    users.user_login = OLD.employee_login
                AND
                    users.user_password = OLD.employee_password;
            RAISE INFO 'Deleted employee %', OLD.employee_login;

        END IF;

        RETURN NEW;
    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER delete_from_users
    AFTER DELETE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE delete_user();

CREATE TRIGGER delete_from_users
    AFTER DELETE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE delete_user();

REVOKE ALL ON FUNCTION
    delete_user()
    FROM public;

GRANT EXECUTE ON FUNCTION
    delete_user()
    TO user_client;
------------------------------------------------------------------

--Function and triggers for updating users table when new employee or client created
-----------------------------------------------
CREATE OR REPLACE FUNCTION update_users_table()
RETURNS trigger AS
$$
    BEGIN

        IF(TG_TABLE_NAME = 'client')
            THEN
                --when user changes only login
                IF NEW.client_login NOT LIKE OLD.client_login
                    THEN
                        RAISE INFO 'Updating user login from % to %', OLD.client_login, NEW.client_login;
                        UPDATE users
                        SET user_login = NEW.client_login
                        WHERE user_login = OLD.client_login;
                  ELSE
                    --when user changes password or new user has been created

                    INSERT INTO users(user_login, user_password, user_role)
                    VALUES (NEW."client_login", NEW."client_password", 'client')
                    ON CONFLICT (user_login)
                        DO UPDATE

                        SET user_login = EXCLUDED.user_login,
                            user_password = EXCLUDED.user_password;
                END IF;

        END IF;

        IF (TG_TABLE_NAME = 'employee')
            THEN
            RAISE INFO 'IN EMPLOYEE TABLE_NAME';
            INSERT INTO users (user_login, user_password, user_role)
            VALUES (NEW."employee_login", NEW."employee_password", NEW."employee_position")
            ON CONFLICT (user_login)
                        DO UPDATE
                        SET user_login = EXCLUDED.user_login,
                            user_password = EXCLUDED.user_password;
        END IF;
    RETURN NEW;
        END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER update_users_with_client
    AFTER INSERT OR UPDATE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();


CREATE TRIGGER update_users_with_employee
    AFTER INSERT OR UPDATE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();

REVOKE ALL ON FUNCTION
    update_users_table()
    FROM public;

GRANT EXECUTE ON FUNCTION
    update_users_table()
    TO user_client;

-----------------------------------------------

--Function and triggers for hashing passwords
------------------------------------------
CREATE OR REPLACE FUNCTION hash_password()
RETURNS trigger AS
$$
    BEGIN
        IF(TG_TABLE_NAME = 'client')
        THEN
            IF (TG_OP = 'INSERT' OR NEW.client_password NOT LIKE OLD.client_password)
                THEN
                    NEW.client_password = encode(digest(NEW.client_password, 'sha256'), 'hex');
                END IF;
            END IF;

        IF(TG_TABLE_NAME = 'employee')
        THEN
            IF (TG_OP = 'INSERT' OR NEW.employee_password NOT LIKE OLD.employee_password)
                THEN
                    NEW.employee_password = encode(digest(NEW.employee_password, 'sha256'), 'hex');
            END IF;
        END IF;

    RETURN NEW;
    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER make_client_password_hash
    BEFORE INSERT OR UPDATE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE hash_password();

CREATE TRIGGER make_employee_password_hash
    BEFORE INSERT OR UPDATE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE hash_password();

------------------------------------------



--Function to check create new client account
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
RETURNS TABLE (created bool) AS
$$
    BEGIN

        INSERT INTO
            client(client_firstname, client_lastname, phone_number, email, client_login, client_password, delivery_address)
        VALUES
            (client_firstname_, client_lastname_, phone_number_, email_, client_login_, client_password_, delivery_address_);

        RETURN QUERY
        SELECT EXISTS(
            SELECT * FROM client WHERE client.client_login = client_login_
        );
        END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
    FROM public;

GRANT EXECUTE ON FUNCTION
    create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
      TO user_client;
-----------------------------------------------------------------------

--Get min and max price for available books
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_min_max_book_prices()
RETURNS TABLE(min_price numeric(7,2), max_price numeric(7, 2)) AS
$$
    BEGIN
    RETURN QUERY
        SELECT MIN(price), MAX(price)
            FROM
                available_books_view;

    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_min_max_book_prices() FROM public;
GRANT EXECUTE ON FUNCTION get_min_max_book_prices() TO user_client;

-----------------------------------------------------------------------

-----------------------------------------------------------------------
--Function for main info about books which are available for sale
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

-----------------------------------------------------------------------
--Function to get full info about certain book
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

-----------------------------------------------------------------------
-- All reviews about concrete book
CREATE OR REPLACE FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date)
    RETURNS TABLE(
        review_by_ varchar,
        review_date_ timestamp(0),
        review_ text
    )  AS
    $$
    BEGIN
        RETURN QUERY
        SELECT user_login, review_date, review
            FROM
                book_reviews
            WHERE
                book_reviews.review_about_book = book_title_
            AND
                book_reviews.book_pubslishing_date = book_publishing_date_;
        END;

$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date) FROM public;
GRANT EXECUTE ON FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date) TO user_client;
-----------------------------------------------------------------------------------------------------

--Function for adding new review
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION insert_user_book_review(
    user_login varchar,
    book_title varchar,
    book_publishing_date date,
    user_review_text text
)
RETURNS VOID AS
    $$
    DECLARE
        user_id int2;
        book_id int2;
    BEGIN
       --get user_id by user_login
       SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login;

       --get book_id by book_title and date_of_publishing
       SELECT
           edition.authority_id INTO book_id FROM edition, authority, book
       WHERE
           edition.authority_id = authority.authority_id
       AND
           authority.edition_book = book.book_id
       AND
           book.title = book_title
       AND
           publishing_date = book_publishing_date;

      INSERT INTO client_review (review_date, review_by, review_about_book, review_text)
      VALUES (now()::timestamp(0), user_id, book_id, user_review_text);

    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION insert_user_book_review(
    user_login varchar,
    book_title varchar,
    book_publishing_date date,
    user_review_text text
) FROM public;

GRANT EXECUTE ON FUNCTION insert_user_book_review(
    user_login varchar,
    book_title varchar,
    book_publishing_date date,
    user_review_text text
) TO user_client;
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
--Function for deleting review about book
CREATE OR REPLACE FUNCTION delete_user_review_about_book(
    review_date_ timestamp(0),
    user_login_ varchar,
    review_text_ text
) RETURNS VOID AS
    $$
    DECLARE
        user_id int2;

    BEGIN
          SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login_;
            RAISE NOTICE '% % %',review_date_, user_id, review_text_;

          DELETE FROM client_review
          WHERE
            client_review.review_by = user_id
          AND
            client_review.review_date = review_date_
          AND
            client_review.review_text = review_text_;

    END;

    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION delete_user_review_about_book(
    review_date_ timestamp(0),
    user_login_ varchar,
    review_text_ text
) FROM public;

GRANT EXECUTE ON FUNCTION delete_user_review_about_book(
    review_date_ timestamp(0),
    user_login_ varchar,
    review_text_ text
)
    TO user_client;
-----------------------------------------------------------------------------------------------------

--Get info about user by login
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
-- Add order to client_order table

CREATE OR REPLACE FUNCTION add_order(
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
) RETURNS VOID AS
    $$
        DECLARE
            emp_id integer;
            cli_id integer;
            book_edition_number integer;
            current_order_id integer;

        BEGIN

            SELECT client.client_id INTO cli_id FROM client WHERE client.client_login = cli_login_;

            SELECT edition.edition_number INTO book_edition_number FROM edition, authority, book
            WHERE
                edition.authority_id = authority.authority_id
            AND
                authority.edition_book = book.book_id
            AND
                book.title = book_title_
            AND
                edition.publishing_date = date_of_publishing_;

            SELECT
                employee.employee_id
            INTO
                emp_id
            FROM
                employee, edition, book_shop
            WHERE
                employee.place_of_work = shop_number
            AND
                employee.employee_position = 'shop_assistant';


            RAISE INFO 'emp_id % , cli_id %, edition_num of book %', emp_id, cli_id, book_edition_number;


            INSERT INTO client_order
                (sender,
                 reciever,
                 delivery_address,
                 order_status,
                 sum_to_pay,
                 payment_type,
                 additional_info,
                 date_of_order,
                 quantity ,
                 date_of_return)
            VALUES
                (emp_id,
                 cli_id,
                 delivery_address_,
                 order_status_,
                 sum_to_pay_,
                 payment_type_,
                 additional_info_,
                 ordering_date,
                 quantity_,
                 NULL)
            RETURNING
                order_id INTO current_order_id;

            INSERT INTO chosen
                (edition_number, order_id)
            VALUES
                (book_edition_number, current_order_id);

            END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION add_order(
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
) FROM public;

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
) TO user_client;


-----------------------------------------------------------------------------------------------------

-- Reduce amount of available books when user creating an order
CREATE OR REPLACE FUNCTION reduce_available_books()
RETURNS TRIGGER AS
    $$
    DECLARE
        edition_to_update int2;
        reduce_by int2;

    BEGIN

        SELECT
            edition.edition_number
        INTO
            edition_to_update
        FROM
            edition, client_order
        WHERE
            NEW.order_id = client_order.order_id
        AND
            NEW.edition_number = edition.edition_number;

        SELECT
            client_order.quantity
        INTO
            reduce_by
        FROM
            client_order
        WHERE
            NEW.order_id = client_order.order_id;

        UPDATE
            edition
        SET
            number_of_copies_in_shop = number_of_copies_in_shop - reduce_by
        WHERE
            edition_number = edition_to_update;

        RETURN NEW;
    END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER reduce_available_books_trigger
    AFTER INSERT
    ON chosen
    FOR EACH ROW
    EXECUTE PROCEDURE reduce_available_books();

REVOKE ALL ON FUNCTION reduce_available_books() FROM public;
GRANT EXECUTE ON FUNCTION reduce_available_books() TO user_client;
-----------------------------------------------------------------------------------------------------

--Update client info

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
--Update order status

CREATE OR REPLACE FUNCTION update_user_order(ordering_date timestamp(0), status varchar)
RETURNS VOID AS
    $$
        BEGIN

        IF status = 'Отменён' THEN
            UPDATE client_order
            SET
                order_status = status,
                date_of_return = now()
            WHERE
                date_of_order = ordering_date;
        ELSE
            UPDATE client_order
            SET
                order_status = status
            WHERE
                date_of_order = ordering_date;
        END IF;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
set search_path = public;

-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
--Return books (add client_order.quantity to edition number of books)
CREATE OR REPLACE FUNCTION return_ordered_books()
RETURNS TRIGGER AS

    $$
    DECLARE
        edition_to_return int2;

    BEGIN

        SELECT
            chosen.edition_number INTO edition_to_return FROM edition, chosen
        WHERE
            NEW.order_id = chosen.order_id;

        UPDATE edition
        SET number_of_copies_in_shop = number_of_copies_in_shop + NEW.quantity
        WHERE edition_number = edition_to_return;

        RETURN NEW;
    END

    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER return_ordered_books_trigger
    AFTER UPDATE
    ON client_order
    FOR EACH ROW
    WHEN (NEW.order_status = 'Отменён')
    EXECUTE PROCEDURE return_ordered_books();
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- Function to get orders for specific client
CREATE OR REPLACE FUNCTION get_client_orders(login varchar)
RETURNS TABLE (
    book_title_ varchar,
    quantity_ int,
    sum_to_pay_ numeric(7, 2),
    order_status_ varchar,
    date_of_order_ timestamp(0),
    date_of_return_ timestamp(0)
) AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    title,quantity, sum_to_pay, order_status, date_of_order, date_of_return
                FROM
                    client_order, chosen, client, book, edition, authority
                WHERE
                    client_order.reciever = client.client_id
                AND
                    client.client_login = login
                AND
                    chosen.order_id = client_order.order_id
                AND
                    chosen.edition_number = edition.edition_number
                AND
                    edition.authority_id = authority.authority_id
                AND
                    authority.edition_book = book.book_id;
        END
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;
select * from chosen;

REVOKE ALL ON FUNCTION get_client_orders(client_login varchar) FROM public;
GRANT EXECUTE ON FUNCTION get_client_orders(client_login varchar) TO user_client;
-----------------------------------------------------------------------------------------------------
