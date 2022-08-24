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

