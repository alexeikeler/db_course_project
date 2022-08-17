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
-----------------------------------------------------------------------


-----------------------------------------------------------------------
--Function to add new edition

CREATE OR REPLACE FUNCTION add_edition(
    manager_pow integer,
    book_title_ varchar,
    book_genre_type varchar,

    book_author_id integer,

    publishing_agency_ varchar,
    price_ numeric(7, 2),
    publishing_date_ date,
    available_copies_ integer,
    pages_ integer,
    binding_type_ varchar,
    paper_quality_ varchar
)
RETURNS INTEGER AS
    $$
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
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    add_edition(
    manager_pow integer,
    book_title_ varchar,
    book_genre_type varchar,

    book_author_id integer,

    publishing_agency_ varchar,
    price numeric(7, 2),
    publishing_date_ date,
    available_copies_ integer,
    pages_ integer,
    binding_type_ varchar,
    paper_quality_ varchar
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION
    add_edition(
    manager_pow integer,
    book_title_ varchar,
    book_genre_type varchar,

    book_author_id integer,

    publishing_agency_ varchar,
    price numeric(7, 2),
    publishing_date_ date,
    available_copies_ integer,
    pages_ integer,
    binding_type_ varchar,
    paper_quality_ varchar
)  TO user_manager;


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
