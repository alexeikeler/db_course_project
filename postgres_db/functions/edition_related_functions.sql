------------------------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------

DROP FUNCTION delete_edition(edition_id integer);
CREATE OR REPLACE FUNCTION delete_edition(edition_id integer)
RETURNS VOID AS
    $$
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
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    delete_edition(edition_id integer)FROM public;

GRANT EXECUTE ON FUNCTION
    delete_edition(edition_id integer) TO user_manager;
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_editions_number(edition_id integer, update_by integer)
RETURNS VOID AS
    $$
        BEGIN
            UPDATE edition
            SET number_of_copies_in_shop = number_of_copies_in_shop + update_by
            WHERE edition_number = edition_id;
        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    update_editions_number(edition_id integer, update_by integer) FROM public;

GRANT EXECUTE ON FUNCTION
    update_editions_number(edition_id integer, update_by integer) TO user_manager;

------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------
