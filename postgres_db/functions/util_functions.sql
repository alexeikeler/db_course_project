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


-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_publishing_agencies()
RETURNS TABLE (agency_name varchar) AS
    $$
        BEGIN
            RETURN QUERY
            SELECT publishing_agency_name FROM publishing_agency;
        END;
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_publishing_agencies() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    get_publishing_agencies() TO user_manager;
-----------------------------------------------------------------------


-----------------------------------------------------------------------
DROP FUNCTION not_sold_books(manager_pow integer);
CREATE OR REPLACE FUNCTION not_sold_books(manager_pow integer)
RETURNS TABLE (
    id integer,
    author_name varchar,
    book_title varchar
              )
AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    not_sold_books(manager_pow integer) FROM public;
GRANT EXECUTE ON FUNCTION
    not_sold_books(manager_pow integer) TO user_manager;
-----------------------------------------------------------------------


-----------------------------------------------------------------------
DROP FUNCTION get_number_of_books(manager_id integer);
CREATE OR REPLACE FUNCTION get_number_of_books(manager_pow integer)
RETURNS TABLE (
                edition_id integer,
                author varchar,
                title varchar,
                available int2
              )
AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_number_of_books(manager_pow integer) FROM public;

GRANT EXECUTE ON FUNCTION
    get_number_of_books(manager_pow integer) TO user_manager;
-----------------------------------------------------------------------


-----------------------------------------------------------------------
DROP FUNCTION client_activity();
CREATE OR REPLACE FUNCTION client_activity()
RETURNS TABLE
(
    id integer,
    login varchar,
    oldest_order timestamp(0),
    newest_order timestamp(0)
) AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    client_activity() FROM public;

GRANT EXECUTE ON FUNCTION
    client_activity() TO user_admin;

-----------------------------------------------------------------------


-----------------------------------------------------------------------
DROP FUNCTION get_employees_salary();
CREATE OR REPLACE FUNCTION get_employees_salary()
RETURNS TABLE
    (
        empl_id integer,
        empl_name varchar,
        empl_pos varchar,
        empl_salary numeric(7, 2),
        empl_pow varchar
    ) AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_employees_salary() FROM public;
GRANT EXECUTE ON FUNCTION get_employees_salary() TO user_director;

-----------------------------------------------------------------------


-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION change_employee_salary(id integer, new_salary numeric(7, 2))
RETURNS BOOLEAN AS
    $$

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
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION change_employee_salary(id integer, new_salary numeric(7, 2)) FROM public;
GRANT EXECUTE ON FUNCTION change_employee_salary(id integer, new_salary numeric(7, 2)) TO user_director;

select * from book_shop;
-----------------------------------------------------------------------


-----------------------------------------------------------------------
DROP FUNCTION update_number_of_employees();
DROP TRIGGER update_number_of_employees_trigger ON employee;


CREATE TRIGGER update_number_of_employees_trigger
    AFTER INSERT OR DELETE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE update_number_of_employees();


CREATE OR REPLACE FUNCTION update_number_of_employees()
RETURNS TRIGGER AS
    $$
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
    $$
LANGUAGE plpgsql;
-----------------------------------------------------------------------