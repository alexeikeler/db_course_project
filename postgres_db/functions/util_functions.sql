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
--Function to delete author
-----------------------------------------------------------------------
DROP FUNCTION delete_author(author_id_ integer);
CREATE OR REPLACE FUNCTION delete_author(author_id_ integer)
RETURNS TABLE (id integer) AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    delete_author(author_id integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    delete_author(author_id integer) TO user_manager;

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
