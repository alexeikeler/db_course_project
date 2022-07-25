--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Ubuntu 14.2-1.pgdg21.10+1)
-- Dumped by pg_dump version 14.2 (Ubuntu 14.2-1.pgdg21.10+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: add_order(character varying, date, integer, character varying, character varying, character varying, numeric, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
                (sender, reciever, delivery_address, order_status, sum_to_pay, payment_type, additional_info, date_of_order, quantity , date_of_return)
            VALUES
                (emp_id::integer, cli_id::integer, delivery_address_, order_status_, sum_to_pay_, payment_type_, additional_info_, now(), quantity_, NULL)
            RETURNING
                order_id INTO current_order_id;

            INSERT INTO chosen
                (edition_number, order_id)
            VALUES
                (book_edition_number, current_order_id);

            END


    $$;


ALTER FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) OWNER TO postgres;

--
-- Name: add_order(character varying, date, timestamp without time zone, integer, character varying, character varying, character varying, numeric, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
                (sender, reciever, delivery_address, order_status, sum_to_pay, payment_type, additional_info, date_of_order, quantity , date_of_return)
            VALUES
                (emp_id, cli_id, delivery_address_, order_status_, sum_to_pay_, payment_type_, additional_info_, ordering_date, quantity_, NULL)
            RETURNING
                order_id INTO current_order_id;

            INSERT INTO chosen
                (edition_number, order_id)
            VALUES
                (book_edition_number, current_order_id);

            END


    $$;


ALTER FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) OWNER TO postgres;

--
-- Name: add_review(character varying, integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_review(IN r_type character varying, IN id integer, IN r_text character varying, IN r_by integer)
    LANGUAGE plpgsql
    AS $$

    BEGIN
        CASE
         WHEN r_type = 'edition_review'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, id, null,null, r_text);
                RAISE INFO 'INSERTION AT CLIENT_REVIEW: SUCCESS';

        WHEN r_type = 'shop_review'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, null, id, null, r_text);
                RAISE INFO 'INSERTION AT CLIENT_REVIEW: SUCCESS';

        WHEN r_type = 'employee'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, null, null, id, r_text);
                RAISE INFO 'INSERTION AT CLIENT_REVIEW: SUCCESS';

        END CASE;

    END;

    $$;


ALTER PROCEDURE public.add_review(IN r_type character varying, IN id integer, IN r_text character varying, IN r_by integer) OWNER TO postgres;

--
-- Name: add_review(character varying, integer, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_review(IN r_type character varying, IN id integer, IN r_text character varying, IN r_by character varying)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        CASE
         WHEN r_type = 'edition_review'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, id, null,null, r_text);

        WHEN r_type = 'shop_review'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, null, id, null, r_text);

        WHEN r_type = 'employee'
                THEN INSERT INTO client_review(review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (current_date, r_by, null, null, id, r_text);

        END CASE;

    END; $$;


ALTER PROCEDURE public.add_review(IN r_type character varying, IN id integer, IN r_text character varying, IN r_by character varying) OWNER TO postgres;

--
-- Name: add_review(character varying, character varying, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_review(user_login character varying, book_title character varying, book_publ_date date, user_review_text text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    declare
        user_id int2;
        book_id int2;
     BEGIN
        select client.client_id into user_id from client where client.client_login = user_login;

       select
           edition.authority_id into book_id from edition, authority, book
       where
           edition.authority_id = authority.authority_id
       and
           authority.edition_book = book.book_id
       and
           book.title = book_title
       and
           publishing_date = book_publ_date;
        RAISE NOTICE 'user_id: %, book_id: %', user_id, book_id;
    end;
    $$;


ALTER FUNCTION public.add_review(user_login character varying, book_title character varying, book_publ_date date, user_review_text text) OWNER TO postgres;

--
-- Name: add_review(integer, character varying, integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_review(IN r_id integer, IN r_type character varying, IN id integer, IN r_text character varying, IN r_by integer)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        CASE
         WHEN r_type = 'book_review'
            THEN IF id IN(SELECT book_id from book)
                    THEN INSERT INTO client_review(review_id, review_date, review_by,
                                      review_about_book, review_about_shop, review_about_employee,
                                      review_text) VALUES (r_id, current_date, r_by, id, null,null, r_text);
                    RAISE INFO 'INSERTION AT CLIENT_REVIEW ABOUT BOOK: SUCCESS';
                ELSE
                    RAISE EXCEPTION 'INSERTION AT CLIENT_REVIEW ABOUT BOOK: FAIL - WRONG ID';

                END IF;

        WHEN r_type = 'shop_review'
                THEN IF id IN (SELECT shop_id from book_shop)
                    THEN INSERT INTO client_review(review_id, review_date, review_by,
                                  review_about_book, review_about_shop, review_about_employee,
                                  review_text) VALUES (r_id, current_date, r_by, null, id, null, r_text);
                    RAISE INFO 'INSERTION AT CLIENT_REVIEW ABOUT SHOP: SUCCESS';
                    ELSE
                         RAISE EXCEPTION 'INSERTION AT CLIENT_REVIEW ABOUT SHOP: FAIL - WRONG ID';
                    END IF;

        WHEN r_type = 'employee_review'
            THEN IF id IN (SELECT employee_id from employee)
                    THEN INSERT INTO client_review(review_id, review_date, review_by,
                                      review_about_book, review_about_shop, review_about_employee,
                                      review_text) VALUES (r_id, current_date, r_by, null, null, id, r_text);
                    RAISE INFO 'INSERTION AT CLIENT_REVIEW ABOUT EMPLOYEE: SUCCESS';
                ELSE
                     RAISE EXCEPTION 'INSERTION AT CLIENT_REVIEW ABOUT EMPLOYEE: FAIL - WRONG ID';
                END IF;

        END CASE;
    END;
    $$;


ALTER PROCEDURE public.add_review(IN r_id integer, IN r_type character varying, IN id integer, IN r_text character varying, IN r_by integer) OWNER TO postgres;

--
-- Name: available_books_main_info(character varying, character varying, character varying, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric) RETURNS TABLE(author_info character varying, title_info character varying, genre_info character varying, date_of_publishing date, price_info numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

$$;


ALTER FUNCTION public.available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric) OWNER TO postgres;

--
-- Name: change_client_password(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_client_password(login character varying, new_password character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
        UPDATE client
        SET
            client_password = new_password
        WHERE
            client_login = login;
    END;
    $$;


ALTER FUNCTION public.change_client_password(login character varying, new_password character varying) OWNER TO postgres;

--
-- Name: change_client_password(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_client_password(login character varying, old_password character varying, new_password character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$

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
    $$;


ALTER FUNCTION public.change_client_password(login character varying, old_password character varying, new_password character varying) OWNER TO postgres;

--
-- Name: concrete_book_full_info(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) RETURNS TABLE(author_ character varying, title_ character varying, genre_ character varying, available_amount_ smallint, shop_ integer, binding_type_ character varying, number_of_pages_ smallint, publishing_date_ date, publishing_agency_ character varying, price_ numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

$$;


ALTER FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) OWNER TO postgres;

--
-- Name: create_client(character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) RETURNS TABLE(created boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) OWNER TO postgres;

--
-- Name: delete_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.delete_user() OWNER TO postgres;

--
-- Name: delete_user(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_user(login character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
        DELETE FROM client WHERE client.client_login = login;
        DELETE FROM users WHERE users.user_login = login;
    END;
$$;


ALTER FUNCTION public.delete_user(login character varying) OWNER TO postgres;

--
-- Name: delete_user_review_about_book(timestamp without time zone, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_user_review_about_book(review_date_ timestamp without time zone, user_login_ character varying, review_text_ text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

    $$;


ALTER FUNCTION public.delete_user_review_about_book(review_date_ timestamp without time zone, user_login_ character varying, review_text_ text) OWNER TO postgres;

--
-- Name: get_book_reviews(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) RETURNS TABLE(review_by_ character varying, review_date_ timestamp without time zone, review_ text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

$$;


ALTER FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) OWNER TO postgres;

--
-- Name: get_client_info(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_client_info(client_login_ character varying) RETURNS TABLE(user_login character varying, user_first_name character varying, user_last_name character varying, user_phone_number character varying, user_email character varying, user_delivery_address character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
       RETURN QUERY


       SELECT client_login, client_firstname, client_lastname, phone_number, email, delivery_address
        from client
        where client.client_login = client_login_;
    END
    $$;


ALTER FUNCTION public.get_client_info(client_login_ character varying) OWNER TO postgres;

--
-- Name: get_min_max_book_prices(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_min_max_book_prices() RETURNS TABLE(min_price numeric, max_price numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
    RETURN QUERY
        SELECT MIN(price), MAX(price)
            FROM
                available_books_view;

    END;
$$;


ALTER FUNCTION public.get_min_max_book_prices() OWNER TO postgres;

--
-- Name: get_reviews_about_book(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reviews_about_book(book_title text) RETURNS TABLE(review_by character varying, review_about character varying, review_date timestamp without time zone, review text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT *
            FROM
                ClientBookReviews
            WHERE
                ClientBookReviews.review_about = book_title;
        END;

$$;


ALTER FUNCTION public.get_reviews_about_book(book_title text) OWNER TO postgres;

--
-- Name: hash_password(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hash_password() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.hash_password() OWNER TO postgres;

--
-- Name: insert_user_book_review(character varying, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, user_review_text text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        user_id int2;
        book_id int2;
    BEGIN
        select client.client_id into user_id from client where client.client_login = user_login;
        select book.book_id into book_id from book where book.title = book_title;

        INSERT INTO client_review (review_date, review_by, review_about_book, review_text)
        VALUES (now()::timestamp(0), user_id, book_id, user_review_text);
    END;
$$;


ALTER FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, user_review_text text) OWNER TO postgres;

--
-- Name: insert_user_book_review(character varying, character varying, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) OWNER TO postgres;

--
-- Name: make_discount(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.make_discount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        total_bought_over_year integer = 0;
    BEGIN
        total_bought_over_year = (SELECT count(order_id)
                                  FROM client_order
                                  WHERE EXTRACT('year' from client_order.date_order) = EXTRACT('year' from current_date)
                                  AND client_order.reciever = NEW.reciever
                                  group by reciever);

        RAISE NOTICE 'total_bought_over_year: % from cli %', total_bought_over_year, NEW.reciever;

        IF total_bought_over_year > 1
            THEN UPDATE client_order
                SET sum_to_pay = sum_to_pay * 0.92
                WHERE order_id = NEW.order_id;

            RAISE NOTICE 'PRICE WITH DISCOUNT';
            RETURN NEW;

        ELSE
            RAISE NOTICE 'USUAL PRICE';
            RETURN NEW;
        END IF;
    END;
    $$;


ALTER FUNCTION public.make_discount() OWNER TO postgres;

--
-- Name: quantity_of_books_checker(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.quantity_of_books_checker() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        available integer;

    BEGIN
    SELECT edition.number_of_copies_in_shop
        INTO available
        FROM edition
        WHERE edition.edition_number = NEW.edition;

        IF NEW.quantity > available
            THEN RAISE EXCEPTION 'BIG_AMOUNT_ERROR';
            RETURN NULL;

        ELSE
            UPDATE edition
                SET number_of_copies_in_shop = number_of_copies_in_shop - NEW.quantity
            WHERE edition.edition_number = NEW.edition;
            RETURN NEW;

            END IF;
    END;
    $$;


ALTER FUNCTION public.quantity_of_books_checker() OWNER TO postgres;

--
-- Name: reduce_available_books(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reduce_available_books() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

        RAISE INFO 'order_id : %, edition_to_update : %', NEW.order_id, edition_to_update;

        UPDATE edition
        SET number_of_copies_in_shop = number_of_copies_in_shop - reduce_by
        WHERE
            edition_number = edition_to_update;

        RETURN NEW;
    END
    $$;


ALTER FUNCTION public.reduce_available_books() OWNER TO postgres;

--
-- Name: update_client_info(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_client_info(login character varying, subject character varying, new_value character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

            WHEN 'devilery_address'
                THEN
                    UPDATE client
                    SET delivery_address = new_value
                    WHERE client_login = login;
                    RETURN TRUE;
           ELSE
                RAISE INFO 'Eror in function update_client_info.';
                RETURN FALSE;
    END CASE;
    END
    $$;


ALTER FUNCTION public.update_client_info(login character varying, subject character varying, new_value character varying) OWNER TO postgres;

--
-- Name: update_users_table(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_users_table() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.update_users_table() OWNER TO postgres;

--
-- Name: verify_user(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_user(login character varying, password character varying) RETURNS TABLE(user_role character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            users.user_role
        FROM
            users
        WHERE
            users.user_login = login
        AND
            users.user_password = encode(digest(password, 'sha256'), 'hex');
    END;
$$;


ALTER FUNCTION public.verify_user(login character varying, password character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: author; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.author (
    author_id integer NOT NULL,
    lastname character varying(64) NOT NULL,
    firstname character varying(64) NOT NULL,
    date_of_birth date NOT NULL,
    date_of_death date,
    CONSTRAINT author_check CHECK ((date_of_birth < date_of_death)),
    CONSTRAINT author_date_of_birth_check CHECK ((date_of_birth < CURRENT_DATE)),
    CONSTRAINT author_firstname_check CHECK ((length((firstname)::text) > 0)),
    CONSTRAINT author_lastname_check CHECK ((length((lastname)::text) > 0))
);


ALTER TABLE public.author OWNER TO postgres;

--
-- Name: author_author_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.author_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.author_author_id_seq OWNER TO postgres;

--
-- Name: author_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.author_author_id_seq OWNED BY public.author.author_id;


--
-- Name: authority; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authority (
    authority_id integer NOT NULL,
    edition_author integer NOT NULL,
    edition_book integer NOT NULL
);


ALTER TABLE public.authority OWNER TO postgres;

--
-- Name: authority_authority_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.authority_authority_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authority_authority_id_seq OWNER TO postgres;

--
-- Name: authority_authority_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.authority_authority_id_seq OWNED BY public.authority.authority_id;


--
-- Name: book; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book (
    book_id integer NOT NULL,
    title character varying(128) NOT NULL,
    genre_type character varying(20) NOT NULL,
    CONSTRAINT book_genre_type_check CHECK (((genre_type)::text = ANY (ARRAY[('Детектив'::character varying)::text, ('Роман'::character varying)::text, ('Фантастика'::character varying)::text, ('Фэнтези'::character varying)::text, ('Психология'::character varying)::text, ('Философия'::character varying)::text, ('Программирование'::character varying)::text, ('Триллер'::character varying)::text, ('Научная литература'::character varying)::text, ('Мемуары'::character varying)::text, ('ПрозаПоэзия'::character varying)::text]))),
    CONSTRAINT book_title_check CHECK ((length((title)::text) > 0))
);


ALTER TABLE public.book OWNER TO postgres;

--
-- Name: edition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.edition (
    edition_number integer NOT NULL,
    authority_id integer NOT NULL,
    publishing_agency_id integer NOT NULL,
    concrete_shop integer NOT NULL,
    price numeric(7,2) NOT NULL,
    publishing_date date NOT NULL,
    number_of_copies_in_shop smallint NOT NULL,
    number_of_pages smallint NOT NULL,
    binding_type character varying(7) NOT NULL,
    paper_quality character varying(19) NOT NULL,
    CONSTRAINT edition_binding_type_check CHECK (((binding_type)::text = ANY (ARRAY[('Твёрдый'::character varying)::text, ('Мягкий'::character varying)::text]))),
    CONSTRAINT edition_number_of_copies_in_shop_check CHECK ((number_of_copies_in_shop > 0)),
    CONSTRAINT edition_number_of_pages_check CHECK ((number_of_pages > 0)),
    CONSTRAINT edition_paper_quality_check CHECK (((paper_quality)::text = ANY (ARRAY[('Для глубокой печати'::character varying)::text, ('Типографическая'::character varying)::text, ('Офсетная'::character varying)::text]))),
    CONSTRAINT edition_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT edition_publishing_date_check CHECK ((publishing_date < CURRENT_DATE))
);


ALTER TABLE public.edition OWNER TO postgres;

--
-- Name: publishing_agency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publishing_agency (
    publishing_agency_id integer NOT NULL,
    publishing_agency_name character varying(128) NOT NULL,
    phone_number character varying(16) NOT NULL,
    email character varying(64) NOT NULL,
    CONSTRAINT publishing_agency_email_check CHECK (((email)::text ~ similar_to_escape('[A-Za-z0-9._%+-]+@[A-Za-z0-9]+\.[A-Za-z]{2,4}'::text))),
    CONSTRAINT publishing_agency_phone_number_check CHECK (((phone_number)::text ~ similar_to_escape('\+?3?8?(0\d{9})'::text))),
    CONSTRAINT publishing_agency_publishing_agency_name_check CHECK ((length((publishing_agency_name)::text) > 0))
);


ALTER TABLE public.publishing_agency OWNER TO postgres;

--
-- Name: available_books_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.available_books_view AS
 SELECT ((((author.firstname)::text || ' '::text) || (author.lastname)::text))::character varying AS author,
    book.title,
    book.genre_type AS genre,
    edition.price,
    edition.number_of_copies_in_shop AS available_amount,
    edition.concrete_shop AS shop,
    edition.binding_type,
    edition.number_of_pages,
    edition.publishing_date,
    publishing_agency.publishing_agency_name AS publising_agency_name
   FROM public.edition,
    public.authority,
    public.book,
    public.author,
    public.publishing_agency
  WHERE ((edition.authority_id = authority.authority_id) AND (authority.edition_author = author.author_id) AND (authority.edition_book = book.book_id) AND (edition.publishing_agency_id = publishing_agency.publishing_agency_id));


ALTER TABLE public.available_books_view OWNER TO postgres;

--
-- Name: book_book_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.book_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.book_book_id_seq OWNER TO postgres;

--
-- Name: book_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.book_book_id_seq OWNED BY public.book.book_id;


--
-- Name: book_edition_number; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_edition_number (
    edition_number integer
);


ALTER TABLE public.book_edition_number OWNER TO postgres;

--
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    client_id integer NOT NULL,
    client_firstname character varying(64) NOT NULL,
    client_lastname character varying(64) NOT NULL,
    phone_number character varying(16) NOT NULL,
    email character varying(64) NOT NULL,
    client_login character varying(64) NOT NULL,
    client_password character varying(64) NOT NULL,
    delivery_address character varying(128),
    CONSTRAINT client_client_firstname_check CHECK ((length((client_firstname)::text) > 0)),
    CONSTRAINT client_client_lastname_check CHECK ((length((client_lastname)::text) > 0)),
    CONSTRAINT client_client_login_check CHECK ((length((client_login)::text) > 0)),
    CONSTRAINT client_client_password_check CHECK ((length((client_password)::text) > 8)),
    CONSTRAINT client_email_check CHECK (((email)::text ~ similar_to_escape('[A-Za-z0-9._%+-]+@[A-Za-z0-9]+\.[A-Za-z]{2,4}'::text))),
    CONSTRAINT client_phone_number_check CHECK (((phone_number)::text ~ similar_to_escape('\+?3?8?(0\d{9})'::text)))
);


ALTER TABLE public.client OWNER TO postgres;

--
-- Name: client_review; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_review (
    review_id integer NOT NULL,
    review_date timestamp(0) without time zone NOT NULL,
    review_by integer NOT NULL,
    review_about_book integer,
    review_about_shop integer,
    review_about_employee integer,
    review_text text NOT NULL,
    CONSTRAINT client_review_review_date_check CHECK ((review_date > '2021-01-01'::date)),
    CONSTRAINT client_review_review_text_check CHECK ((length(review_text) > 0))
);


ALTER TABLE public.client_review OWNER TO postgres;

--
-- Name: book_reviews; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.book_reviews AS
 SELECT client.client_login AS user_login,
    book.title AS review_about_book,
    edition.publishing_date AS book_pubslishing_date,
    client_review.review_date,
    client_review.review_text AS review
   FROM public.client_review,
    public.client,
    public.edition,
    public.authority,
    public.book
  WHERE ((client_review.review_about_book IS NOT NULL) AND (client_review.review_about_book = edition.authority_id) AND (client.client_id = client_review.review_by) AND (edition.authority_id = authority.authority_id) AND (authority.edition_book = book.book_id));


ALTER TABLE public.book_reviews OWNER TO postgres;

--
-- Name: book_shop; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_shop (
    shop_id integer NOT NULL,
    name_of_shop character varying(64) NOT NULL,
    number_of_employees smallint NOT NULL,
    post_code character varying(32) NOT NULL,
    country character varying(64) NOT NULL,
    city character varying(64) NOT NULL,
    street character varying(128) NOT NULL,
    manager integer NOT NULL,
    CONSTRAINT book_shop_city_check CHECK ((length((city)::text) > 0)),
    CONSTRAINT book_shop_country_check CHECK ((length((country)::text) > 0)),
    CONSTRAINT book_shop_number_of_employees_check CHECK ((number_of_employees >= 0)),
    CONSTRAINT book_shop_post_code_check CHECK ((length((post_code)::text) > 0)),
    CONSTRAINT book_shop_street_check CHECK ((length((street)::text) > 0))
);


ALTER TABLE public.book_shop OWNER TO postgres;

--
-- Name: book_shop_shop_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.book_shop_shop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.book_shop_shop_id_seq OWNER TO postgres;

--
-- Name: book_shop_shop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.book_shop_shop_id_seq OWNED BY public.book_shop.shop_id;


--
-- Name: chosen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chosen (
    chosen_id integer NOT NULL,
    edition_number integer NOT NULL,
    order_id integer NOT NULL
);


ALTER TABLE public.chosen OWNER TO postgres;

--
-- Name: chosen_chosen_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chosen_chosen_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chosen_chosen_id_seq OWNER TO postgres;

--
-- Name: chosen_chosen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chosen_chosen_id_seq OWNED BY public.chosen.chosen_id;


--
-- Name: client_client_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_client_id_seq OWNER TO postgres;

--
-- Name: client_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_client_id_seq OWNED BY public.client.client_id;


--
-- Name: client_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_order (
    order_id integer NOT NULL,
    sender integer NOT NULL,
    reciever integer NOT NULL,
    delivery_address character varying(128),
    order_status character varying(128) NOT NULL,
    sum_to_pay numeric(6,2) NOT NULL,
    payment_type character varying(8) NOT NULL,
    quantity integer NOT NULL,
    date_of_return timestamp(0) without time zone,
    additional_info character varying(1024),
    date_of_order timestamp(0) without time zone NOT NULL,
    CONSTRAINT client_order_additional_info_check CHECK ((length((additional_info)::text) > 0)),
    CONSTRAINT client_order_delivery_address_check CHECK ((length((delivery_address)::text) > 0)),
    CONSTRAINT client_order_order_status_check CHECK (((order_status)::text = ANY ((ARRAY['В корзине'::character varying, 'Отменён'::character varying, 'Оплачен'::character varying, 'В работе'::character varying, 'Обработан'::character varying])::text[]))),
    CONSTRAINT client_order_payment_type_check CHECK (((payment_type)::text = ANY ((ARRAY['Наличные'::character varying, 'Карта'::character varying])::text[]))),
    CONSTRAINT client_order_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT client_order_sum_to_pay_check CHECK ((sum_to_pay > (0)::numeric))
);


ALTER TABLE public.client_order OWNER TO postgres;

--
-- Name: client_order_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_order_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_order_order_id_seq OWNER TO postgres;

--
-- Name: client_order_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_order_order_id_seq OWNED BY public.client_order.order_id;


--
-- Name: client_review_review_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_review_review_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_review_review_id_seq OWNER TO postgres;

--
-- Name: client_review_review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_review_review_id_seq OWNED BY public.client_review.review_id;


--
-- Name: concrete_client; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.concrete_client AS
 SELECT client.client_id,
    client.client_firstname,
    client.client_lastname,
    client.phone_number,
    client.email,
    client.client_login,
    client.client_password,
    client.delivery_address
   FROM public.client
  WHERE ((client.client_login)::text = 'test_login'::text);


ALTER TABLE public.concrete_client OWNER TO postgres;

--
-- Name: edition_edition_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.edition_edition_number_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.edition_edition_number_seq OWNER TO postgres;

--
-- Name: edition_edition_number_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.edition_edition_number_seq OWNED BY public.edition.edition_number;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    employee_id integer NOT NULL,
    lastname character varying(64) NOT NULL,
    firstname character varying(64) NOT NULL,
    employee_position character varying(32) NOT NULL,
    salary numeric(7,2) NOT NULL,
    phone_number character varying(16) NOT NULL,
    email character varying(64) NOT NULL,
    employee_login character varying(64) NOT NULL,
    employee_password character varying(64) NOT NULL,
    place_of_work integer NOT NULL,
    CONSTRAINT employee_email_check CHECK (((email)::text ~ similar_to_escape('[A-Za-z0-9._%+-]+@[A-Za-z0-9]+\.[A-Za-z]{2,4}'::text))),
    CONSTRAINT employee_employee_login_check CHECK ((length((employee_login)::text) > 0)),
    CONSTRAINT employee_employee_password_check CHECK ((length((employee_password)::text) > 8)),
    CONSTRAINT employee_employee_position_check CHECK (((employee_position)::text = ANY ((ARRAY['director'::character varying, 'admin'::character varying, 'manager'::character varying, 'cashier'::character varying, 'shop_assistant'::character varying])::text[]))),
    CONSTRAINT employee_firstname_check CHECK ((length((firstname)::text) > 0)),
    CONSTRAINT employee_lastname_check CHECK ((length((lastname)::text) > 0)),
    CONSTRAINT employee_phone_number_check CHECK (((phone_number)::text ~ similar_to_escape('\+?3?8?(0\d{9})'::text))),
    CONSTRAINT employee_salary_check CHECK ((salary > (0)::numeric))
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_employee_id_seq OWNER TO postgres;

--
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_employee_id_seq OWNED BY public.employee.employee_id;


--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publishing_agency_publishing_agency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publishing_agency_publishing_agency_id_seq OWNER TO postgres;

--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publishing_agency_publishing_agency_id_seq OWNED BY public.publishing_agency.publishing_agency_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    user_login character varying(64) NOT NULL,
    user_role character varying(32) NOT NULL,
    user_password character varying(64) NOT NULL,
    CONSTRAINT users_user_login_check CHECK ((length((user_login)::text) > 0)),
    CONSTRAINT users_user_password_check CHECK ((length((user_password)::text) > 0)),
    CONSTRAINT users_user_role_check CHECK ((length((user_role)::text) > 0))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: author author_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author ALTER COLUMN author_id SET DEFAULT nextval('public.author_author_id_seq'::regclass);


--
-- Name: authority authority_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authority ALTER COLUMN authority_id SET DEFAULT nextval('public.authority_authority_id_seq'::regclass);


--
-- Name: book book_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book ALTER COLUMN book_id SET DEFAULT nextval('public.book_book_id_seq'::regclass);


--
-- Name: book_shop shop_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_shop ALTER COLUMN shop_id SET DEFAULT nextval('public.book_shop_shop_id_seq'::regclass);


--
-- Name: chosen chosen_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chosen ALTER COLUMN chosen_id SET DEFAULT nextval('public.chosen_chosen_id_seq'::regclass);


--
-- Name: client client_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client ALTER COLUMN client_id SET DEFAULT nextval('public.client_client_id_seq'::regclass);


--
-- Name: client_order order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_order ALTER COLUMN order_id SET DEFAULT nextval('public.client_order_order_id_seq'::regclass);


--
-- Name: client_review review_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review ALTER COLUMN review_id SET DEFAULT nextval('public.client_review_review_id_seq'::regclass);


--
-- Name: edition edition_number; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition ALTER COLUMN edition_number SET DEFAULT nextval('public.edition_edition_number_seq'::regclass);


--
-- Name: employee employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN employee_id SET DEFAULT nextval('public.employee_employee_id_seq'::regclass);


--
-- Name: publishing_agency publishing_agency_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency ALTER COLUMN publishing_agency_id SET DEFAULT nextval('public.publishing_agency_publishing_agency_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: author; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.author (author_id, lastname, firstname, date_of_birth, date_of_death) FROM stdin;
1	Томас	Харрис	1940-04-11	\N
2	Гёте	Иоганн Вольфганг фон	1749-08-28	1832-03-28
3	Оруэлл	Джордж	1903-06-25	1950-01-21
4	Рэй	Бредбери	1920-08-22	2012-06-05
5	Бардуго	Ли	1975-04-06	\N
6	Саповский	Анджей	1948-06-21	\N
7	Кормен	Томас	1956-05-02	\N
8	Лейзерсон	Чарльз Эрик	1953-11-10	\N
9	Рвест	Рональд Линн\t	1947-05-06	\N
10	Штайн	Клиффорд	1965-12-05	\N
11	Фихтенгольц	Григорий	1888-06-05	1959-05-26
12	Ницше	Фридрих	1844-10-15	1900-08-25
13	Хаустов	Дмитрий	1988-05-28	\N
14	Дуглас	Джон	1945-06-18	\N
15	Олшейкер	Марк	1951-02-28	\N
16	Макконахи	Мэттью	1969-11-04	\N
17	Фейнман	Ричард	1918-05-11	1988-02-15
18	Стивенс	Род	1961-08-20	\N
19	Диевский	Виктор	1949-04-28	\N
20	Феррейра	Владстон	1990-05-23	\N
21	Апполонский	Сергей	1981-03-13	\N
\.


--
-- Data for Name: authority; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authority (authority_id, edition_author, edition_book) FROM stdin;
1	1	19
2	1	20
3	1	21
4	2	22
5	12	39
6	13	38
7	11	32
8	11	33
9	16	35
10	3	24
12	12	40
13	12	41
14	12	42
15	18	43
16	19	44
17	20	45
18	21	46
\.


--
-- Data for Name: book; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book (book_id, title, genre_type) FROM stdin;
19	Красный дракон	Детектив
20	Молчание ягнят	Детектив
21	Ганнибал	Детектив
22	Страдания юного Вертера	Роман
23	Мастер и Маргарита	Роман
24	1984	Фантастика
25	451 градус по Фаренгейту	Фантастика
26	Тень и кость	Фэнтези
27	Последнее желание	Фэнтези
28	Алгоритмы: построение и анализ	Программирование
29	Глубокое обучение в биологии и медицине	Программирование
30	Внутри убийцы	Триллер
31	Заживо в темноте	Триллер
32	Основы математического анализа	Научная литература
33	Курс дифференциального и интегрального исчесления	Научная литература
34	Вы, конечно, шутите, мистер Фейнман!	Мемуары
35	Зелёный свет	Мемуары
36	Охотник за разумом	Психология
37	Психологические типы	Психология
38	Лекции по философии постмодерна	Философия
39	Антихрист	Философия
40	Так говорил Заратустра	Философия
41	По ту сторону добра и зла	Философия
42	Генеалогия морали	Философия
43	Алгоритмы. Теория и практическое применение	Программирование
44	Теоретическая механика	Научная литература
45	Теоретический минимум по Computer Science.	Программирование
46	Теоретические основы электротехники	Научная литература
\.


--
-- Data for Name: book_edition_number; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_edition_number (edition_number) FROM stdin;
9
\.


--
-- Data for Name: book_shop; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_shop (shop_id, name_of_shop, number_of_employees, post_code, country, city, street, manager) FROM stdin;
1	BigBook shop # 1	5	79007	Украина	Львов	ул. Андрея Головко, 1	1
2	BigBook shop # 2	4	65125	Украина	Одесса	ул. Мельницкая, 13	2
3	BigBook shop # 3	4	65125	Украина	Одесса	ул. Довженко, 3	3
4	BigBook shop # 4	4	4050	Украина	Киев	ул. Крещатик	4
5	BigBook shop # 5	4	4050	Украина	Киев	ул. Владимирская	5
\.


--
-- Data for Name: chosen; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chosen (chosen_id, edition_number, order_id) FROM stdin;
11	19	17
12	10	18
13	20	19
14	15	20
15	19	21
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (client_id, client_firstname, client_lastname, phone_number, email, client_login, client_password, delivery_address) FROM stdin;
40	Волощук	Епифан	+380876678123	epifanvol@gmail.com	EpifanVoloshtuk520	9a50447e3c467cd1184e6284ffa94f91384085eab2ac59b77fe3b2ab1fc486b1	123007 г. Ярославское, ул. Полевая Нижняя, дом 38, квартира 597
35	Андрей	Семёнов	+380976567877	semenovAndrei@gmail.com	SemenovAndrei1982	2dd1c28e5a791fb79326ecf45ef6a9393746d76d9faffbc80153b128acd0e4af	618155, г. Железнодорожный, ул. Нансена проезд, дом 18, квартира 606
36	Островская	Виктория	+380786678543	ostrovskaya189@gmail.com	OstrovskayaVictorija	9d0ea08959e1c4fd5ce6531d768379bc102db383c87316ca7b1f73abfdf70239	446677, г. Гаврилов-ям, ул. Воронцовский пер, дом 97, квартира 617
38	Рубенцова	Лариса	+380786555543	rubenstova@gmail.com	LarisaRubentsova882	7d05e098c33ba199f900255245f7870deed7d1a71eb873b481df1db581403e67	216472, г. Усть-Ишим, ул. Инская, дом 176, квартира 242
39	Канаева	Тамара	+380255678564	tamara_kanvaeva@gmail.com	TamaraKanaeva605	08f0b2715717abe979c7d54409a285636ac8c493cfdda4ec330b309ae5133bd8	161450, г. Долгоруково, ул. Крутицкий Вал, дом 181, квартира 540
95	test_first_name	test_lastname_modif	+380999999999	asd@gmail.com	test_login	10a6e6cc8311a3e2bcc09bf6c199adecd5dd59408c343e926b129c4914f3cb01	test_address
\.


--
-- Data for Name: client_order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_order (order_id, sender, reciever, delivery_address, order_status, sum_to_pay, payment_type, quantity, date_of_return, additional_info, date_of_order) FROM stdin;
17	11	95	test_address	В корзине	6250.00	Наличные	5	\N	Test info!	2022-07-13 00:00:00
18	15	95	-	В корзине	450.00	Наличные	1	\N	-	2022-07-13 22:57:43
19	19	95	-	В корзине	570.00	Наличные	1	\N	-	2022-07-13 23:41:16
20	11	95	-	В корзине	450.00	Наличные	1	\N	-	2022-07-13 23:41:58
21	11	95	-	В корзине	1250.00	Наличные	1	\N	-	2022-07-13 23:44:51
\.


--
-- Data for Name: client_review; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_review (review_id, review_date, review_by, review_about_book, review_about_shop, review_about_employee, review_text) FROM stdin;
4	2021-03-17 00:00:00	12	\N	\N	4	Спасибо консультанту за помощь в выборе правильного издания.
9	2021-12-01 00:00:00	9	\N	\N	11	Спасибо данному консультанту, помог найти искомое издание.
7	2021-12-02 00:00:00	35	\N	1	\N	Всегда привозят товар вовремя и хорошем состоянии. Рекомендую данный магазин.
12	2021-12-07 00:00:00	36	\N	3	\N	Отличный книжный магазин.
13	2021-12-11 00:00:00	36	\N	\N	21	Спасибо менеджеру за помощь с возвратом книги.
11	2022-06-25 23:01:20	38	\N	\N	27	Благодаря данному консультанту нашёл книгу которую не мог найти долгое время!
15	2022-06-25 23:01:20	38	\N	2	\N	Лучшее книжное заведение в Одессе.
2	2021-07-19 00:00:00	10	15	\N	\N	Фундаментальная работа по алгоритмам и структурам данных. Рекомендую всем!
5	2021-11-12 00:00:00	13	16	\N	\N	Отличный выбор для тех, кто хочет начать изучение данной темы.
1	2021-05-18 00:00:00	9	1	\N	\N	Отличный триллер.
56	2022-07-05 23:49:07	95	3	\N	\N	test!!!
8	2021-12-03 00:00:00	9	18	\N	\N	Автору удалось изложить сложный материал простым языком, понятным даже тем, кто не знаком с темой.
14	2021-12-11 00:00:00	9	14	\N	\N	Интересный взгляд на историю морали.
10	2022-06-25 23:01:20	38	3	\N	\N	Достойное продолжение истории о докторе Ганнибале Лекторе.
57	2022-07-10 13:26:24	95	\N	\N	\N	kkk
58	2022-07-10 13:27:17	95	\N	\N	\N	!@#
59	2022-07-10 13:27:50	95	3	\N	\N	!@#
60	2022-07-12 12:08:15	95	4	\N	\N	!@#
\.


--
-- Data for Name: edition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.edition (edition_number, authority_id, publishing_agency_id, concrete_shop, price, publishing_date, number_of_copies_in_shop, number_of_pages, binding_type, paper_quality) FROM stdin;
7	1	1	1	500.00	2017-11-03	200	431	Твёрдый	Офсетная
8	2	3	2	375.00	2018-06-03	300	514	Мягкий	Офсетная
16	14	3	1	150.00	2018-12-22	100	145	Твёрдый	Типографическая
14	12	2	1	750.00	2013-02-13	50	331	Твёрдый	Офсетная
17	15	2	2	700.00	2011-01-12	20	600	Твёрдый	Для глубокой печати
11	5	2	2	150.00	2019-10-14	45	137	Твёрдый	Для глубокой печати
18	16	3	1	650.00	2009-07-23	21	550	Мягкий	Типографическая
9	3	4	3	650.00	2019-12-02	140	621	Твёрдый	Офсетная
10	4	5	2	450.00	2019-03-23	29	289	Мягкий	Типографическая
20	18	1	3	570.00	2008-03-03	34	850	Твёрдый	Офсетная
15	13	3	1	450.00	2015-06-23	249	255	Мягкий	Типографическая
19	17	2	1	1250.00	2015-02-10	144	350	Мягкий	Для глубокой печати
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (employee_id, lastname, firstname, employee_position, salary, phone_number, email, employee_login, employee_password, place_of_work) FROM stdin;
8	Семёнов	Александр	director	20000.00	+380564765145	semenovaleksandr@gmail.com	semenov_alksndr	204b08cc9af8c34607ce420b04dbe1ab9319832d07a47d2b33870a6d7dddbbc5	1
9	Екатерина	Макарчук	manager	15000.00	+380987767543	makarchk_ektr@gmail.com	ekaterina_makarchuck	28698e64d6887829d90cf74036840f1b51fa65bea6a211c0861425e612406f2a	1
13	Кожина	Эвелина	manager	15000.00	+380568885145	evakoj@gmail.com	evelinaKOJINA	4612feee9fa6bd671957fc1ac908aa985cdaa9aab9a04b9dc36731aa9a368b31	2
17	Егоров	Арнольд	manager	15000.00	+380978872111	ArnoldEgorov@gmail.com	arnoldEgorov	dd38c7b5f5ac35e960a533d673874649ee3c2cd1d8f8eb2e4c2f9bfe9b498c71	3
21	Островская	Лилиана	manager	15000.00	+380977681543	ostrovskaja_lili@gmail.com	lilianaOst	e7e0a11d19bf9bb82ad4af4c6bb4106d74c268959d1bef2a617f1fed64f90679	4
25	Исаев	Никита	manager	15000.00	+380975587145	Issaev234@gmail.com	IsaevNikita	60656c0b5388c93ecb4cbb2b3f0a5ce3dc7db550a656cf81eaa56be7dba28204	5
10	Макаров	Даниил	admin	13500.00	+380345543123	makarov1984@gmail.com	makarov_daniiL	f1d80f8c48bd52c0b87e3a8055ad742259e4b72cf1883a4f9ec7287bdffa3c4c	1
14	Кружина	Элеонора	admin	13500.00	+380568761239	krujinaeleonora@gmail.com	eleonora_kruj	fdf75ec0f9666081318e5797bd1b462392fdc7b825d2164fa5a849ef7c6faade	2
18	Рыбакова	Мария	admin	13500.00	+380976761559	ribakovaMarija@gmail.com	ribakova_marija	21564debedb21a27333c6953e948d4f8162f0b3a6820b0f78ff21d715c0ee128	3
22	Питерский	Ратмир	admin	13500.00	+380975543234	RatmirPiter@gmail.com	ratmir_piterskij	7a3526b48d7733a03729ec1c95205de7ec13b78912c61cb59dfd01b18a625c28	4
26	Кропотов	Андрей	admin	13500.00	+380972391239	kropotov231@gmail.com	kropotovAndrei	9191545e56b4fe700f8568538e3c8357c80c9942c5cae9d7c8e8d1646b997a9e	5
12	Иванов	Юрий	cashier	8000.00	+380654789129	youriiIvanov@gmail.com	IvanovYourii	67b213a8177bf5d9b0bffe13cf13337396f46ffda43567e4a21d5057bf35dc37	1
16	Просветова	София	cashier	8000.00	+380978231239	ProsvetovaSofija@gmail.com	pSofija	75e877c9051527d2e09450f162f27fab88698aff213a7d15bd5bfb9291d3bec4	2
20	Смолов	Андрей	cashier	8000.00	+380978765566	SmolOv@gmail.com	smolovAndry	11919de68023e41cf0bcdc62e8b70a6a99525f1d96382ab18dd9a64f54190e6d	3
24	Артимович 	Владимир	cashier	8000.00	+380652289129	Artimovich@gmail.com	ArtimovichVladimir	5b6c40126d01d6d242948e1a598109716ffd314a9192bfc197feb3057762dfa6	4
28	Репина	Светлана	cashier	8000.00	+380977825439	RepinaSveta@gmail.com	RSveta	3e544c1de3f3aa7961cbdd19ba77cc7e71a64bdb094b27db8c037701ea815de8	5
11	Петров	Василий	shop_assistant	10000.00	+380988567765	petrovVas@gmail.com	petrov_vasilii	e9bada2d8fc138b493a3d1ff67c7aa7f51822ae61852db5863c8177853c47379	1
15	Павлов	Сергей	shop_assistant	10000.00	+380777886145	PavlovSegei@gmail.com	PavlovSergei	dbba0cfa3f92557234167fcb94b838f370337449903cbc4b47fdd716c9b66d1c	2
19	Кутузова	Анастасия	shop_assistant	10000.00	+380978343145	kutuzova1922@gmail.com	anastasijaKutuzova	58655ffd60781d26a3362b2744520c56a50bc60eaf74512bcb194bd5680752d1	3
23	Кольцов 	Алексей	shop_assistant	10000.00	+380971123456	ColcevAlik@gmail.com	colcevaleksei	d8da84b410651220fa2e1a247fa801569495f6f4ea069fae542c14e04b462511	4
27	Брежнев	Дмитрий	shop_assistant	10000.00	+380979886145	BrejnevDmitrii@gmail.com	BrejnewDmitro	031f506209091c377efa3a558e900ea7eaf954f8d95f6b900cf09b621b9615eb	5
\.


--
-- Data for Name: publishing_agency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publishing_agency (publishing_agency_id, publishing_agency_name, phone_number, email) FROM stdin;
1	Ad Marginem	+380567343231	admarginem@gmail.com
2	BookChef	+380321785673	bookchefagency@gmail.com
3	ArtHuss	+380982728543	arthuss_agency@gmailc.com
4	Terra Incognita	+380788567761	terra_incognita@gmail.com
5	Pabulum	+380988275914	pabulum_bookagency@gmail.com
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, user_login, user_role, user_password) FROM stdin;
88	smolovAndry	cashier	11919de68023e41cf0bcdc62e8b70a6a99525f1d96382ab18dd9a64f54190e6d
89	ArtimovichVladimir	cashier	5b6c40126d01d6d242948e1a598109716ffd314a9192bfc197feb3057762dfa6
90	RSveta	cashier	3e544c1de3f3aa7961cbdd19ba77cc7e71a64bdb094b27db8c037701ea815de8
91	petrov_vasilii	shop_assistant	e9bada2d8fc138b493a3d1ff67c7aa7f51822ae61852db5863c8177853c47379
92	PavlovSergei	shop_assistant	dbba0cfa3f92557234167fcb94b838f370337449903cbc4b47fdd716c9b66d1c
93	anastasijaKutuzova	shop_assistant	58655ffd60781d26a3362b2744520c56a50bc60eaf74512bcb194bd5680752d1
101	SemenovAndrei1982	client	2dd1c28e5a791fb79326ecf45ef6a9393746d76d9faffbc80153b128acd0e4af
70	OstrovskayaVictorija	client	9d0ea08959e1c4fd5ce6531d768379bc102db383c87316ca7b1f73abfdf70239
71	LarisaRubentsova882	client	7d05e098c33ba199f900255245f7870deed7d1a71eb873b481df1db581403e67
72	TamaraKanaeva605	client	08f0b2715717abe979c7d54409a285636ac8c493cfdda4ec330b309ae5133bd8
73	EpifanVoloshtuk520	client	9a50447e3c467cd1184e6284ffa94f91384085eab2ac59b77fe3b2ab1fc486b1
75	semenov_alksndr	director	204b08cc9af8c34607ce420b04dbe1ab9319832d07a47d2b33870a6d7dddbbc5
76	ekaterina_makarchuck	manager	28698e64d6887829d90cf74036840f1b51fa65bea6a211c0861425e612406f2a
77	evelinaKOJINA	manager	4612feee9fa6bd671957fc1ac908aa985cdaa9aab9a04b9dc36731aa9a368b31
78	arnoldEgorov	manager	dd38c7b5f5ac35e960a533d673874649ee3c2cd1d8f8eb2e4c2f9bfe9b498c71
79	lilianaOst	manager	e7e0a11d19bf9bb82ad4af4c6bb4106d74c268959d1bef2a617f1fed64f90679
80	IsaevNikita	manager	60656c0b5388c93ecb4cbb2b3f0a5ce3dc7db550a656cf81eaa56be7dba28204
81	makarov_daniiL	admin	f1d80f8c48bd52c0b87e3a8055ad742259e4b72cf1883a4f9ec7287bdffa3c4c
82	eleonora_kruj	admin	fdf75ec0f9666081318e5797bd1b462392fdc7b825d2164fa5a849ef7c6faade
83	ribakova_marija	admin	21564debedb21a27333c6953e948d4f8162f0b3a6820b0f78ff21d715c0ee128
84	ratmir_piterskij	admin	7a3526b48d7733a03729ec1c95205de7ec13b78912c61cb59dfd01b18a625c28
85	kropotovAndrei	admin	9191545e56b4fe700f8568538e3c8357c80c9942c5cae9d7c8e8d1646b997a9e
86	IvanovYourii	cashier	67b213a8177bf5d9b0bffe13cf13337396f46ffda43567e4a21d5057bf35dc37
87	pSofija	cashier	75e877c9051527d2e09450f162f27fab88698aff213a7d15bd5bfb9291d3bec4
94	colcevaleksei	shop_assistant	d8da84b410651220fa2e1a247fa801569495f6f4ea069fae542c14e04b462511
95	BrejnewDmitro	shop_assistant	031f506209091c377efa3a558e900ea7eaf954f8d95f6b900cf09b621b9615eb
146	test_login	client	10a6e6cc8311a3e2bcc09bf6c199adecd5dd59408c343e926b129c4914f3cb01
\.


--
-- Name: author_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.author_author_id_seq', 21, true);


--
-- Name: authority_authority_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.authority_authority_id_seq', 18, true);


--
-- Name: book_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_book_id_seq', 46, true);


--
-- Name: book_shop_shop_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_shop_shop_id_seq', 5, true);


--
-- Name: chosen_chosen_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chosen_chosen_id_seq', 15, true);


--
-- Name: client_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_client_id_seq', 100, true);


--
-- Name: client_order_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_order_order_id_seq', 21, true);


--
-- Name: client_review_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_review_review_id_seq', 60, true);


--
-- Name: edition_edition_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.edition_edition_number_seq', 20, true);


--
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_employee_id_seq', 37, true);


--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publishing_agency_publishing_agency_id_seq', 5, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 194, true);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (author_id);


--
-- Name: authority authority_edition_author_edition_book_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_edition_author_edition_book_key UNIQUE (edition_author, edition_book);


--
-- Name: edition authority_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition
    ADD CONSTRAINT authority_id_unique UNIQUE (authority_id);


--
-- Name: authority authority_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_pkey PRIMARY KEY (authority_id);


--
-- Name: book book_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_pkey PRIMARY KEY (book_id);


--
-- Name: book_shop book_shop_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_shop
    ADD CONSTRAINT book_shop_pkey PRIMARY KEY (shop_id);


--
-- Name: chosen chosen_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chosen
    ADD CONSTRAINT chosen_pkey PRIMARY KEY (chosen_id);


--
-- Name: client client_client_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_client_login_key UNIQUE (client_login);


--
-- Name: client_order client_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_order
    ADD CONSTRAINT client_order_pkey PRIMARY KEY (order_id);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (client_id);


--
-- Name: client_review client_review_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review
    ADD CONSTRAINT client_review_pkey PRIMARY KEY (review_id);


--
-- Name: edition edition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition
    ADD CONSTRAINT edition_pkey PRIMARY KEY (edition_number);


--
-- Name: employee employee_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_email_key UNIQUE (email);


--
-- Name: employee employee_employee_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_employee_login_key UNIQUE (employee_login);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- Name: publishing_agency publishing_agency_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_email_key UNIQUE (email);


--
-- Name: publishing_agency publishing_agency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_pkey PRIMARY KEY (publishing_agency_id);


--
-- Name: publishing_agency publishing_agency_publishing_agency_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_publishing_agency_name_key UNIQUE (publishing_agency_name);


--
-- Name: users unique_user_login; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_user_login UNIQUE (user_login);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: client delete_from_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_from_users AFTER DELETE ON public.client FOR EACH ROW EXECUTE FUNCTION public.delete_user();


--
-- Name: employee delete_from_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_from_users AFTER DELETE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.delete_user();


--
-- Name: client make_client_password_hash; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER make_client_password_hash BEFORE INSERT OR UPDATE ON public.client FOR EACH ROW EXECUTE FUNCTION public.hash_password();


--
-- Name: employee make_employee_password_hash; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER make_employee_password_hash BEFORE INSERT OR UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.hash_password();


--
-- Name: chosen reduce_available_books_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER reduce_available_books_trigger AFTER INSERT ON public.chosen FOR EACH ROW EXECUTE FUNCTION public.reduce_available_books();


--
-- Name: client update_users_with_client; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_with_client AFTER INSERT OR UPDATE ON public.client FOR EACH ROW EXECUTE FUNCTION public.update_users_table();


--
-- Name: employee update_users_with_employee; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_with_employee AFTER INSERT OR UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.update_users_table();


--
-- Name: authority authority_edition_author_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_edition_author_fkey FOREIGN KEY (edition_author) REFERENCES public.author(author_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: authority authority_edition_book_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_edition_book_fkey FOREIGN KEY (edition_book) REFERENCES public.book(book_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: chosen chosen_edition_number_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chosen
    ADD CONSTRAINT chosen_edition_number_fkey FOREIGN KEY (edition_number) REFERENCES public.edition(edition_number) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: chosen chosen_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chosen
    ADD CONSTRAINT chosen_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.client_order(order_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: client_order client_order_reciever_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_order
    ADD CONSTRAINT client_order_reciever_fkey FOREIGN KEY (reciever) REFERENCES public.client(client_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: client_order client_order_sender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_order
    ADD CONSTRAINT client_order_sender_fkey FOREIGN KEY (sender) REFERENCES public.employee(employee_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: client_review client_review_review_about_book_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review
    ADD CONSTRAINT client_review_review_about_book_fkey FOREIGN KEY (review_about_book) REFERENCES public.edition(authority_id);


--
-- Name: client_review client_review_review_about_shop_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review
    ADD CONSTRAINT client_review_review_about_shop_fkey FOREIGN KEY (review_about_shop) REFERENCES public.book_shop(shop_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: edition edition_authority_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition
    ADD CONSTRAINT edition_authority_id_fkey FOREIGN KEY (authority_id) REFERENCES public.authority(authority_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: edition edition_concrete_shop_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition
    ADD CONSTRAINT edition_concrete_shop_fkey FOREIGN KEY (concrete_shop) REFERENCES public.book_shop(shop_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: employee work_where; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT work_where FOREIGN KEY (place_of_work) REFERENCES public.book_shop(shop_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO user_checker;
GRANT USAGE ON SCHEMA public TO user_client;


--
-- Name: FUNCTION concrete_book_full_info(book_title character varying, publ_date date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) TO user_client;


--
-- Name: FUNCTION create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) TO user_client;


--
-- Name: FUNCTION get_book_reviews(book_title_ character varying, book_publishing_date_ date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) TO user_client;


--
-- Name: FUNCTION get_min_max_book_prices(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_min_max_book_prices() TO user_client;


--
-- Name: FUNCTION insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) TO user_client;


--
-- Name: FUNCTION update_users_table(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_users_table() TO user_client;


--
-- Name: TABLE available_books_view; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.available_books_view TO user_client;


--
-- Name: TABLE client; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.client TO user_checker;


--
-- Name: TABLE book_reviews; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.book_reviews TO user_client;


--
-- Name: SEQUENCE client_client_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.client_client_id_seq TO user_client;


--
-- Name: SEQUENCE client_review_review_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.client_review_review_id_seq TO user_client;


--
-- Name: TABLE employee; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.employee TO user_checker;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO user_checker;


--
-- Name: SEQUENCE users_user_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.users_user_id_seq TO user_client;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: user_client
--

ALTER DEFAULT PRIVILEGES FOR ROLE user_client REVOKE ALL ON FUNCTIONS  FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

