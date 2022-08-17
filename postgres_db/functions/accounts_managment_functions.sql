--------------------------------------------------------------------------------------
--Function and triggers for hashing passwords
--------------------------------------------------------------------------------------
DROP FUNCTION hash_password();
CREATE OR REPLACE FUNCTION hash_password()
RETURNS trigger AS
$$
    BEGIN
        RAISE INFO 'IN TRIGGER HASH PASS';
        IF (TG_OP = 'INSERT' OR NEW.user_password NOT LIKE OLD.user_password)
            THEN
                NEW.user_password = encode(digest(NEW.user_password, 'sha256'), 'hex');
            END IF;

    RETURN NEW;
    END;
$$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


DROP TRIGGER hash_users_password_trigger ON users;
CREATE TRIGGER hash_users_password_trigger
    BEFORE INSERT OR UPDATE
    ON users
    FOR EACH ROW
    EXECUTE PROCEDURE hash_password();

--------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
--Function for updating password
--------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION change_password(login varchar, old_password varchar, new_password varchar)
RETURNS boolean AS
    $$

    BEGIN

        IF EXISTS(
            SELECT *
            FROM users
            WHERE
                users.user_login = login
            AND
                users.user_password = encode(digest(old_password, 'sha256'), 'hex')
            )
            THEN
                UPDATE users
                SET
                    user_password = new_password
                WHERE
                    user_login = login;
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
    change_password(login varchar, old_password varchar, new_password varchar)
    FROM public;

GRANT EXECUTE ON FUNCTION
    change_password(login varchar, old_password varchar, new_password varchar)
    TO user_client;

--------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
--When client / employee account deleted delete it from users table
--------------------------------------------------------------------------------------
DROP FUNCTION delete_user();
CREATE OR REPLACE FUNCTION delete_user()
RETURNS TRIGGER AS
    $$
    BEGIN
        IF (TG_TABLE_NAME = 'client')
        THEN

            DELETE FROM
                       users
                   WHERE
                       users.user_login = OLD.client_login;
            RAISE INFO 'Deleted client %', OLD.client_login;

        ELSIF (TG_TABLE_NAME = 'employee')
            THEN
                DELETE FROM
                        users
                WHERE
                    users.user_login = OLD.employee_login;

            RAISE INFO 'Deleted employee %', OLD.employee_login;

        END IF;

        RETURN NEW;
    END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

DROP TRIGGER delete_from_users ON client;
CREATE TRIGGER delete_from_users
    AFTER DELETE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE delete_user();

DROP TRIGGER delete_from_users ON employee;
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
--------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
--Function to create new client account
--------------------------------------------------------------------------------------
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
            client(client_firstname, client_lastname, phone_number, email, client_login, delivery_address)
        VALUES
            (client_firstname_, client_lastname_, phone_number_, email_, client_login_, delivery_address_);

        INSERT INTO
            users(user_login, user_role, user_password)
        VALUES
            (client_login_, 'client', client_password_);

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
--------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
--Function to create employee account
--------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_employee(
    employee_lastname_ varchar,
    employee_firstname_ varchar,
    employee_position_ varchar,
    employee_salary_ numeric(7, 2),
    employee_phone_num_ varchar,
    employee_email_ varchar,
    employee_login_ varchar,
    employee_password_ varchar,
    employee_place_of_work integer
)
    RETURNS BOOL AS
    $$
        BEGIN
            INSERT INTO employee
                (lastname, firstname, employee_position, salary, phone_number, email, employee_login, place_of_work)
            VALUES
                (
                 employee_lastname_,
                 employee_firstname_,
                 employee_position_,
                 employee_salary_,
                 employee_phone_num_,
                 employee_email_,
                 employee_login_,
                 employee_place_of_work
                 );

            INSERT INTO
                users(user_login, user_role, user_password)
            VALUES
                (employee_login_, employee_position_, employee_password_);


        IF EXISTS( SELECT employee_id FROM employee WHERE employee_login = employee_login_) THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
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


---------------------------------------------------------------------------------------
--Function and triggers for updating users table when new employee or client created
---------------------------------------------------------------------------------------
DROP FUNCTION update_users_table();
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
                END IF;

        END IF;

        IF (TG_TABLE_NAME = 'employee')
            THEN
                IF NEW.employee_login NOT LIKE OLD.employee_login
                    THEN
                    RAISE INFO 'Updating employee login from % to %', OLD.employee_login, NEW.employee_login;
                    UPDATE users
                    SET user_login = NEW.employee_login
                    WHERE user_login = OLD.employee_login;
                END IF;

        END IF;
    RETURN NEW;
        END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

DROP TRIGGER update_users_with_client ON client;
CREATE TRIGGER update_users_with_client
    AFTER UPDATE
    ON client
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();

DROP TRIGGER update_users_with_employee ON employee;
CREATE TRIGGER update_users_with_employee
    AFTER UPDATE
    ON employee
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_table();

REVOKE ALL ON FUNCTION
    update_users_table()
    FROM public;

GRANT EXECUTE ON FUNCTION
    update_users_table()
    TO user_client;

---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
DROP FUNCTION get_employee_main_data(login varchar);
--Function for getting employee id and place of work
CREATE OR REPLACE FUNCTION get_employee_main_data(login varchar)
RETURNS TABLE(empl_id integer, empl_place_of_work integer) AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    employee.employee_id, employee.place_of_work
                FROM
                    employee
                WHERE
                    employee.employee_login = login;

        END;
    $$

LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_employee_main_data(login varchar) FROM public;

GRANT EXECUTE ON FUNCTION
    get_employee_main_data(login varchar) TO user_manager;

---------------------------------------------------------------------------------------