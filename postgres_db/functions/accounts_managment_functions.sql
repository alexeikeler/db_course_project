--------------------------------------------------------------------------------------
--Function for updating client password
--------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION change_client_password(login varchar, old_password varchar, new_password varchar)
RETURNS boolean AS
    $$

    BEGIN

        IF EXISTS(
            SELECT *
            FROM client
            WHERE
                client.client_login = login
            AND
                client.client_password = encode(digest(old_password, 'sha256'), 'hex')
            )
            THEN
                UPDATE client
                SET
                    client_password = new_password
                WHERE
                    client_login = login;
                RETURN TRUE;

        ELSE
            RAISE WARNING 'Wrong password!';
            RETURN FALSE;

        END IF;

    END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    change_client_password(login varchar, old_password varchar, new_password varchar)
    FROM public;

GRANT EXECUTE ON FUNCTION
    change_client_password(login varchar, old_password varchar, new_password varchar)
    TO user_client;

--------------------------------------------------------------------------------------