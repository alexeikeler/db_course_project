--Function and triggers for updating users table when new employee or client created
-----------------------------------------------
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

-----------------------------------------------



