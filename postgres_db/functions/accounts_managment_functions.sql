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
                DELETE FROM users WHERE users.user_login = OLD.employee_login;

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

select * from employee where place_of_work = 4;

select * from delete_employee(59, 'shop_assistant', 4);

select * from create_employee(
    'Павлов',
    'Алексей',
    'shop_assistant',
    10000.00,
    '+380765765765',
    'pavlovAlexei@gmail.com',
    'alexeipavlov',
    '123456789',
    4
                  );

DROP FUNCTION create_employee(employee_lastname_ varchar, employee_firstname_ varchar, employee_position_ varchar, employee_salary_ numeric(7,2), employee_phone_num_ varchar, employee_email_ varchar, employee_login_ varchar, employee_password_ varchar, employee_place_of_work integer);
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
    RETURNS VOID AS
    $$
        DECLARE
            sa_count INTEGER;
            sa_flag BOOLEAN = FALSE;
            m_count INTEGER;
            m_flag BOOLEAN = FALSE;
            dummy_sa_id INTEGER;
            dummy_m_id INTEGER;
            new_emp_id INTEGER;
            error_message VARCHAR = format(
                'Employee with position %s already exists in shop # %s. '
                'If you need new employee with this position in this shop, '
                'please delete old one first.',
                employee_position_, employee_place_of_work
                );

        BEGIN

            IF employee_position_ LIKE 'shop_assistant'
                 THEN
                     sa_flag = TRUE;
                     SELECT COUNT(employee_position) INTO sa_count FROM employee
                     WHERE employee_position = 'shop_assistant' AND place_of_work = employee_place_of_work;
                        RAISE INFO 'sa_count: %', sa_count;
                     IF sa_count = 2
                         THEN
                             RAISE WARNING '%', error_message;
                             RETURN;
                     END IF;

                     SELECT employee_id INTO dummy_sa_id FROM employee
                     WHERE employee_position = 'shop_assistant' AND place_of_work = employee_place_of_work;

            ELSIF employee_position_ LIKE 'manager'
                THEN
                    m_flag = TRUE;
                    SELECT COUNT(employee_position) INTO m_count FROM employee
                    WHERE employee_position = 'manager' AND place_of_work = employee_place_of_work;

                    RAISE INFO 'm_count: %', m_count;

                    IF m_count = 2
                        THEN
                            RAISE WARNING '%', error_message;
                            RETURN;
                    END IF;

                    SELECT employee_id INTO dummy_m_id FROM employee
                    WHERE employee_position = 'manager' AND place_of_work = employee_place_of_work;

            ELSE
                IF EXISTS(
                    SELECT
                        employee_id
                    FROM
                        employee
                    WHERE
                        employee_position = employee_position_ AND place_of_work = employee_place_of_work
                    ) THEN
                        RAISE WARNING '%', error_message;
                        RETURN;
                END IF;

                IF EXISTS(SELECT employee_id FROM employee WHERE employee_login = employee_login_) THEN
                     RAISE WARNING
                         'Employee with login % already exists!', employee_login_;
                     RETURN;
                END IF;

            END IF;

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
                )
             RETURNING
                employee_id INTO new_emp_id;


            INSERT INTO
                users(user_login, user_role, user_password)
            VALUES
                (employee_login_, employee_position_, employee_password_);

            IF sa_flag THEN
                RAISE INFO 'IN SA_FLAG CHECK| sa_flag: % | new_emp_id: % | dummy_sa_id: %', sa_flag, new_emp_id, dummy_sa_id;
                UPDATE client_order
                    SET sender = new_emp_id
                    WHERE sender = dummy_sa_id;

            ELSIF m_flag THEN
                RAISE INFO 'IN M_FLAG CHECK| m_flag: % | new_emp_id: % | dummy_m_id: %', m_flag, new_emp_id, dummy_m_id;
                UPDATE book_shop
                    SET manager = new_emp_id
                    WHERE manager = dummy_m_id;
                END IF;

            IF EXISTS( SELECT employee_id FROM employee WHERE employee_login = employee_login_) THEN
                RAISE INFO 'New account: ROLE - % | LOGIN - % created.', employee_position_, employee_login_;
                RETURN;
            ELSE
                RAISE WARNING
                    'Error occured while creating account: ROLE - % | LOGIN - %', employee_position_, employee_login_;
                RETURN;
            END IF;

            END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION create_employee(
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
    FROM PUBLIC;

GRANT EXECUTE ON FUNCTION create_employee(
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
    TO user_admin;
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
    get_employee_main_data(login varchar) TO user_manager, user_director;

---------------------------------------------------------------------------------------

DROP FUNCTION delete_client(id integer);
CREATE OR REPLACE FUNCTION delete_client(id integer)
RETURNS BOOL AS
    $$
        DECLARE
            dummy_client_id integer;

        BEGIN
            IF EXISTS(

                SELECT order_id  FROM client_order
                WHERE reciever = id AND order_status SIMILAR TO '(Оплачен|Обработан|Доставляется)'
                ) THEN

                RETURN FALSE;

            END IF;

            SELECT client_id INTO dummy_client_id FROM client WHERE client_login = 'DeletedAccount';

            UPDATE client_order
                SET reciever = dummy_client_id
                WHERE reciever = id;

            UPDATE client_review
                SET review_by = dummy_client_id
                WHERE review_by = id;

            DELETE FROM client WHERE client_id = id;
            DELETE FROM client_review WHERE review_by = id;

           RETURN TRUE;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    delete_client(id integer) FROM public;

GRANT EXECUTE ON FUNCTION
    delete_client(id integer) TO user_admin;
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
DROP FUNCTION employee_activity();
CREATE OR REPLACE FUNCTION employee_activity()
RETURNS TABLE(
    empl_id_ integer,
    empl_firstname varchar,
    empl_lastname varchar,
    empl_login varchar,
    counted_reviews_ integer,
    name_of_shop_ varchar,
    empl_pos_ varchar,
    salary numeric(7, 2),
    phone_num varchar,
    email varchar
             )
AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
                employee.employee_id,
                employee.firstname,
                employee.lastname,
                employee.employee_login,
                empl_reviews_ctr.counted_reviews::int,
                book_shop.name_of_shop,
                employee.employee_position,
                employee.salary,
                employee.phone_number,
                employee.email
            FROM
                book_shop, employee
            LEFT JOIN
                    (
                        SELECT
                            review_about_employee, count(review_about_employee) AS counted_reviews
                        FROM
                            client_review
                        GROUP BY
                            review_about_employee
                    ) AS empl_reviews_ctr
            ON
                employee.employee_id = empl_reviews_ctr.review_about_employee

            WHERE
                employee.place_of_work = book_shop.shop_id
            ORDER BY employee.employee_position, employee.employee_login;
        END;

    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION employee_activity() FROM public;
GRANT EXECUTE ON FUNCTION employee_activity() TO user_admin;
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
DROP FUNCTION update_employee_data(update_subject varchar, data varchar, id integer);
CREATE OR REPLACE FUNCTION update_employee_data(update_subject varchar, data varchar, id integer)
RETURNS BOOLEAN AS

    $$
        DECLARE
            exists integer = -1;

        BEGIN
            EXECUTE format(
                'UPDATE employee SET %1$s = %2$L WHERE %3$s = %4$s', update_subject, data, 'employee_id', id
                );

            EXECUTE FORMAT(
                'SELECT employee_id FROM employee WHERE %1$s = %2$L', update_subject, data
                ) INTO exists;

            IF exists > 0 THEN
                RAISE INFO '%', exists;
                RETURN TRUE;
            ELSE
                RETURN FALSE;

            END IF;
        END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION update_employee_data(update_subject varchar, data varchar, id integer)FROM public;
GRANT EXECUTE ON FUNCTION update_employee_data(update_subject varchar, data varchar, id integer) TO user_admin;
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
DROP FUNCTION delete_employee(id integer, pos varchar, place_of_work integer);
CREATE OR REPLACE FUNCTION delete_employee(id integer, pos varchar, pow integer)
RETURNS BOOLEAN AS
    $$
        DECLARE
            dummy_sender integer;
            dummy_manager integer;

        BEGIN
            CASE pos
                WHEN 'director'
                    THEN
                        DELETE FROM client_review WHERE review_about_employee = id;
                        DELETE FROM employee WHERE employee_id = id;
                        RETURN TRUE;

                WHEN 'shop_assistant'
                    THEN
                        IF EXISTS(
                            SELECT order_id FROM client_order
                                            WHERE sender = id AND order_status NOT IN ('Доставлен', 'Отменён')
                            ) THEN

                                RETURN FALSE;
                        END IF;

                        SELECT employee_id INTO dummy_sender FROM employee
                        WHERE employee_login = format('dummy_shop_assistant_%s', pow);

                        UPDATE client_order
                        SET sender = dummy_sender
                        WHERE sender = id;

                        DELETE FROM client_review WHERE review_about_employee = id;
                        DELETE FROM employee WHERE employee_id = id;

                        RETURN TRUE;

                WHEN 'manager'
                    THEN
                        SELECT employee_id INTO dummy_manager FROM employee
                        WHERE employee_login = format('dummy_manager_%s', pow);

                        UPDATE book_shop
                        SET manager = dummy_manager
                        WHERE manager = id;

                        DELETE FROM employee WHERE employee_id = id;

                        RETURN TRUE;

                ELSE
                    RETURN FALSE;
            END CASE;

        END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    delete_employee(id integer, pos varchar, place_of_work integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
    delete_employee(id integer, pos varchar, place_of_work integer) TO user_admin;
---------------------------------------------------------------------------------------
