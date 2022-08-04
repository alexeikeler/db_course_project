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
