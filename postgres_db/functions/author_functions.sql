-----------------------------------------------------------------------
DROP FUNCTION add_author(lastname_ varchar, firstname_ varchar, dob_ date, dod_ date);
CREATE OR REPLACE FUNCTION
    add_author(lastname_ varchar, firstname_ varchar, dob_ date, dod_ date DEFAULT NULL)
RETURNS INTEGER AS
    $$
        DECLARE ret_author_id integer;

        BEGIN
            INSERT INTO
                author(lastname, firstname, date_of_birth, date_of_death)
            VALUES
                (lastname_, firstname_, dob_, dod_)
            RETURNING author.author_id INTO ret_author_id;
            RETURN ret_author_id;
        END;
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    add_author(lastname_ varchar, firstname_ varchar, dob_ date, dod_ date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    add_author(lastname_ varchar, firstname_ varchar, dob_ date, dod_ date) TO user_manager;
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