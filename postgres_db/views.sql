-----------------------------------------------------------------------
CREATE OR REPLACE VIEW book_reviews AS
    SELECT
        client_review.review_id AS review_id,
        client.client_login AS user_login,
        book.title AS review_about_book,
        edition.publishing_date AS book_pubslishing_date,
        client_review.review_date AS review_date,
        client_review.review_text AS review
        FROM
            client_review, client, edition, authority, book
        WHERE
            client_review.review_about_book is not null
        AND
            client_review.review_about_book = edition.authority_id
        AND
           client.client_id = client_review.review_by
        AND
            edition.authority_id = authority.authority_id
        AND
            authority.edition_book = book.book_id;
-----------------------------------------------------------------------

-----------------------------------------------------------------------
CREATE OR REPLACE VIEW available_books_view AS
    SELECT
        CAST(author.firstname ||' '|| author.lastname AS varchar) author,
        book.title AS title,
        book.genre_type AS genre,
        edition.price AS price,
        edition.number_of_copies_in_shop AS available_amount,
        edition.concrete_shop AS shop,
        edition.binding_type AS binding_type,
        edition.number_of_pages AS number_of_pages,
        edition.publishing_date AS publishing_date,
        publishing_agency_name AS publising_agency_name,
        edition.paper_quality AS paper_quality
    FROM
        edition, authority, book, author, publishing_agency
    WHERE
        edition.authority_id = authority.authority_id
    AND
        authority.edition_author = author.author_id
    AND
        authority.edition_book = book.book_id
    AND
        edition.publishing_agency_id = publishing_agency.publishing_agency_id;

-----------------------------------------------------------------------