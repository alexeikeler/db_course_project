--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5 (Ubuntu 14.5-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.5 (Ubuntu 14.5-0ubuntu0.22.04.1)

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
-- Name: add_author(character varying, character varying, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date DEFAULT NULL::date) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE ret_author_id integer;

        BEGIN
            INSERT INTO
                author(lastname, firstname, date_of_birth, date_of_death)
            VALUES
                (lastname_, firstname_, dob_, dod_)
            RETURNING author.author_id INTO ret_author_id;
            RETURN ret_author_id;
        END;
    $$;


ALTER FUNCTION public.add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date) OWNER TO postgres;

--
-- Name: add_edition(integer, character varying, character varying, integer, character varying, numeric, date, integer, integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            new_book_id integer;
            new_authority_id integer;
            new_edition_id integer;
            publ_agency_id integer;

            BEGIN

                SELECT
                    publishing_agency_id
                INTO
                    publ_agency_id
                FROM
                    publishing_agency
                WHERE
                    publishing_agency_name = publishing_agency_;

                INSERT INTO
                    book(title, genre_type)
                VALUES
                    (book_title_, book_genre_type)
                RETURNING
                    book_id
                INTO
                    new_book_id;

                INSERT INTO
                    authority(edition_author, edition_book)
                VALUES
                    (book_author_id, new_book_id)
                RETURNING
                    authority_id
                INTO
                    new_authority_id;

                INSERT INTO
                    edition(
                            authority_id, publishing_agency_id, concrete_shop, price, publishing_date,
                            number_of_copies_in_shop, number_of_pages, binding_type, paper_quality
                           )
                VALUES
                    (
                     new_authority_id, publ_agency_id, manager_pow, price_, publishing_date_,
                     available_copies_, pages_, binding_type_, paper_quality_
                    )
                RETURNING edition_number INTO new_edition_id;

                RETURN new_edition_id;

            END;
    $$;


ALTER FUNCTION public.add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying) OWNER TO postgres;

--
-- Name: add_employee_review(character varying, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_employee_review(user_login character varying, employee_id integer, user_review_text text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    DECLARE
        user_id integer;

        BEGIN
            SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login;

            INSERT INTO
                client_review(review_date, review_by, review_about_employee, review_text)
            VALUES
                (CURRENT_TIMESTAMP, user_id, employee_id, user_review_text);
        END;
    $$;


ALTER FUNCTION public.add_employee_review(user_login character varying, employee_id integer, user_review_text text) OWNER TO postgres;

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

CREATE FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            emp_id integer;
            cli_id integer;
            book_edition_number integer;
            current_order_id integer;
            available_amount integer;

        BEGIN

            SELECT client.client_id INTO cli_id FROM client WHERE client.client_login = cli_login_;

            SELECT
                edition.edition_number, edition.number_of_copies_in_shop
            INTO
                book_edition_number, available_amount
            FROM
                edition, authority, book
            WHERE
                edition.authority_id = authority.authority_id
            AND
                authority.edition_book = book.book_id
            AND
                book.title = book_title_
            AND
                edition.publishing_date = date_of_publishing_;

            IF quantity_ > available_amount THEN
                RAISE EXCEPTION 'To much books ordered. Maximum amount is: %', available_amount;
            END IF;

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

            RETURN current_order_id;
            END
    $$;


ALTER FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) OWNER TO postgres;

--
-- Name: add_shop_review(character varying, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            user_id integer;

        BEGIN
            SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login_;

            INSERT INTO
                client_review(review_date, review_by, review_about_shop, review_text)
            VALUES
                (CURRENT_TIMESTAMP, user_id, shop_id_, user_review_text_);
        END;
    $$;


ALTER FUNCTION public.add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text) OWNER TO postgres;

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
-- Name: change_employee_salary(integer, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_employee_salary(id integer, new_salary numeric) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$

        BEGIN
           UPDATE employee
           SET salary = new_salary
           WHERE employee_id = id;

           IF EXISTS(SELECT id FROM employee WHERE employee_id = id AND salary = new_salary) THEN
                RETURN TRUE;
           ELSE
                RETURN FALSE;
           END IF;

        END
    $$;


ALTER FUNCTION public.change_employee_salary(id integer, new_salary numeric) OWNER TO postgres;

--
-- Name: change_password(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_password(login character varying, old_password character varying, new_password character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$

    BEGIN

        IF EXISTS(
            SELECT *
            FROM users
            WHERE
                users.user_login = login
            AND
                users.user_password = encode(digest(old_password, 'sha256'), 'hex')
            )
            THEN
                UPDATE users
                SET
                    user_password = new_password
                WHERE
                    user_login = login;
                RETURN TRUE;

        ELSE
            RAISE WARNING 'Wrong password!';
            RETURN FALSE;

        END IF;

    END;
    $$;


ALTER FUNCTION public.change_password(login character varying, old_password character varying, new_password character varying) OWNER TO postgres;

--
-- Name: client_activity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.client_activity() RETURNS TABLE(id integer, login character varying, oldest_order timestamp without time zone, newest_order timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                client_id,
                client.client_login,
                min(date_of_order) AS oldest,
                max(date_of_order) AS newest
            FROM
                client
            LEFT JOIN
                client_order co ON client.client_id = co.reciever
            GROUP BY
                client.client_id, client.client_login
            ORDER BY
                oldest;
        END;
    $$;


ALTER FUNCTION public.client_activity() OWNER TO postgres;

--
-- Name: concrete_book_full_info(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) RETURNS TABLE(author_ character varying, title_ character varying, genre_ character varying, available_amount_ smallint, shop_ integer, binding_type_ character varying, number_of_pages_ smallint, publishing_date_ date, publishing_agency_ character varying, paper_type_ character varying, price_ numeric)
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
                    paper_quality,
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
            client(client_firstname, client_lastname, phone_number, email, client_login, delivery_address)
        VALUES
            (client_firstname_, client_lastname_, phone_number_, email_, client_login_, delivery_address_);

        INSERT INTO
            users(user_login, user_role, user_password)
        VALUES
            (client_login_, 'client', client_password_);

        RETURN QUERY
        SELECT EXISTS(
            SELECT * FROM client WHERE client.client_login = client_login_
        );
        END;
$$;


ALTER FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) OWNER TO postgres;

--
-- Name: create_employee(character varying, character varying, character varying, numeric, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_employee(employee_lastname_ character varying, employee_firstname_ character varying, employee_position_ character varying, employee_salary_ numeric, employee_phone_num_ character varying, employee_email_ character varying, employee_login_ character varying, employee_password_ character varying, employee_place_of_work integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            sa_count INTEGER;
            sa_flag BOOLEAN = FALSE;
            m_count INTEGER;
            m_flag BOOLEAN = FALSE;
            dummy_sa_id INTEGER;
            dummy_m_id INTEGER;
            new_emp_id INTEGER;
            error_message VARCHAR = format(
                'Employee with position %s already exists in shop # %s. '
                'If you need new employee with this position in this shop, '
                'please delete old one first.',
                employee_position_, employee_place_of_work
                );

        BEGIN

            IF employee_position_ LIKE 'shop_assistant'
                 THEN
                     sa_flag = TRUE;
                     SELECT COUNT(employee_position) INTO sa_count FROM employee
                     WHERE employee_position = 'shop_assistant' AND place_of_work = employee_place_of_work;
                        RAISE INFO 'sa_count: %', sa_count;
                     IF sa_count = 2
                         THEN
                             RAISE WARNING '%', error_message;
                             RETURN;
                     END IF;

                     SELECT employee_id INTO dummy_sa_id FROM employee
                     WHERE employee_position = 'shop_assistant' AND place_of_work = employee_place_of_work;

            ELSIF employee_position_ LIKE 'manager'
                THEN
                    m_flag = TRUE;
                    SELECT COUNT(employee_position) INTO m_count FROM employee
                    WHERE employee_position = 'manager' AND place_of_work = employee_place_of_work;

                    RAISE INFO 'm_count: %', m_count;

                    IF m_count = 2
                        THEN
                            RAISE WARNING '%', error_message;
                            RETURN;
                    END IF;

                    SELECT employee_id INTO dummy_m_id FROM employee
                    WHERE employee_position = 'manager' AND place_of_work = employee_place_of_work;

            ELSE
                IF EXISTS(
                    SELECT
                        employee_id
                    FROM
                        employee
                    WHERE
                        employee_position = employee_position_ AND place_of_work = employee_place_of_work
                    ) THEN
                        RAISE WARNING '%', error_message;
                        RETURN;
                END IF;

                IF EXISTS(SELECT employee_id FROM employee WHERE employee_login = employee_login_) THEN
                     RAISE WARNING
                         'Employee with login % already exists!', employee_login_;
                     RETURN;
                END IF;

            END IF;

            INSERT INTO employee
                (lastname, firstname, employee_position, salary, phone_number, email, employee_login, place_of_work)
            VALUES
                (
                 employee_lastname_,
                 employee_firstname_,
                 employee_position_,
                 employee_salary_,
                 employee_phone_num_,
                 employee_email_,
                 employee_login_,
                 employee_place_of_work
                )
             RETURNING
                employee_id INTO new_emp_id;


            INSERT INTO
                users(user_login, user_role, user_password)
            VALUES
                (employee_login_, employee_position_, employee_password_);

            IF sa_flag THEN
                RAISE INFO 'IN SA_FLAG CHECK| sa_flag: % | new_emp_id: % | dummy_sa_id: %', sa_flag, new_emp_id, dummy_sa_id;
                UPDATE client_order
                    SET sender = new_emp_id
                    WHERE sender = dummy_sa_id;

            ELSIF m_flag THEN
                RAISE INFO 'IN M_FLAG CHECK| m_flag: % | new_emp_id: % | dummy_m_id: %', m_flag, new_emp_id, dummy_m_id;
                UPDATE book_shop
                    SET manager = new_emp_id
                    WHERE manager = dummy_m_id;
                END IF;

            IF EXISTS( SELECT employee_id FROM employee WHERE employee_login = employee_login_) THEN
                RAISE INFO 'New account: ROLE - % | LOGIN - % created.', employee_position_, employee_login_;
                RETURN;
            ELSE
                RAISE WARNING
                    'Error occured while creating account: ROLE - % | LOGIN - %', employee_position_, employee_login_;
                RETURN;
            END IF;

            END
    $$;


ALTER FUNCTION public.create_employee(employee_lastname_ character varying, employee_firstname_ character varying, employee_position_ character varying, employee_salary_ numeric, employee_phone_num_ character varying, employee_email_ character varying, employee_login_ character varying, employee_password_ character varying, employee_place_of_work integer) OWNER TO postgres;

--
-- Name: delete_author(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_author(author_id_ integer) RETURNS TABLE(id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            DELETE FROM author
            WHERE author.author_id = author_id_
            AND author.author_id IN (
                SELECT
                    author.author_id
                FROM
                    author
                LEFT JOIN authority on
                    author.author_id = authority.edition_author
                WHERE
                    authority_id is null
                )
            RETURNING author_id;

        END;
    $$;


ALTER FUNCTION public.delete_author(author_id_ integer) OWNER TO postgres;

--
-- Name: delete_client(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_client(id integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            dummy_client_id integer;

        BEGIN
            IF EXISTS(

                SELECT order_id  FROM client_order
                WHERE reciever = id AND order_status SIMILAR TO '(Оплачен|Обработан|Доставляется)'
                ) THEN

                RETURN FALSE;

            END IF;

            SELECT client_id INTO dummy_client_id FROM client WHERE client_login = 'DeletedAccount';

            UPDATE client_order
                SET reciever = dummy_client_id
                WHERE reciever = id;

            UPDATE client_review
                SET review_by = dummy_client_id
                WHERE review_by = id;

            DELETE FROM client WHERE client_id = id;
            DELETE FROM client_review WHERE review_by = id;

           RETURN TRUE;

        END;
    $$;


ALTER FUNCTION public.delete_client(id integer) OWNER TO postgres;

--
-- Name: delete_edition(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_edition(edition_id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    DECLARE
        authority_id_ integer;
        book_id_ integer;

        BEGIN
            SELECT edition.authority_id INTO authority_id_ FROM edition WHERE edition_number = edition_id;
            SELECT authority.edition_book INTO book_id_ FROM authority WHERE authority.authority_id = authority_id_;

            DELETE FROM client_review where review_about_book = book_id_;
            DELETE FROM edition WHERE edition.edition_number = edition_id;
            DELETE FROM authority WHERE authority.authority_id = authority_id_;
            DELETE FROM book WHERE book.book_id = book_id_;

            END
    $$;


ALTER FUNCTION public.delete_edition(edition_id integer) OWNER TO postgres;

--
-- Name: delete_employee(integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_employee(id integer, pos character varying, pow integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        DECLARE
            dummy_sender integer;
            dummy_manager integer;

        BEGIN
            CASE pos
                WHEN 'director'
                    THEN
                        DELETE FROM client_review WHERE review_about_employee = id;
                        DELETE FROM employee WHERE employee_id = id;
                        RETURN TRUE;

                WHEN 'shop_assistant'
                    THEN
                        IF EXISTS(
                            SELECT order_id FROM client_order
                                            WHERE sender = id AND order_status NOT IN ('Доставлен', 'Отменён')
                            ) THEN

                                RETURN FALSE;
                        END IF;

                        SELECT employee_id INTO dummy_sender FROM employee
                        WHERE employee_login = format('dummy_shop_assistant_%s', pow);

                        UPDATE client_order
                        SET sender = dummy_sender
                        WHERE sender = id;

                        DELETE FROM client_review WHERE review_about_employee = id;
                        DELETE FROM employee WHERE employee_id = id;

                        RETURN TRUE;

                WHEN 'manager'
                    THEN
                        SELECT employee_id INTO dummy_manager FROM employee
                        WHERE employee_login = format('dummy_manager_%s', pow);

                        UPDATE book_shop
                        SET manager = dummy_manager
                        WHERE manager = id;

                        DELETE FROM employee WHERE employee_id = id;

                        RETURN TRUE;

                ELSE
                    RETURN FALSE;
            END CASE;

        END
    $$;


ALTER FUNCTION public.delete_employee(id integer, pos character varying, pow integer) OWNER TO postgres;

--
-- Name: delete_review(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_review(id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            DELETE FROM client_review WHERE review_id = id;
        END;
    $$;


ALTER FUNCTION public.delete_review(id integer) OWNER TO postgres;

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
                       users.user_login = OLD.client_login;
            RAISE INFO 'Deleted client %', OLD.client_login;

        ELSIF (TG_TABLE_NAME = 'employee')
            THEN
                DELETE FROM users WHERE users.user_login = OLD.employee_login;

            RAISE INFO 'Deleted employee %', OLD.employee_login;

        END IF;

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.delete_user() OWNER TO postgres;

--
-- Name: employee_activity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_activity() RETURNS TABLE(empl_id_ integer, empl_firstname character varying, empl_lastname character varying, empl_login character varying, counted_reviews_ integer, name_of_shop_ character varying, empl_pos_ character varying, salary numeric, phone_num character varying, email character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                employee.employee_id,
                employee.firstname,
                employee.lastname,
                employee.employee_login,
                empl_reviews_ctr.counted_reviews::int,
                book_shop.name_of_shop,
                employee.employee_position,
                employee.salary,
                employee.phone_number,
                employee.email
            FROM
                book_shop, employee
            LEFT JOIN
                    (
                        SELECT
                            review_about_employee, count(review_about_employee) AS counted_reviews
                        FROM
                            client_review
                        GROUP BY
                            review_about_employee
                    ) AS empl_reviews_ctr
            ON
                employee.employee_id = empl_reviews_ctr.review_about_employee

            WHERE
                employee.place_of_work = book_shop.shop_id
            ORDER BY employee.employee_position, employee.employee_login;
        END;

    $$;


ALTER FUNCTION public.employee_activity() OWNER TO postgres;

--
-- Name: get_authors(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_authors(author_name character varying) RETURNS TABLE(author_id_ integer, author_name_ character varying, date_of_birth_ date, date_of_death_ date)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
    $$;


ALTER FUNCTION public.get_authors(author_name character varying) OWNER TO postgres;

--
-- Name: get_book_reviews(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) RETURNS TABLE(review_id_ integer, review_by_ character varying, review_date_ timestamp without time zone, review_ text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
        RETURN QUERY
        SELECT review_id, user_login, review_date, review
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
-- Name: get_cli_orders_statuses(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_cli_orders_statuses(client_login_ character varying) RETURNS TABLE(order_status_ character varying, couned_ integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
    $$;


ALTER FUNCTION public.get_cli_orders_statuses(client_login_ character varying) OWNER TO postgres;

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
-- Name: get_client_orders(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_client_orders(login character varying) RETURNS TABLE(book_title_ character varying, genre_ character varying, quantity_ integer, sum_to_pay_ numeric, order_status_ character varying, date_of_order_ timestamp without time zone, date_of_return_ timestamp without time zone, date_of_delivery_ timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
                SELECT
                    title, genre_type, quantity, sum_to_pay,
                    order_status, date_of_order, date_of_return, date_of_delivery
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
    $$;


ALTER FUNCTION public.get_client_orders(login character varying) OWNER TO postgres;

--
-- Name: get_client_sales_by_genre(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_client_sales_by_genre(client_login_ character varying) RETURNS TABLE(genre_ character varying, money_spend_ numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
    $$;


ALTER FUNCTION public.get_client_sales_by_genre(client_login_ character varying) OWNER TO postgres;

--
-- Name: get_employee_info(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_employee_info(shop_num integer, pos character varying) RETURNS TABLE(employee_id_ integer, employee_name_ character varying, employee_position_ character varying, employee_place_of_work_ character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
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
                employee.firstname !~'([0-9]$)'
            AND
                employee.place_of_work = shop_num
            AND
                book_shop.shop_id = employee.place_of_work;

        END;
    $_$;


ALTER FUNCTION public.get_employee_info(shop_num integer, pos character varying) OWNER TO postgres;

--
-- Name: get_employee_main_data(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_employee_main_data(login character varying) RETURNS TABLE(empl_id integer, empl_place_of_work integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
                SELECT
                    employee.employee_id, employee.place_of_work
                FROM
                    employee
                WHERE
                    employee.employee_login = login;

        END;
    $$;


ALTER FUNCTION public.get_employee_main_data(login character varying) OWNER TO postgres;

--
-- Name: get_employees_salary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_employees_salary() RETURNS TABLE(empl_id integer, empl_name character varying, empl_pos character varying, empl_salary numeric, empl_pow character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
        BEGIN
            RETURN QUERY

            SELECT
                employee_id,
                CAST(firstname || ' ' || lastname AS varchar) name,
                employee_position,
                salary,
                name_of_shop
            FROM
                employee, book_shop
            WHERE
                employee.firstname !~ '\d+$'
            AND
                employee.place_of_work = book_shop.shop_id
            ORDER BY place_of_work;
        END
    $_$;


ALTER FUNCTION public.get_employees_salary() OWNER TO postgres;

--
-- Name: get_genre_sales(integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone) RETURNS TABLE(genre_type_ character varying, sum_per_genre_ numeric, sold_copies_ integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY

            SELECT inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies FROM(

                SELECT
                    genre_type,
                    sum(sum_to_pay) OVER(PARTITION BY genre_type)::numeric(10, 2) AS sum_per_genre,
                    sum(quantity) OVER(PARTITION BY genre_type):: integer AS sold_copies
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_time AND r_time) AS inner_select

            GROUP BY inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies
            ORDER BY  inner_select.sum_per_genre DESC;

        END
    $$;


ALTER FUNCTION public.get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone) OWNER TO postgres;

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
-- Name: get_number_of_books(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_number_of_books(manager_pow integer) RETURNS TABLE(edition_id integer, author character varying, title character varying, available smallint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                edition.edition_number,
                CAST(author.firstname ||' '|| author.lastname AS varchar) author,
                book.title,
                edition.number_of_copies_in_shop
            FROM
                book, author, authority, edition
            WHERE
                edition.authority_id = authority.authority_id
            AND
                authority.edition_author = author.author_id
            AND
                authority.edition_book = book.book_id
            AND
                edition.concrete_shop = manager_pow
            ORDER BY
                edition.number_of_copies_in_shop DESC;
        END
    $$;


ALTER FUNCTION public.get_number_of_books(manager_pow integer) OWNER TO postgres;

--
-- Name: get_order_statuses_count(integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) RETURNS TABLE(order_status_ character varying, counted_ integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
                SELECT
                    order_status,
                    count(order_status)::integer as counted
                FROM
                    sales
                WHERE
                    concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_date AND r_date
                GROUP BY order_status;

        END;
    $$;


ALTER FUNCTION public.get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) OWNER TO postgres;

--
-- Name: get_orders_distribtuion_by_month(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_orders_distribtuion_by_month(client_login_ character varying) RETURNS TABLE(date_ timestamp without time zone, counted_ integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
    $$;


ALTER FUNCTION public.get_orders_distribtuion_by_month(client_login_ character varying) OWNER TO postgres;

--
-- Name: get_payment_types_count(integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) RETURNS TABLE(payment_type_ character varying, counted_ integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
                SELECT
                    payment_type,
                    count(payment_type)::integer as counted
                FROM
                    sales
                WHERE
                    concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_date AND r_date
                GROUP BY payment_type;

        END;
    $$;


ALTER FUNCTION public.get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) OWNER TO postgres;

--
-- Name: get_publishing_agencies(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_publishing_agencies() RETURNS TABLE(agency_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT publishing_agency_name FROM publishing_agency;
        END;
    $$;


ALTER FUNCTION public.get_publishing_agencies() OWNER TO postgres;

--
-- Name: get_reviews_about_employee(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reviews_about_employee(employee_id integer) RETURNS TABLE(review_id_ integer, review_by_ character varying, review_date_ timestamp without time zone, review_text_ text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                review_id, client_login, review_date, review_text
            FROM
                client_review, client
            WHERE
                client_review.review_about_employee = employee_id
            AND
                client.client_id = client_review.review_by;
        END;
    $$;


ALTER FUNCTION public.get_reviews_about_employee(employee_id integer) OWNER TO postgres;

--
-- Name: get_reviews_for_shop_assistant(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying) RETURNS TABLE(review_id_ integer, review_date_ timestamp without time zone, review_by_ character varying, review_about_ character varying, review_text_ text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    DECLARE
        sa_place_of_work integer;

        BEGIN
            SELECT employee.place_of_work INTO sa_place_of_work FROM employee WHERE employee.employee_login = sa_login;
            RAISE INFO 'sa pow: %', sa_place_of_work;

            CASE reviews_about

                WHEN 'Books' THEN
                    RETURN QUERY
                        SELECT
                            review_id, review_date, client_login, title, review_text
                        FROM
                            client_review, client, edition, authority, book
                        WHERE
                            review_about_book IS NOT NULL
                        AND
                            review_by = client.client_id
                        AND
                            review_about_book = edition.authority_id
                        AND
                            sa_place_of_work = edition.concrete_shop
                        AND
                            edition.authority_id = authority.authority_id
                        AND
                            authority.edition_book = book.book_id;

                WHEN 'Shops' THEN
                    RETURN QUERY
                        SELECT
                            review_id, review_date, client_login, name_of_shop, review_text
                        FROM
                            client_review, client, book_shop
                        WHERE
                            review_about_shop IS NOT NULL
                        AND
                            sa_place_of_work = review_about_shop
                        AND
                            sa_place_of_work = shop_id
                        AND
                            client.client_id = client_review.review_by;

                WHEN 'Employees' THEN
                    RETURN QUERY
                        SELECT
                            review_id, review_date, client_login, employee_login, review_text
                        FROM
                            client_review, client, employee
                        WHERE
                            review_about_employee IS NOT NULL
                        AND
                            sa_place_of_work = employee.place_of_work
                        AND
                            client.client_id = client_review.review_by
                        AND
                            employee.employee_id = client_review.review_about_employee;

            END CASE;
        END
    $$;


ALTER FUNCTION public.get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying) OWNER TO postgres;

--
-- Name: get_sales_by_date(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sales_by_date(manager_pow integer, trunc_by character varying) RETURNS TABLE(date_ date, sum_per_partition_ numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                inner_select.month_of_sale, inner_select.sum_per_month
            FROM (

                SELECT
                    date_trunc(trunc_by, date_of_order)::date
                        AS month_of_sale,
                    SUM(sum_to_pay) OVER(PARTITION BY date_trunc(trunc_by, date_of_order))::numeric(7, 2)
                        AS sum_per_month
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                )
                AS inner_select

            GROUP BY
                month_of_sale, sum_per_month
            ORDER BY
                month_of_sale;

        END;
    $$;


ALTER FUNCTION public.get_sales_by_date(manager_pow integer, trunc_by character varying) OWNER TO postgres;

--
-- Name: get_shop_assistant_orders(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_shop_assistant_orders(sa_login character varying) RETURNS TABLE(order_id_ integer, state_ character varying, customer_name_ character varying, customer_phone_num character varying, customer_email character varying, customer_login_ character varying, ordered_book character varying, quantity_ integer, ordering_date_ timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


ALTER FUNCTION public.get_shop_assistant_orders(sa_login character varying) OWNER TO postgres;

--
-- Name: get_shop_info(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_shop_info(shop_num integer) RETURNS TABLE(shop_id_ integer, name_of_shop_ character varying, employees_num_ character varying, post_code_ character varying, country_ character varying, city_ character varying, street_ character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                shop_id, name_of_shop, number_of_employees::varchar, post_code, country, city, street
            FROM
                book_shop
            WHERE
                book_shop.shop_id = shop_num;
        END;
    $$;


ALTER FUNCTION public.get_shop_info(shop_num integer) OWNER TO postgres;

--
-- Name: get_shop_reviews(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_shop_reviews(shop_num integer) RETURNS TABLE(review_id_ integer, review_by_ character varying, review_date_ timestamp without time zone, review_text_ text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                review_id, client_login, review_date, review_text
            FROM
                client_review, client
            WHERE
                client_review.review_about_shop = shop_num
            AND
                client.client_id = client_review.review_by;
        END;
    $$;


ALTER FUNCTION public.get_shop_reviews(shop_num integer) OWNER TO postgres;

--
-- Name: get_top_selling_books(integer, timestamp without time zone, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer) RETURNS TABLE(title_ character varying, sold_copies integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            RETURN QUERY
                SELECT
                    title,
                    sum(sum(quantity)) OVER(PARTITION BY title)::integer as sold_cop_num
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                AND
                    date_of_order BETWEEN l_time AND r_time
                GROUP BY title
                ORDER BY sold_cop_num DESC
                LIMIT n_top;
        END;
    $$;


ALTER FUNCTION public.get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer) OWNER TO postgres;

--
-- Name: hash_password(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hash_password() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    BEGIN
        RAISE INFO 'IN TRIGGER HASH PASS';
        IF (TG_OP = 'INSERT' OR NEW.user_password NOT LIKE OLD.user_password)
            THEN
                NEW.user_password = encode(digest(NEW.user_password, 'sha256'), 'hex');
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
-- Name: not_sold_books(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.not_sold_books(manager_pow integer) RETURNS TABLE(id integer, author_name character varying, book_title character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN

            RETURN QUERY

                SELECT
                    edition.edition_number AS id,
                    CAST(a.firstname ||' '|| a.lastname AS varchar) author_name,
                    b.title AS book_title
                FROM
                    edition
                    INNER JOIN authority ON edition.authority_id = authority.authority_id
                    INNER JOIN book b ON b.book_id = authority.edition_book
                    INNER JOIN author a ON a.author_id = authority.edition_author
                    LEFT JOIN chosen c ON edition.edition_number = c.edition_number WHERE c.edition_number IS NULL
                    AND edition.concrete_shop = manager_pow;

        END;
    $$;


ALTER FUNCTION public.not_sold_books(manager_pow integer) OWNER TO postgres;

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
-- Name: return_ordered_books(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.return_ordered_books() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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

    $$;


ALTER FUNCTION public.return_ordered_books() OWNER TO postgres;

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
-- Name: update_editions_number(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_editions_number(edition_id integer, update_by integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
            UPDATE edition
            SET number_of_copies_in_shop = number_of_copies_in_shop + update_by
            WHERE edition_number = edition_id;
        END;
    $$;


ALTER FUNCTION public.update_editions_number(edition_id integer, update_by integer) OWNER TO postgres;

--
-- Name: update_employee_data(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_employee_data(update_subject character varying, data character varying, id integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
        DECLARE
            exists integer = -1;

        BEGIN
            EXECUTE format(
                'UPDATE employee SET %1$s = %2$L WHERE %3$s = %4$s', update_subject, data, 'employee_id', id
                );

            EXECUTE FORMAT(
                'SELECT employee_id FROM employee WHERE %1$s = %2$L', update_subject, data
                ) INTO exists;

            IF exists > 0 THEN
                RAISE INFO '%', exists;
                RETURN TRUE;
            ELSE
                RETURN FALSE;

            END IF;
        END
    $_$;


ALTER FUNCTION public.update_employee_data(update_subject character varying, data character varying, id integer) OWNER TO postgres;

--
-- Name: update_number_of_employees(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_number_of_employees() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            CASE TG_OP
                WHEN 'INSERT' THEN
                    UPDATE book_shop
                    SET number_of_employees = number_of_employees + 1
                    WHERE NEW.place_of_work = shop_id;
                WHEN 'DELETE' THEN
                    UPDATE book_shop
                    SET number_of_employees = number_of_employees - 1
                    WHERE OLD.place_of_work = shop_id;
            END CASE;
        RETURN NEW;
        END;
    $$;


ALTER FUNCTION public.update_number_of_employees() OWNER TO postgres;

--
-- Name: update_user_order(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_user_order(current_order_id integer, status character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
        BEGIN
        CASE status

           WHEN 'Отменён'
               THEN
                   RAISE INFO 'Order is declined';
                  UPDATE client_order
                    SET
                        order_status = status,
                        date_of_return = now()
                    WHERE
                        order_id = current_order_id;
                   RETURN TRUE;

           WHEN 'Доставлен'
               THEN
                   RAISE INFO 'Finishing order.';
                    UPDATE client_order
                    SET
                        order_status = status,
                        date_of_delivery = now()
                    WHERE
                        order_id = current_order_id;
                   RETURN TRUE;
           ELSE
                    RAISE INFO 'Updating order % to status %', current_order_id, status;
                    UPDATE client_order
                    SET
                        order_status = status
                    WHERE
                        order_id = current_order_id;
                    RETURN TRUE;
            END CASE;

        END;

    $$;


ALTER FUNCTION public.update_user_order(current_order_id integer, status character varying) OWNER TO postgres;

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
                END IF;

        END IF;

        IF (TG_TABLE_NAME = 'employee')
            THEN
                IF NEW.employee_login NOT LIKE OLD.employee_login
                    THEN
                    RAISE INFO 'Updating employee login from % to %', OLD.employee_login, NEW.employee_login;
                    UPDATE users
                    SET user_login = NEW.employee_login
                    WHERE user_login = OLD.employee_login;
                END IF;

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
    publishing_agency.publishing_agency_name AS publising_agency_name,
    edition.paper_quality
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
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    client_id integer NOT NULL,
    client_firstname character varying(64) NOT NULL,
    client_lastname character varying(64) NOT NULL,
    phone_number character varying(16) NOT NULL,
    email character varying(64) NOT NULL,
    client_login character varying(64) NOT NULL,
    delivery_address character varying(128),
    CONSTRAINT client_client_firstname_check CHECK ((length((client_firstname)::text) > 0)),
    CONSTRAINT client_client_lastname_check CHECK ((length((client_lastname)::text) > 0)),
    CONSTRAINT client_client_login_check CHECK ((length((client_login)::text) > 0)),
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
 SELECT client_review.review_id,
    client.client_login AS user_login,
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
    manager smallint DEFAULT 1 NOT NULL,
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
    date_of_delivery timestamp(0) without time zone,
    CONSTRAINT client_order_additional_info_check CHECK ((length((additional_info)::text) > 0)),
    CONSTRAINT client_order_check CHECK ((date_of_delivery > date_of_order)),
    CONSTRAINT client_order_delivery_address_check CHECK ((length((delivery_address)::text) > 0)),
    CONSTRAINT client_order_payment_type_check CHECK (((payment_type)::text = ANY (ARRAY[('Наличные'::character varying)::text, ('Карта'::character varying)::text]))),
    CONSTRAINT client_order_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT client_order_sum_to_pay_check CHECK ((sum_to_pay > (0)::numeric)),
    CONSTRAINT client_return_check CHECK ((date_of_return > date_of_order))
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
    place_of_work integer NOT NULL,
    CONSTRAINT employee_email_check CHECK (((email)::text ~ similar_to_escape('[A-Za-z0-9._%+-]+@[A-Za-z0-9]+\.[A-Za-z]{2,4}'::text))),
    CONSTRAINT employee_employee_login_check CHECK ((length((employee_login)::text) > 0)),
    CONSTRAINT employee_employee_position_check CHECK (((employee_position)::text = ANY (ARRAY[('director'::character varying)::text, ('admin'::character varying)::text, ('manager'::character varying)::text, ('cashier'::character varying)::text, ('shop_assistant'::character varying)::text]))),
    CONSTRAINT employee_firstname_check CHECK ((length((firstname)::text) > 0)),
    CONSTRAINT employee_lastname_check CHECK ((length((lastname)::text) > 0)),
    CONSTRAINT employee_phone_number_check CHECK (((phone_number)::text ~ similar_to_escape('\+?3?8?(0\d{9})'::text))),
    CONSTRAINT employee_salary_check CHECK ((salary >= (0)::numeric))
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
-- Name: sales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sales AS
 SELECT edition.concrete_shop,
    client_order.order_id,
    book.genre_type,
    book.title,
    client_order.sum_to_pay,
    client_order.quantity,
    client_order.payment_type,
    client_order.order_status,
    client_order.date_of_order,
    client_order.date_of_delivery
   FROM public.client_order,
    public.chosen,
    public.authority,
    public.edition,
    public.book
  WHERE (((client_order.order_status)::text <> ALL (ARRAY[('Отменён'::character varying)::text, ('В коризне'::character varying)::text])) AND (client_order.order_id = chosen.order_id) AND (chosen.edition_number = edition.edition_number) AND (edition.authority_id = authority.authority_id) AND (authority.edition_book = book.book_id));


ALTER TABLE public.sales OWNER TO postgres;

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
12	Ницше	Фридрих	1844-10-15	1900-08-25
18	Стивенс	Род	1961-08-20	\N
19	Диевский	Виктор	1949-04-28	\N
20	Феррейра	Владстон	1990-05-23	\N
21	Апполонский	Сергей	1981-03-13	\N
33	Дмитрий	Хаустов	1989-01-01	\N
34	Герман	Гессе	1877-07-02	1962-08-09
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
12	12	40
13	12	41
14	12	42
15	18	43
16	19	44
17	20	45
18	21	46
26	33	54
28	34	56
\.


--
-- Data for Name: book; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book (book_id, title, genre_type) FROM stdin;
19	Красный дракон	Детектив
20	Молчание ягнят	Детектив
21	Ганнибал	Детектив
22	Страдания юного Вертера	Роман
39	Антихрист	Философия
40	Так говорил Заратустра	Философия
41	По ту сторону добра и зла	Философия
42	Генеалогия морали	Философия
43	Алгоритмы. Теория и практическое применение	Программирование
44	Теоретическая механика	Научная литература
45	Теоретический минимум по Computer Science.	Программирование
46	Теоретические основы электротехники	Научная литература
54	Лекции по философии постмодерна	Философия
56	Степной волк	Роман
\.


--
-- Data for Name: book_shop; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_shop (shop_id, name_of_shop, number_of_employees, post_code, country, city, street, manager) FROM stdin;
1	BigBook shop # 1	6	79007	Украина	Львов	ул. Андрея Головко, 1	9
2	BigBook shop # 2	5	65125	Украина	Одесса	ул. Мельницкая, 13	13
3	BigBook shop # 3	5	65125	Украина	Одесса	ул. Довженко, 3	17
5	BigBook shop # 5	5	4050	Украина	Киев	ул. Владимирская	25
4	BigBook shop # 4	5	4050	Украина	Киев	ул. Крещатик	70
\.


--
-- Data for Name: chosen; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chosen (chosen_id, edition_number, order_id) FROM stdin;
38	9	44
39	7	45
40	10	46
41	11	47
42	20	48
43	19	49
44	18	50
45	16	51
46	9	52
47	10	53
48	9	54
49	15	55
50	11	56
51	11	57
52	14	58
53	20	59
54	19	60
55	18	61
56	18	62
58	14	64
59	19	65
60	17	66
61	9	67
70	9	76
71	9	77
77	9	83
78	11	84
79	9	85
80	9	86
81	10	87
82	8	88
83	9	89
84	7	90
85	17	91
86	18	92
87	10	93
88	8	94
89	7	95
90	8	96
91	9	97
92	10	98
93	10	99
94	11	100
95	14	101
96	20	102
97	19	103
98	18	104
99	17	105
100	16	106
101	8	107
102	8	108
103	9	109
104	10	110
105	11	111
106	20	112
107	19	113
108	18	114
109	17	115
110	16	116
111	7	117
112	8	118
113	9	119
114	10	120
115	11	121
116	14	122
117	18	123
118	19	124
119	20	125
120	7	126
121	8	127
122	9	128
123	9	129
124	10	130
125	11	131
126	14	132
127	18	133
128	19	134
129	20	135
130	20	136
131	19	137
132	18	138
133	17	139
134	16	140
135	15	141
136	10	142
137	9	143
138	8	144
139	7	145
140	11	146
141	7	147
142	26	148
143	7	149
144	26	150
145	7	151
146	8	152
147	11	153
148	26	154
149	26	155
150	14	156
151	15	157
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (client_id, client_firstname, client_lastname, phone_number, email, client_login, delivery_address) FROM stdin;
40	Волощук	Епифан	+380876678123	epifanvol@gmail.com	EpifanVoloshtuk520	123007 г. Ярославское, ул. Полевая Нижняя, дом 38, квартира 597
35	Андрей	Семёнов	+380976567877	semenovAndrei@gmail.com	SemenovAndrei1982	618155, г. Железнодорожный, ул. Нансена проезд, дом 18, квартира 606
36	Островская	Виктория	+380786678543	ostrovskaya189@gmail.com	OstrovskayaVictorija	446677, г. Гаврилов-ям, ул. Воронцовский пер, дом 97, квартира 617
38	Рубенцова	Лариса	+380786555543	rubenstova@gmail.com	LarisaRubentsova882	216472, г. Усть-Ишим, ул. Инская, дом 176, квартира 242
106	Account	Deleted	+380000000000	dummy_client@gmail.com	DeletedAccount	-
95	Александр	Петров	+380999599999	asd@gmail.com	test_login	test_address
\.


--
-- Data for Name: client_order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_order (order_id, sender, reciever, delivery_address, order_status, sum_to_pay, payment_type, quantity, date_of_return, additional_info, date_of_order, date_of_delivery) FROM stdin;
55	11	95	-	Отменён	450.00	Наличные	1	2022-07-19 23:58:53	-	2022-07-19 23:58:49	\N
56	15	95	-	Отменён	150.00	Наличные	1	2022-07-19 23:58:55	-	2022-07-19 23:58:50	\N
54	19	95	-	Отменён	650.00	Наличные	1	2022-07-19 23:58:57	-	2022-07-19 23:58:47	\N
58	11	95	-	Отменён	750.00	Наличные	1	2022-07-20 00:04:23	-	2022-07-20 00:04:16	\N
59	19	95	-	Отменён	570.00	Наличные	1	2022-07-20 00:04:25	-	2022-07-20 00:04:18	\N
61	11	95	-	Отменён	650.00	Наличные	1	2022-07-20 00:04:28	-	2022-07-20 00:04:20	\N
57	15	95	-	Отменён	150.00	Наличные	1	2022-07-20 00:04:30	-	2022-07-20 00:04:15	\N
48	19	95	test_address	Оплачен	1710.00	Наличные	3	\N	Test review!	2022-06-19 21:52:12	\N
52	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-05-19 21:52:21	\N
67	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-07-20 15:24:44	\N
44	19	95	test_address	Оплачен	3250.00	Наличные	5	\N	Good deal	2022-07-19 17:00:42	\N
72	19	95	test_address	Отменён	6500.00	Наличные	10	2022-07-23 23:28:07	Buying 10 at a time!	2022-07-23 23:22:29	\N
76	19	95	-	Отменён	650.00	Наличные	1	2022-07-24 02:04:00	-	2022-07-24 02:03:50	\N
77	19	95	-	Отменён	650.00	Наличные	1	2022-07-24 02:04:01	-	2022-07-24 02:03:57	\N
83	19	95	test_address	Оплачен	3250.00	Карта	5	\N	!@#	2022-07-24 02:30:12	\N
94	15	95	-	Отменён	375.00	Наличные	1	2022-07-30 23:15:19	-	2022-07-30 23:15:16	\N
64	11	95	test_address	Доставлен	9000.00	Наличные	12	\N	Thank you for books.	2022-07-20 12:44:12	2022-08-01 22:09:10
51	11	95	-	Доставлен	150.00	Наличные	1	\N	-	2022-07-19 21:52:20	2022-08-01 22:09:19
62	11	95	test_address	Доставлен	3250.00	Наличные	5	\N	-	2022-07-20 00:11:08	2022-08-01 22:15:00
60	11	95	-	Доставлен	1250.00	Наличные	1	\N	-	2022-07-20 00:04:19	2022-08-01 22:15:17
45	11	95	-	Отменён	500.00	Наличные	1	2022-07-31 10:40:28	-	2022-06-19 21:51:59	\N
122	11	95	-	Оплачен	750.00	Наличные	1	\N	-	2022-02-08 21:01:52	\N
124	11	95	-	Оплачен	1250.00	Наличные	1	\N	-	2022-05-08 21:01:59	\N
65	11	95	test_address	Доставлен	2500.00	Наличные	2	\N	A!	2022-07-20 12:49:21	2022-08-01 22:29:50
50	11	95	-	Доставлен	5850.00	Наличные	9	\N	-	2022-07-19 21:52:18	2022-08-01 22:30:56
121	15	95	-	Оплачен	150.00	Наличные	1	\N	-	2022-01-08 21:01:51	\N
93	15	95	-	Доставлен	450.00	Наличные	1	\N	-	2022-07-30 23:14:19	2022-08-07 12:56:16
85	19	95	test_address	Оплачен	1300.00	Карта	2	\N	-	2022-07-30 22:09:28	\N
86	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-07-30 22:18:27	\N
66	15	95	-	Доставлен	700.00	Наличные	1	\N	-	2022-07-20 12:52:47	2022-08-07 12:56:18
89	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-07-30 22:27:20	\N
91	15	95	-	Доставлен	700.00	Наличные	1	\N	-	2022-07-30 23:11:50	2022-08-07 12:56:19
105	15	95	-	Доставлен	700.00	Наличные	1	\N	-	2022-08-07 12:42:27	2022-08-07 12:56:21
47	15	95	-	Доставлен	150.00	Наличные	1	\N	-	2022-05-19 21:52:03	2022-08-07 12:56:22
84	15	95	test_address	Доставлен	300.00	Карта	2	\N	-	2022-07-30 22:08:31	2022-08-07 12:56:24
102	19	95	-	Оплачен	570.00	Наличные	1	\N	-	2022-08-07 12:42:20	\N
100	15	95	-	Доставлен	150.00	Наличные	1	\N	-	2022-08-07 12:42:16	2022-08-07 12:56:25
46	15	95	-	Доставлен	1800.00	Наличные	4	\N	-	2022-06-19 21:52:02	2022-08-07 12:56:31
53	15	95	-	Доставлен	450.00	Наличные	1	\N	-	2022-07-19 21:52:23	2022-08-07 12:56:32
87	15	95	-	Доставлен	450.00	Наличные	1	\N	-	2022-07-30 22:20:01	2022-08-07 12:56:33
90	11	95	-	Доставлен	500.00	Наличные	1	\N	-	2022-07-30 22:36:46	2022-08-07 12:45:12
101	11	95	-	Доставлен	750.00	Наличные	1	\N	-	2022-08-07 12:42:17	2022-08-07 12:45:14
106	11	95	-	Доставлен	150.00	Наличные	1	\N	-	2022-08-07 12:42:28	2022-08-07 12:45:18
92	11	95	test_address	Доставлен	650.00	Карта	1	\N	-	2022-07-30 23:12:58	2022-08-07 12:45:21
103	11	95	test_address	Доставлен	3750.00	Наличные	3	\N	-	2022-08-07 12:42:24	2022-08-07 12:45:22
49	11	95	-	Доставлен	1250.00	Наличные	1	\N	-	2022-07-19 21:52:14	2022-08-07 12:45:24
104	11	95	-	Доставлен	650.00	Наличные	1	\N	-	2022-08-07 12:42:25	2022-08-07 12:45:26
123	11	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-06-08 21:01:54	\N
88	15	95	-	Доставлен	375.00	Наличные	1	\N	-	2022-07-30 22:23:38	2022-08-07 12:56:12
99	15	95	-	Доставлен	450.00	Наличные	1	\N	-	2022-08-07 12:42:15	2022-08-07 12:56:14
108	15	95	-	Оплачен	1125.00	Наличные	3	\N	-	2022-08-08 21:01:30	\N
109	19	95	-	Оплачен	1950.00	Наличные	3	\N	-	2022-08-08 21:01:33	\N
110	15	95	-	Оплачен	1350.00	Наличные	3	\N	-	2022-08-08 21:01:35	\N
111	15	95	-	Оплачен	150.00	Наличные	1	\N	-	2022-08-08 21:01:38	\N
112	19	95	-	Оплачен	570.00	Наличные	1	\N	-	2022-08-08 21:01:39	\N
113	11	95	-	Обработан	1250.00	Наличные	1	\N	-	2022-08-08 21:01:40	\N
115	15	95	-	Оплачен	700.00	Наличные	1	\N	-	2022-08-08 21:01:43	\N
116	11	95	-	Оплачен	150.00	Наличные	1	\N	-	2022-08-08 21:01:44	\N
117	11	95	-	Оплачен	500.00	Наличные	1	\N	-	2022-08-08 21:01:47	\N
118	15	95	-	Оплачен	375.00	Наличные	1	\N	-	2022-08-08 21:01:48	\N
120	15	95	-	Оплачен	450.00	Наличные	1	\N	-	2022-08-08 21:01:50	\N
98	15	95	test_address	Доставлен	4050.00	Наличные	9	\N	-	2022-03-07 12:42:12	2022-08-07 12:56:15
107	15	95	-	Оплачен	1125.00	Наличные	3	\N	-	2022-08-08 21:01:28	\N
119	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-08-08 21:01:49	\N
141	11	95	-	Доставляется	450.00	Карта	1	\N	-	2022-03-08 21:02:24	\N
137	11	95	-	Обработан	1250.00	Наличные	1	\N	-	2022-03-08 21:02:16	\N
114	11	95	-	Доставляется	650.00	Наличные	1	\N	-	2022-06-08 21:01:42	\N
138	11	95	-	Доставлен	650.00	Карта	1	\N	-	2022-06-08 21:02:18	2022-08-18 21:48:36
140	11	95	-	Доставляется	150.00	Карта	1	\N	-	2022-03-08 21:02:22	\N
126	11	95	-	Оплачен	500.00	Наличные	1	\N	-	2022-06-13 21:02:02	\N
131	15	95	-	Оплачен	150.00	Наличные	1	\N	-	2022-01-08 21:02:08	\N
143	19	95	-	Оплачен	650.00	Карта	1	\N	-	2022-02-08 21:02:29	\N
134	11	95	-	Оплачен	1250.00	Наличные	1	\N	-	2022-04-08 21:02:12	\N
129	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-04-08 21:02:06	\N
95	11	95	test_address	Доставлен	2500.00	Карта	5	\N	-	2022-04-07 12:41:55	2022-08-07 12:45:07
97	19	95	test_address	Оплачен	4550.00	Наличные	7	\N	-	2022-05-07 12:42:06	\N
133	11	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-06-08 21:02:11	\N
136	19	95	-	Оплачен	570.00	Наличные	1	\N	-	2022-04-08 21:02:15	\N
142	15	95	-	Оплачен	450.00	Карта	1	\N	-	2022-02-08 21:02:27	\N
132	11	95	-	Оплачен	750.00	Наличные	1	\N	-	2022-06-08 21:02:10	\N
144	15	95	-	Оплачен	375.00	Карта	1	\N	-	2022-01-08 21:02:31	\N
135	19	95	-	Оплачен	570.00	Наличные	1	\N	-	2022-04-08 21:02:13	\N
139	15	95	-	Оплачен	700.00	Карта	1	\N	-	2022-04-08 21:02:20	\N
96	15	95	test_address	Доставлен	1125.00	Карта	3	\N	-	2022-07-07 12:42:00	2022-08-07 12:56:11
130	15	95	-	Оплачен	450.00	Наличные	1	\N	-	2022-07-08 21:02:07	\N
127	15	95	-	Оплачен	375.00	Наличные	1	\N	-	2022-03-08 21:02:03	\N
125	19	95	-	Оплачен	570.00	Наличные	1	\N	-	2022-04-08 21:02:00	\N
128	19	95	-	Оплачен	650.00	Наличные	1	\N	-	2022-02-08 21:02:04	\N
145	11	95	-	Обработан	500.00	Карта	1	\N	-	2022-01-08 21:02:33	\N
146	15	106	161450, г. Долгоруково, ул. Крутицкий Вал, дом 181, квартира 540	Доставлен	450.00	Карта	3	\N	nice price	2022-08-21 15:25:07	2022-08-21 15:26:31
147	11	106	-	Доставлен	500.00	Карта	1	\N	-	2022-08-24 22:39:44	2022-08-24 23:08:11
148	60	95	test_address	Доставлен	250.00	Карта	1	\N	My favorite book!	2022-08-29 16:44:30	2022-08-29 16:55:37
149	11	40	123007 г. Ярославское, ул. Полевая Нижняя, дом 38, квартира 597	Оплачен	1500.00	Карта	3	\N	-	2022-09-02 18:10:00	\N
150	56	40	123007 г. Ярославское, ул. Полевая Нижняя, дом 38, квартира 597	Оплачен	1000.00	Карта	4	\N	-	2022-09-02 18:10:08	\N
151	11	95	test_address	Оплачен	1500.00	Карта	3	\N	Would like to recieve as fast as possible	2022-09-11 17:45:42	\N
152	15	95	-	В корзине	375.00	Наличные	1	\N	-	2022-09-12 20:20:22	\N
153	15	95	-	В корзине	150.00	Наличные	1	\N	-	2022-09-12 20:20:24	\N
154	56	95	test_address	В корзине	750.00	Карта	3	\N	Waiting for it to be delivered asap!	2022-09-12 20:20:49	\N
155	56	95	-	В корзине	250.00	Наличные	1	\N	-	2022-09-12 21:29:58	\N
156	11	95	-	В корзине	750.00	Наличные	1	\N	-	2022-09-12 21:35:08	\N
157	11	95	-	В корзине	450.00	Наличные	1	\N	-	2022-09-12 21:35:10	\N
\.


--
-- Data for Name: client_review; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_review (review_id, review_date, review_by, review_about_book, review_about_shop, review_about_employee, review_text) FROM stdin;
12	2021-12-07 00:00:00	36	\N	3	\N	Отличный книжный магазин.
15	2022-06-25 23:01:20	38	\N	2	\N	Лучшее книжное заведение в Одессе.
71	2022-08-04 00:34:59	95	1	\N	\N	Bad book!
74	2022-08-04 20:39:16	95	1	\N	\N	!@#!@
10	2022-06-25 23:01:20	38	3	\N	\N	Достойное продолжение истории о докторе Ганнибале Лекторе.
59	2022-07-10 13:27:50	95	3	\N	\N	!@#
60	2022-07-12 12:08:15	95	4	\N	\N	!@#
61	2022-07-20 15:32:32	95	2	\N	\N	Good book.
78	2022-08-24 22:39:18	106	\N	1	\N	Good shop.
81	2022-08-25 12:54:13	95	\N	\N	10	Thank you for deliting my old account.
\.


--
-- Data for Name: edition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.edition (edition_number, authority_id, publishing_agency_id, concrete_shop, price, publishing_date, number_of_copies_in_shop, number_of_pages, binding_type, paper_quality) FROM stdin;
20	18	1	3	570.00	2008-03-03	26	850	Твёрдый	Офсетная
19	17	2	1	1250.00	2015-02-10	133	350	Мягкий	Для глубокой печати
17	15	2	2	700.00	2011-01-12	15	600	Твёрдый	Для глубокой печати
16	14	3	1	150.00	2018-12-22	95	145	Твёрдый	Типографическая
10	4	5	2	450.00	2019-03-23	2	289	Мягкий	Типографическая
9	3	4	3	650.00	2019-12-02	100	621	Твёрдый	Офсетная
18	16	3	1	650.00	2009-07-23	24	550	Мягкий	Типографическая
25	26	2	1	450.00	2012-01-01	250	300	Твёрдый	Для глубокой печати
7	1	1	1	500.00	2017-11-03	202	431	Твёрдый	Офсетная
8	2	3	2	375.00	2018-06-03	280	514	Мягкий	Офсетная
11	5	2	2	150.00	2019-10-14	34	137	Твёрдый	Для глубокой печати
26	28	3	4	250.00	2005-01-01	146	150	Мягкий	Офсетная
14	12	2	1	750.00	2013-02-13	34	331	Твёрдый	Офсетная
15	13	3	1	450.00	2015-06-23	247	255	Мягкий	Типографическая
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (employee_id, lastname, firstname, employee_position, salary, phone_number, email, employee_login, place_of_work) FROM stdin;
9	Екатерина	Макарчук	manager	15000.00	+380987767543	makarchk_ektr@gmail.com	ekaterina_makarchuck	1
13	Кожина	Эвелина	manager	15000.00	+380568885145	evakoj@gmail.com	evelinaKOJINA	2
10	Макаров	Даниил	admin	13500.00	+380345543123	makarov1984@gmail.com	makarov_daniiL	1
14	Кружина	Элеонора	admin	13500.00	+380568761239	krujinaeleonora@gmail.com	eleonora_kruj	2
26	Кропотов	Андрей	admin	13500.00	+380972391239	kropotov231@gmail.com	kropotovAndrei	5
11	Петров	Василий	shop_assistant	10000.00	+380988567765	petrovVas@gmail.com	petrov_vasilii	1
19	Кутузова	Анастасия	shop_assistant	10000.00	+380978343145	kutuzova1922@gmail.com	anastasijaKutuzova	3
27	Брежнев	Дмитрий	shop_assistant	10000.00	+380979886145	BrejnevDmitrii@gmail.com	BrejnewDmitro	5
45	test_lastname	test_firstname	admin	15000.00	+380977681111	123123@gmail.com	test_admin_role	4
56	dummy	shop_assistant_4	shop_assistant	0.00	+380111111114	dummy_sa_4@gmail.com	dummy_shop_assistant_4	4
57	dummy	shop_assistant_5	shop_assistant	0.00	+380111111115	dummy_sa_5@gmail.com	dummy_shop_assistant_5	5
60	Павлов	Алексей	shop_assistant	10000.00	+380765765765	pavlovAlexei@gmail.com	alexeipavlov	4
61	Дмитриев	Олег	director	20000.00	+380977681543	o_dmitriev@gmail.com	dmitriev_oleg	1
65	dummy	manager_1	manager	0.00	+380987654321	dummy_manager_1@gmail.com	dummy_manager_1	1
66	dummy	manager_2	manager	0.00	+380987654322	dummy_manager_2@gmail.com	dummy_manager_2	2
67	dummy	manager_3	manager	0.00	+380987654323	dummy_manager_3@gmail.com	dummy_manager_3	3
68	dummy	manager_4	manager	0.00	+380987654324	dummy_manager_4@gmail.com	dummy_manager_4	4
69	dummy	manager_5	manager	0.00	+380987654325	dummy_manager_5@gmail.com	dummy_manager_5	5
70	Кривицкая	Анастасия	manager	15000.00	+380175683111	akrivitskaya@gmail.com	anastasia_kr	4
18	Рыбакова	Мария	admin	13550.00	+380976761559	riBakovaMarija@gmail.com	ribakova_marija	3
15	Павлов	Сергей	shop_assistant	11320.00	+380777886145	PavlovSegei@gmail.com	PavlovSergei	2
25	Исаев	Никита	manager	15000.00	+380975587145	Issaev234@gmail.com	IsaevNikita	5
53	dummy	shop_assistant_1	shop_assistant	0.00	+380111111111	dummy_sa_1@gmail.com	dummy_shop_assistant_1	1
54	dummy	shop_assistant_2	shop_assistant	0.00	+380111111112	dummy_sa_2@gmail.com	dummy_shop_assistant_2	2
55	dummy	shop_assistant_3	shop_assistant	0.00	+380111111113	dummy_sa_3@gmail.com	dummy_shop_assistant_3	3
17	Егоров	Арнольд	manager	15500.00	+380978872111	ArnoldEgorov@gmail.com	arnoldEgorov	3
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
91	petrov_vasilii	shop_assistant	e9bada2d8fc138b493a3d1ff67c7aa7f51822ae61852db5863c8177853c47379
92	PavlovSergei	shop_assistant	dbba0cfa3f92557234167fcb94b838f370337449903cbc4b47fdd716c9b66d1c
93	anastasijaKutuzova	shop_assistant	58655ffd60781d26a3362b2744520c56a50bc60eaf74512bcb194bd5680752d1
101	SemenovAndrei1982	client	2dd1c28e5a791fb79326ecf45ef6a9393746d76d9faffbc80153b128acd0e4af
70	OstrovskayaVictorija	client	9d0ea08959e1c4fd5ce6531d768379bc102db383c87316ca7b1f73abfdf70239
71	LarisaRubentsova882	client	7d05e098c33ba199f900255245f7870deed7d1a71eb873b481df1db581403e67
73	EpifanVoloshtuk520	client	9a50447e3c467cd1184e6284ffa94f91384085eab2ac59b77fe3b2ab1fc486b1
76	ekaterina_makarchuck	manager	28698e64d6887829d90cf74036840f1b51fa65bea6a211c0861425e612406f2a
77	evelinaKOJINA	manager	4612feee9fa6bd671957fc1ac908aa985cdaa9aab9a04b9dc36731aa9a368b31
78	arnoldEgorov	manager	dd38c7b5f5ac35e960a533d673874649ee3c2cd1d8f8eb2e4c2f9bfe9b498c71
80	IsaevNikita	manager	60656c0b5388c93ecb4cbb2b3f0a5ce3dc7db550a656cf81eaa56be7dba28204
81	makarov_daniiL	admin	f1d80f8c48bd52c0b87e3a8055ad742259e4b72cf1883a4f9ec7287bdffa3c4c
82	eleonora_kruj	admin	fdf75ec0f9666081318e5797bd1b462392fdc7b825d2164fa5a849ef7c6faade
83	ribakova_marija	admin	21564debedb21a27333c6953e948d4f8162f0b3a6820b0f78ff21d715c0ee128
85	kropotovAndrei	admin	9191545e56b4fe700f8568538e3c8357c80c9942c5cae9d7c8e8d1646b997a9e
95	BrejnewDmitro	shop_assistant	031f506209091c377efa3a558e900ea7eaf954f8d95f6b900cf09b621b9615eb
146	test_login	client	10a6e6cc8311a3e2bcc09bf6c199adecd5dd59408c343e926b129c4914f3cb01
204	test_admin_role	admin	96cae35ce8a9b0244178bf28e4966c2ce1b8385723a96a6b838858cdd6ca0a1e
205	DeletedAccount	client	146512fc46367d414ad21a0e1efc8bbd798a975f12b8384510f2d1ad5d8c299c
207	dummy_shop_assistant_1	shop_assistant	5b8f32acb2267dc3f8628bbaee2058ac54d683841bf291d4638d38e16deca7aa
208	dummy_shop_assistant_2	shop_assistant	e467f82e14b9f5e63ac382c9526f276e54956d1635cf3826416c07dd11445690
209	dummy_shop_assistant_3	shop_assistant	622fa8b01d00748dea06aa4cba17820fc808984186157aa0e8393fb253dbabfe
210	dummy_shop_assistant_4	shop_assistant	c3c55c871a6da4e0d7bb4a2263862a4ffa4fbd3c6588b0b8e32b1a495ebd4144
211	dummy_shop_assistant_5	shop_assistant	fd5223eff6cb34ba47c340627fdbe62c186d367ac7d4fb0b7991e7621db63b37
214	alexeipavlov	shop_assistant	15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225
215	dmitriev_oleg	director	932f3c1b56257ce8539ac269d7aab42550dacf8818d075f0bdf1990562aae3ef
217	dummy_manager_1	manager	23c0df49324695419e8e1c85c98e3f9804c22dfae212a8a7fd75def5049dd036
218	dummy_manager_2	manager	36493c27847dae409c1a319f1745d3d8406754aeb409f162e5dbf6230c2d1703
219	dummy_manager_3	manager	99a4657f0da85693cc4ac95fef1b76768299409ab580dcb79788fea3654f6f2d
220	dummy_manager_4	manager	885f0cc3af2f641b98442d89b89dac6a4c35ffaa311479599f63506e9f5cc9b2
221	dummy_manager_5	manager	e9e5666e9881c36894f3d3a7e0fef061b7f83229b1296287af3205c52c7dea8e
222	anastasia_kr	manager	5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5
\.


--
-- Name: author_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.author_author_id_seq', 34, true);


--
-- Name: authority_authority_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.authority_authority_id_seq', 28, true);


--
-- Name: book_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_book_id_seq', 56, true);


--
-- Name: book_shop_shop_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_shop_shop_id_seq', 5, true);


--
-- Name: chosen_chosen_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chosen_chosen_id_seq', 151, true);


--
-- Name: client_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_client_id_seq', 106, true);


--
-- Name: client_order_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_order_order_id_seq', 157, true);


--
-- Name: client_review_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_review_review_id_seq', 82, true);


--
-- Name: edition_edition_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.edition_edition_number_seq', 26, true);


--
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_employee_id_seq', 70, true);


--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publishing_agency_publishing_agency_id_seq', 5, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 222, true);


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
-- Name: users hash_users_password_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER hash_users_password_trigger BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.hash_password();


--
-- Name: chosen reduce_available_books_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER reduce_available_books_trigger AFTER INSERT ON public.chosen FOR EACH ROW EXECUTE FUNCTION public.reduce_available_books();


--
-- Name: client_order return_ordered_books_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER return_ordered_books_trigger AFTER UPDATE ON public.client_order FOR EACH ROW WHEN (((new.order_status)::text = 'Отменён'::text)) EXECUTE FUNCTION public.return_ordered_books();


--
-- Name: employee update_number_of_employees_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_number_of_employees_trigger AFTER INSERT OR DELETE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.update_number_of_employees();


--
-- Name: client update_users_with_client; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_with_client AFTER UPDATE ON public.client FOR EACH ROW EXECUTE FUNCTION public.update_users_table();


--
-- Name: employee update_users_with_employee; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_with_employee AFTER UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.update_users_table();


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
-- Name: book_shop fk_book_shop_manager; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_shop
    ADD CONSTRAINT fk_book_shop_manager FOREIGN KEY (manager) REFERENCES public.employee(employee_id);


--
-- Name: client_review fk_review_about_employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review
    ADD CONSTRAINT fk_review_about_employee FOREIGN KEY (review_about_employee) REFERENCES public.employee(employee_id);


--
-- Name: client_review fk_review_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_review
    ADD CONSTRAINT fk_review_by FOREIGN KEY (review_by) REFERENCES public.client(client_id);


--
-- Name: edition publishing_agency_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edition
    ADD CONSTRAINT publishing_agency_fk FOREIGN KEY (publishing_agency_id) REFERENCES public.publishing_agency(publishing_agency_id);


--
-- Name: employee work_where; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT work_where FOREIGN KEY (place_of_work) REFERENCES public.book_shop(shop_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO user_admin;
GRANT USAGE ON SCHEMA public TO user_client;
GRANT USAGE ON SCHEMA public TO user_manager;
GRANT USAGE ON SCHEMA public TO user_shop_assistant;
GRANT USAGE ON SCHEMA public TO user_checker;
GRANT USAGE ON SCHEMA public TO user_director;


--
-- Name: FUNCTION add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date) TO user_manager;
GRANT ALL ON FUNCTION public.add_author(lastname_ character varying, firstname_ character varying, dob_ date, dod_ date) TO user_admin;


--
-- Name: FUNCTION add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying) TO user_manager;
GRANT ALL ON FUNCTION public.add_edition(manager_pow integer, book_title_ character varying, book_genre_type character varying, book_author_id integer, publishing_agency_ character varying, price_ numeric, publishing_date_ date, available_copies_ integer, pages_ integer, binding_type_ character varying, paper_quality_ character varying) TO user_admin;


--
-- Name: FUNCTION add_employee_review(user_login character varying, employee_id integer, user_review_text text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_employee_review(user_login character varying, employee_id integer, user_review_text text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_employee_review(user_login character varying, employee_id integer, user_review_text text) TO user_client;
GRANT ALL ON FUNCTION public.add_employee_review(user_login character varying, employee_id integer, user_review_text text) TO user_admin;


--
-- Name: FUNCTION add_order(book_title_ character varying, date_of_publishing_ date, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) TO user_admin;


--
-- Name: FUNCTION add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) TO user_client;
GRANT ALL ON FUNCTION public.add_order(book_title_ character varying, date_of_publishing_ date, ordering_date timestamp without time zone, shop_number integer, cli_login_ character varying, delivery_address_ character varying, order_status_ character varying, sum_to_pay_ numeric, payment_type_ character varying, additional_info_ character varying, quantity_ integer) TO user_admin;


--
-- Name: FUNCTION add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text) TO user_client;
GRANT ALL ON FUNCTION public.add_shop_review(user_login_ character varying, shop_id_ integer, user_review_text_ text) TO user_admin;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO user_admin;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO user_admin;


--
-- Name: FUNCTION available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric) TO user_client;
GRANT ALL ON FUNCTION public.available_books_main_info(author_name character varying, book_title character varying, book_genre character varying, min_price numeric, max_price numeric) TO user_admin;


--
-- Name: FUNCTION change_employee_salary(id integer, new_salary numeric); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.change_employee_salary(id integer, new_salary numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.change_employee_salary(id integer, new_salary numeric) TO user_director;
GRANT ALL ON FUNCTION public.change_employee_salary(id integer, new_salary numeric) TO user_admin;


--
-- Name: FUNCTION change_password(login character varying, old_password character varying, new_password character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.change_password(login character varying, old_password character varying, new_password character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.change_password(login character varying, old_password character varying, new_password character varying) TO user_client;
GRANT ALL ON FUNCTION public.change_password(login character varying, old_password character varying, new_password character varying) TO user_admin;


--
-- Name: FUNCTION client_activity(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.client_activity() FROM PUBLIC;
GRANT ALL ON FUNCTION public.client_activity() TO user_admin;


--
-- Name: FUNCTION concrete_book_full_info(book_title character varying, publ_date date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) TO user_client;
GRANT ALL ON FUNCTION public.concrete_book_full_info(book_title character varying, publ_date date) TO user_admin;


--
-- Name: FUNCTION create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) TO user_client;
GRANT ALL ON FUNCTION public.create_client(client_firstname_ character varying, client_lastname_ character varying, phone_number_ character varying, email_ character varying, client_login_ character varying, client_password_ character varying, delivery_address_ character varying) TO user_admin;


--
-- Name: FUNCTION create_employee(employee_lastname_ character varying, employee_firstname_ character varying, employee_position_ character varying, employee_salary_ numeric, employee_phone_num_ character varying, employee_email_ character varying, employee_login_ character varying, employee_password_ character varying, employee_place_of_work integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_employee(employee_lastname_ character varying, employee_firstname_ character varying, employee_position_ character varying, employee_salary_ numeric, employee_phone_num_ character varying, employee_email_ character varying, employee_login_ character varying, employee_password_ character varying, employee_place_of_work integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_employee(employee_lastname_ character varying, employee_firstname_ character varying, employee_position_ character varying, employee_salary_ numeric, employee_phone_num_ character varying, employee_email_ character varying, employee_login_ character varying, employee_password_ character varying, employee_place_of_work integer) TO user_admin;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO user_admin;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO user_admin;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION delete_author(author_id_ integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_author(author_id_ integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_author(author_id_ integer) TO user_manager;
GRANT ALL ON FUNCTION public.delete_author(author_id_ integer) TO user_admin;


--
-- Name: FUNCTION delete_client(id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_client(id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_client(id integer) TO user_admin;


--
-- Name: FUNCTION delete_edition(edition_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_edition(edition_id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_edition(edition_id integer) TO user_manager;
GRANT ALL ON FUNCTION public.delete_edition(edition_id integer) TO user_admin;


--
-- Name: FUNCTION delete_employee(id integer, pos character varying, pow integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_employee(id integer, pos character varying, pow integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_employee(id integer, pos character varying, pow integer) TO user_admin;


--
-- Name: FUNCTION delete_review(id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_review(id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_review(id integer) TO user_client;
GRANT ALL ON FUNCTION public.delete_review(id integer) TO user_shop_assistant;
GRANT ALL ON FUNCTION public.delete_review(id integer) TO user_admin;


--
-- Name: FUNCTION delete_user(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_user() TO user_client;
GRANT ALL ON FUNCTION public.delete_user() TO user_admin;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO user_admin;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO user_admin;


--
-- Name: FUNCTION employee_activity(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.employee_activity() FROM PUBLIC;
GRANT ALL ON FUNCTION public.employee_activity() TO user_admin;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO user_admin;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO user_admin;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO user_admin;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO user_admin;


--
-- Name: FUNCTION get_authors(author_name character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_authors(author_name character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_authors(author_name character varying) TO user_manager;
GRANT ALL ON FUNCTION public.get_authors(author_name character varying) TO user_admin;


--
-- Name: FUNCTION get_book_reviews(book_title_ character varying, book_publishing_date_ date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) TO user_client;
GRANT ALL ON FUNCTION public.get_book_reviews(book_title_ character varying, book_publishing_date_ date) TO user_admin;


--
-- Name: FUNCTION get_cli_orders_statuses(client_login_ character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_cli_orders_statuses(client_login_ character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_cli_orders_statuses(client_login_ character varying) TO user_client;


--
-- Name: FUNCTION get_client_info(client_login_ character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_client_info(client_login_ character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_client_info(client_login_ character varying) TO user_client;
GRANT ALL ON FUNCTION public.get_client_info(client_login_ character varying) TO user_admin;


--
-- Name: FUNCTION get_client_orders(login character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_client_orders(login character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_client_orders(login character varying) TO user_client;
GRANT ALL ON FUNCTION public.get_client_orders(login character varying) TO user_admin;


--
-- Name: FUNCTION get_client_sales_by_genre(client_login_ character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_client_sales_by_genre(client_login_ character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_client_sales_by_genre(client_login_ character varying) TO user_client;


--
-- Name: FUNCTION get_employee_info(shop_num integer, pos character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_employee_info(shop_num integer, pos character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_employee_info(shop_num integer, pos character varying) TO user_client;
GRANT ALL ON FUNCTION public.get_employee_info(shop_num integer, pos character varying) TO user_admin;


--
-- Name: FUNCTION get_employee_main_data(login character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_employee_main_data(login character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_employee_main_data(login character varying) TO user_manager;
GRANT ALL ON FUNCTION public.get_employee_main_data(login character varying) TO user_director;
GRANT ALL ON FUNCTION public.get_employee_main_data(login character varying) TO user_admin;


--
-- Name: FUNCTION get_employees_salary(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_employees_salary() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_employees_salary() TO user_director;
GRANT ALL ON FUNCTION public.get_employees_salary() TO user_admin;


--
-- Name: FUNCTION get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone) TO user_manager;
GRANT ALL ON FUNCTION public.get_genre_sales(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone) TO user_admin;


--
-- Name: FUNCTION get_min_max_book_prices(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_min_max_book_prices() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_min_max_book_prices() TO user_client;
GRANT ALL ON FUNCTION public.get_min_max_book_prices() TO user_admin;


--
-- Name: FUNCTION get_number_of_books(manager_pow integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_number_of_books(manager_pow integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_number_of_books(manager_pow integer) TO user_manager;
GRANT ALL ON FUNCTION public.get_number_of_books(manager_pow integer) TO user_admin;


--
-- Name: FUNCTION get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) TO user_manager;
GRANT ALL ON FUNCTION public.get_order_statuses_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) TO user_admin;


--
-- Name: FUNCTION get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) TO user_manager;
GRANT ALL ON FUNCTION public.get_payment_types_count(manager_pow integer, l_date timestamp without time zone, r_date timestamp without time zone) TO user_admin;


--
-- Name: FUNCTION get_publishing_agencies(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_publishing_agencies() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_publishing_agencies() TO user_manager;
GRANT ALL ON FUNCTION public.get_publishing_agencies() TO user_admin;


--
-- Name: FUNCTION get_reviews_about_employee(employee_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_reviews_about_employee(employee_id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_reviews_about_employee(employee_id integer) TO user_client;
GRANT ALL ON FUNCTION public.get_reviews_about_employee(employee_id integer) TO user_admin;


--
-- Name: FUNCTION get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying) TO user_shop_assistant;
GRANT ALL ON FUNCTION public.get_reviews_for_shop_assistant(sa_login character varying, reviews_about character varying) TO user_admin;


--
-- Name: FUNCTION get_sales_by_date(manager_pow integer, trunc_by character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_sales_by_date(manager_pow integer, trunc_by character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_sales_by_date(manager_pow integer, trunc_by character varying) TO user_manager;
GRANT ALL ON FUNCTION public.get_sales_by_date(manager_pow integer, trunc_by character varying) TO user_admin;


--
-- Name: FUNCTION get_shop_assistant_orders(sa_login character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_shop_assistant_orders(sa_login character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_shop_assistant_orders(sa_login character varying) TO user_shop_assistant;
GRANT ALL ON FUNCTION public.get_shop_assistant_orders(sa_login character varying) TO user_admin;


--
-- Name: FUNCTION get_shop_info(shop_num integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_shop_info(shop_num integer) TO user_admin;


--
-- Name: FUNCTION get_shop_reviews(shop_num integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_shop_reviews(shop_num integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_shop_reviews(shop_num integer) TO user_client;
GRANT ALL ON FUNCTION public.get_shop_reviews(shop_num integer) TO user_admin;


--
-- Name: FUNCTION get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer) TO user_manager;
GRANT ALL ON FUNCTION public.get_top_selling_books(manager_pow integer, l_time timestamp without time zone, r_time timestamp without time zone, n_top integer) TO user_admin;


--
-- Name: FUNCTION hash_password(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hash_password() TO user_admin;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO user_admin;


--
-- Name: FUNCTION insert_user_book_review(user_login character varying, book_title character varying, user_review_text text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, user_review_text text) TO user_admin;


--
-- Name: FUNCTION insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) TO user_client;
GRANT ALL ON FUNCTION public.insert_user_book_review(user_login character varying, book_title character varying, book_publishing_date date, user_review_text text) TO user_admin;


--
-- Name: FUNCTION not_sold_books(manager_pow integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.not_sold_books(manager_pow integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.not_sold_books(manager_pow integer) TO user_manager;
GRANT ALL ON FUNCTION public.not_sold_books(manager_pow integer) TO user_admin;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO user_admin;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO user_admin;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO user_admin;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO user_admin;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO user_admin;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO user_admin;


--
-- Name: FUNCTION quantity_of_books_checker(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.quantity_of_books_checker() TO user_admin;


--
-- Name: FUNCTION reduce_available_books(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.reduce_available_books() FROM PUBLIC;
GRANT ALL ON FUNCTION public.reduce_available_books() TO user_client;
GRANT ALL ON FUNCTION public.reduce_available_books() TO user_admin;


--
-- Name: FUNCTION return_ordered_books(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.return_ordered_books() FROM PUBLIC;
GRANT ALL ON FUNCTION public.return_ordered_books() TO user_client;
GRANT ALL ON FUNCTION public.return_ordered_books() TO user_admin;


--
-- Name: FUNCTION update_client_info(login character varying, subject character varying, new_value character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_client_info(login character varying, subject character varying, new_value character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_client_info(login character varying, subject character varying, new_value character varying) TO user_client;
GRANT ALL ON FUNCTION public.update_client_info(login character varying, subject character varying, new_value character varying) TO user_admin;


--
-- Name: FUNCTION update_editions_number(edition_id integer, update_by integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_editions_number(edition_id integer, update_by integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_editions_number(edition_id integer, update_by integer) TO user_manager;
GRANT ALL ON FUNCTION public.update_editions_number(edition_id integer, update_by integer) TO user_admin;


--
-- Name: FUNCTION update_employee_data(update_subject character varying, data character varying, id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_employee_data(update_subject character varying, data character varying, id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_employee_data(update_subject character varying, data character varying, id integer) TO user_admin;


--
-- Name: FUNCTION update_number_of_employees(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_number_of_employees() TO user_admin;


--
-- Name: FUNCTION update_user_order(current_order_id integer, status character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_user_order(current_order_id integer, status character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_user_order(current_order_id integer, status character varying) TO user_client;
GRANT ALL ON FUNCTION public.update_user_order(current_order_id integer, status character varying) TO user_shop_assistant;
GRANT ALL ON FUNCTION public.update_user_order(current_order_id integer, status character varying) TO user_admin;


--
-- Name: FUNCTION update_users_table(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_users_table() FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_users_table() TO user_client;
GRANT ALL ON FUNCTION public.update_users_table() TO user_admin;


--
-- Name: FUNCTION verify_user(login character varying, password character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.verify_user(login character varying, password character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.verify_user(login character varying, password character varying) TO user_admin;
GRANT ALL ON FUNCTION public.verify_user(login character varying, password character varying) TO user_checker;


--
-- Name: TABLE author; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.author TO user_admin;


--
-- Name: TABLE authority; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.authority TO user_admin;


--
-- Name: TABLE book; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.book TO user_admin;


--
-- Name: TABLE edition; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.edition TO user_admin;


--
-- Name: TABLE publishing_agency; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.publishing_agency TO user_admin;


--
-- Name: TABLE available_books_view; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.available_books_view TO user_client;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.available_books_view TO user_admin;


--
-- Name: TABLE client; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.client TO user_checker;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.client TO user_admin;


--
-- Name: TABLE client_review; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.client_review TO user_admin;


--
-- Name: TABLE book_reviews; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.book_reviews TO user_admin;


--
-- Name: TABLE book_shop; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.book_shop TO user_admin;


--
-- Name: TABLE chosen; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chosen TO user_admin;


--
-- Name: SEQUENCE client_client_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.client_client_id_seq TO user_client;


--
-- Name: TABLE client_order; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.client_order TO user_admin;


--
-- Name: SEQUENCE client_review_review_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.client_review_review_id_seq TO user_client;


--
-- Name: TABLE employee; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.employee TO user_checker;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.employee TO user_admin;


--
-- Name: TABLE sales; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sales TO user_admin;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO user_checker;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.users TO user_admin;


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

