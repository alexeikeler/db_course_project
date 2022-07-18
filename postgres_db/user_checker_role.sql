-- User user_checker for checking if user who tries to connect exist
-------------------------------------------------------

CREATE USER user_checker WITH PASSWORD 'IqmKKJHTbT38';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_checker;
GRANT USAGE ON SCHEMA public TO user_checker;

-------------------------------------------------------

--Function to check if user exists in database, if so return his role
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION verify_user(login varchar, password varchar)
RETURNS TABLE (user_role varchar) AS
$$
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
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION verify_user(login varchar, password varchar) FROM public;
GRANT EXECUTE ON FUNCTION verify_user(login varchar, password varchar) TO user_checker;
---------------------------------------------------------------------------------------