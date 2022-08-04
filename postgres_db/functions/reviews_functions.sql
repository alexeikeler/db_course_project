-----------------------------------------------------------------------------------------------------
-- All reviews about concrete book
-----------------------------------------------------------------------------------------------------
DROP FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date);
CREATE OR REPLACE FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date)
    RETURNS TABLE(
        review_id_ integer,
        review_by_ varchar,
        review_date_ timestamp(0),
        review_ text
    )  AS
    $$
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

$$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date) FROM public;

GRANT EXECUTE ON FUNCTION get_book_reviews(book_title_ varchar, book_publishing_date_ date) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function for adding new review about book
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
      VALUES (CURRENT_TIMESTAMP, user_id, book_id, user_review_text);

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
--Function for getting reviews about concrete employee
-----------------------------------------------------------------------------------------------------
DROP FUNCTION get_reviews_about_employee(employee_id integer);
CREATE OR REPLACE FUNCTION get_reviews_about_employee(employee_id integer)
RETURNS TABLE (
    review_id_ integer,
    review_by_ varchar,
    review_date_ timestamp(0),
    review_text_ text
) AS
    $$
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
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_reviews_about_employee(employee_id integer) FROM public;
GRANT EXECUTE ON FUNCTION get_reviews_about_employee(employee_id integer)TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
-- Function for adding review about employee
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_employee_review(user_login varchar, employee_id integer, user_review_text text)
RETURNS VOID AS
    $$
    DECLARE
        user_id integer;

        BEGIN
            SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login;

            INSERT INTO
                client_review(review_date, review_by, review_about_employee, review_text)
            VALUES
                (CURRENT_TIMESTAMP, user_id, employee_id, user_review_text);
        END;
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION add_employee_review(
    user_login varchar,
    employee_id integer,
    review_text text) FROM public;

GRANT EXECUTE ON FUNCTION add_employee_review(
    user_login varchar,
    employee_id integer,
    review_text text) TO user_client;
-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function for getting reviews about particular shop
-----------------------------------------------------------------------------------------------------
DROP FUNCTION get_shop_reviews(shop_num integer);
CREATE OR REPLACE FUNCTION get_shop_reviews(shop_num integer)
RETURNS TABLE (
review_id_ integer,
review_by_ varchar,
review_date_ timestamp(0),
review_text_ text
)
    AS
    $$
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
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_shop_reviews(shop_num integer) FROM public;

GRANT EXECUTE ON FUNCTION get_shop_reviews(shop_num integer) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Function to add review about particular shop
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_shop_review(
user_login_ varchar,
shop_id_ integer,
user_review_text_ text
)
    RETURNS VOID AS
    $$
        DECLARE
            user_id integer;

        BEGIN
            SELECT client.client_id INTO user_id FROM client WHERE client.client_login = user_login_;

            INSERT INTO
                client_review(review_date, review_by, review_about_shop, review_text)
            VALUES
                (CURRENT_TIMESTAMP, user_id, shop_id_, user_review_text_);
        END;
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION add_shop_review(
user_login_ varchar,
shop_id_ integer,
user_review_text_ text
) FROM public;

GRANT EXECUTE ON FUNCTION add_shop_review(
user_login_ varchar,
shop_id_ integer,
user_review_text_ text
) TO user_client;

-----------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION delete_review(id integer)
RETURNS VOID AS
    $$
        BEGIN
            DELETE FROM client_review WHERE review_id = id;
        END;
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION delete_review(id integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION delete_review(id integer) TO user_client, user_shop_assistant;


-----------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------------
-- Function to get all reviews related to shop assistant place of work

DROP FUNCTION get_reviews_for_shop_assistant(sa_login varchar, reviews_about varchar);
CREATE OR REPLACE FUNCTION get_reviews_for_shop_assistant(sa_login varchar, reviews_about varchar)
RETURNS TABLE(
    review_id_ integer,
    review_date_ timestamp(0),
    review_by_ varchar,
    review_about_ varchar,
    review_text_ text
             )
    AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_reviews_for_shop_assistant(sa_login varchar, reviews_about varchar) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    get_reviews_for_shop_assistant(sa_login varchar, reviews_about varchar) TO user_shop_assistant;

-----------------------------------------------------------------------------------------------------