--Function for updating password
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


------------------------------------------------------------------
--When client / employee account deleted delete it from users table
CREATE OR REPLACE FUNCTION delete_user()
RETURNS TRIGGER AS
    $$
    BEGIN
        IF (TG_TABLE_NAME = 'client')
        THEN

            DELETE FROM
                       users
                   WHERE
                       users.user_login = OLD.client_login
                    AND
                       users.user_password = OLD.client_password;
            RAISE INFO 'Deleted client %', OLD.client_login;

        ELSIF (TG_TABLE_NAME = 'employee')
            THEN
                DELETE FROM
                        users
                WHERE
                    users.user_login = OLD.employee_login
                AND
                    users.user_password = OLD.employee_password;
            RAISE INFO 'Deleted employee %', OLD.employee_login;

        END IF;

        RETURN NEW;
    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER delete_from_users
    AFTER DELETE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE delete_user();

CREATE TRIGGER delete_from_users
    AFTER DELETE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE delete_user();

REVOKE ALL ON FUNCTION
    delete_user()
    FROM public;

GRANT EXECUTE ON FUNCTION
    delete_user()
    TO user_client;
------------------------------------------------------------------

--Function and triggers for updating users table when new employee or client created
-----------------------------------------------
CREATE OR REPLACE FUNCTION update_users_table()
RETURNS trigger AS
$$
    BEGIN

        IF(TG_TABLE_NAME = 'client')
            THEN
                --when user changes only login
                IF NEW.client_login NOT LIKE OLD.client_login
                    THEN
                        RAISE INFO 'Updating user login from % to %', OLD.client_login, NEW.client_login;
                        UPDATE users
                        SET user_login = NEW.client_login
                        WHERE user_login = OLD.client_login;
                  ELSE
                    --when user changes password or new user has been created

                    INSERT INTO users(user_login, user_password, user_role)
                    VALUES (NEW."client_login", NEW."client_password", 'client')
                    ON CONFLICT (user_login)
                        DO UPDATE

                        SET user_login = EXCLUDED.user_login,
                            user_password = EXCLUDED.user_password;
                END IF;

        END IF;

        IF (TG_TABLE_NAME = 'employee')
            THEN
            RAISE INFO 'IN EMPLOYEE TABLE_NAME';
            INSERT INTO users (user_login, user_password, user_role)
            VALUES (NEW."employee_login", NEW."employee_password", NEW."employee_position")
            ON CONFLICT (user_login)
                        DO UPDATE
                        SET user_login = EXCLUDED.user_login,
                            user_password = EXCLUDED.user_password;
        END IF;
    RETURN NEW;
        END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER update_users_with_client
    AFTER INSERT OR UPDATE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();


CREATE TRIGGER update_users_with_employee
    AFTER INSERT OR UPDATE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();

REVOKE ALL ON FUNCTION
    update_users_table()
    FROM public;

GRANT EXECUTE ON FUNCTION
    update_users_table()
    TO user_client;

-----------------------------------------------

--Function and triggers for hashing passwords
------------------------------------------
CREATE OR REPLACE FUNCTION hash_password()
RETURNS trigger AS
$$
    BEGIN
        IF(TG_TABLE_NAME = 'client')
        THEN
            IF (TG_OP = 'INSERT' OR NEW.client_password NOT LIKE OLD.client_password)
                THEN
                    NEW.client_password = encode(digest(NEW.client_password, 'sha256'), 'hex');
                END IF;
            END IF;

        IF(TG_TABLE_NAME = 'employee')
        THEN
            IF (TG_OP = 'INSERT' OR NEW.employee_password NOT LIKE OLD.employee_password)
                THEN
                    NEW.employee_password = encode(digest(NEW.employee_password, 'sha256'), 'hex');
            END IF;
        END IF;

    RETURN NEW;
    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER make_client_password_hash
    BEFORE INSERT OR UPDATE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE hash_password();

CREATE TRIGGER make_employee_password_hash
    BEFORE INSERT OR UPDATE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE hash_password();

------------------------------------------



--Function to create new account
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
RETURNS TABLE (created bool) AS
$$
    BEGIN

        INSERT INTO
            client(client_firstname, client_lastname, phone_number, email, client_login, client_password, delivery_address)
        VALUES
            (client_firstname_, client_lastname_, phone_number_, email_, client_login_, client_password_, delivery_address_);

        RETURN QUERY
        SELECT EXISTS(
            SELECT * FROM client WHERE client.client_login = client_login_
        );
        END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
    FROM public;

GRANT EXECUTE ON FUNCTION
    create_client(
    client_firstname_ varchar,
    client_lastname_ varchar,
    phone_number_ varchar,
    email_ varchar,
    client_login_ varchar,
    client_password_ varchar,
    delivery_address_ varchar
)
      TO user_client;
-----------------------------------------------------------------------
