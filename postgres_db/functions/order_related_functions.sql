-----------------------------------------------------------------------------------------------------
--Add order to client_order table
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_order(
    book_title_ varchar,
    date_of_publishing_ date,
    ordering_date timestamp(0),
    shop_number integer,
    cli_login_ varchar,
    delivery_address_ varchar,
    order_status_ varchar,
    sum_to_pay_ numeric(6, 2),
    payment_type_ varchar,
    additional_info_ varchar,
    quantity_ integer
) RETURNS VOID AS
    $$
        DECLARE
            emp_id integer;
            cli_id integer;
            book_edition_number integer;
            current_order_id integer;
            available_amount integer;

        BEGIN

            SELECT client.client_id INTO cli_id FROM client WHERE client.client_login = cli_login_;

            SELECT
                edition.edition_number, edition.number_of_copies_in_shop
            INTO
                book_edition_number, available_amount
            FROM
                edition, authority, book
            WHERE
                edition.authority_id = authority.authority_id
            AND
                authority.edition_book = book.book_id
            AND
                book.title = book_title_
            AND
                edition.publishing_date = date_of_publishing_;

            IF quantity_ > available_amount THEN
                RAISE EXCEPTION 'To much books ordered. Maximum amount is: %', available_amount;
            END IF;

            SELECT
                employee.employee_id
            INTO
                emp_id
            FROM
                employee, edition, book_shop
            WHERE
                employee.place_of_work = shop_number
            AND
                employee.employee_position = 'shop_assistant';

            RAISE INFO 'emp_id % , cli_id %, edition_num of book %', emp_id, cli_id, book_edition_number;

            INSERT INTO client_order
                (sender,
                 reciever,
                 delivery_address,
                 order_status,
                 sum_to_pay,
                 payment_type,
                 additional_info,
                 date_of_order,
                 quantity ,
                 date_of_return)
            VALUES
                (emp_id,
                 cli_id,
                 delivery_address_,
                 order_status_,
                 sum_to_pay_,
                 payment_type_,
                 additional_info_,
                 ordering_date,
                 quantity_,
                 NULL)
            RETURNING
                order_id INTO current_order_id;

            INSERT INTO chosen
                (edition_number, order_id)
            VALUES
                (book_edition_number, current_order_id);

            END
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION add_order(
    book_title_ varchar,
    date_of_publishing_ date,
    ordering_date timestamp(0),
    shop_number integer,
    cli_login_ varchar,
    delivery_address_ varchar,
    order_status_ varchar,
    sum_to_pay_ numeric(6, 2),
    payment_type_ varchar,
    additional_info_ varchar,
    quantity_ integer
) FROM public;

GRANT EXECUTE ON FUNCTION add_order(
    book_title_ varchar,
    date_of_publishing_ date,
    ordering_date timestamp(0),
    shop_number integer,
    cli_login_ varchar,
    delivery_address_ varchar,
    order_status_ varchar,
    sum_to_pay_ numeric(6, 2),
    payment_type_ varchar,
    additional_info_ varchar,
    quantity_ integer
) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
-- Reduce amount of available books when user creating an order
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION reduce_available_books()
RETURNS TRIGGER AS
    $$
    DECLARE
        edition_to_update int2;
        reduce_by int2;

    BEGIN

        SELECT
            edition.edition_number
        INTO
            edition_to_update
        FROM
            edition, client_order
        WHERE
            NEW.order_id = client_order.order_id
        AND
            NEW.edition_number = edition.edition_number;

        SELECT
            client_order.quantity
        INTO
            reduce_by
        FROM
            client_order
        WHERE
            NEW.order_id = client_order.order_id;

        UPDATE
            edition
        SET
            number_of_copies_in_shop = number_of_copies_in_shop - reduce_by
        WHERE
            edition_number = edition_to_update;

        RETURN NEW;
    END
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION reduce_available_books() FROM public;

GRANT EXECUTE ON FUNCTION reduce_available_books() TO user_client;


CREATE TRIGGER reduce_available_books_trigger
    AFTER INSERT
    ON chosen
    FOR EACH ROW
    EXECUTE PROCEDURE reduce_available_books();

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Return books (add client_order.quantity to edition.number_available_books)
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION return_ordered_books()
RETURNS TRIGGER AS

    $$
    DECLARE
        edition_to_return int2;

    BEGIN

        SELECT
            chosen.edition_number INTO edition_to_return FROM edition, chosen
        WHERE
            NEW.order_id = chosen.order_id;

        UPDATE edition
        SET number_of_copies_in_shop = number_of_copies_in_shop + NEW.quantity
        WHERE edition_number = edition_to_return;

        RETURN NEW;
    END

    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION return_ordered_books() FROM public;

GRANT EXECUTE ON FUNCTION return_ordered_books() TO user_client;

CREATE TRIGGER return_ordered_books_trigger
    AFTER UPDATE
    ON client_order
    FOR EACH ROW
    WHEN (NEW.order_status = 'Отменён')
    EXECUTE PROCEDURE return_ordered_books();

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
--Update order status
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_user_order(ordering_date timestamp(0), status varchar)
RETURNS VOID AS
    $$
        BEGIN

        IF status = 'Отменён' THEN
            UPDATE client_order
            SET
                order_status = status,
                date_of_return = now()
            WHERE
                date_of_order = ordering_date;
        ELSE
            UPDATE client_order
            SET
                order_status = status
            WHERE
                date_of_order = ordering_date;
        END IF;

        END;
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION update_user_order(ordering_date timestamp(0), status varchar) FROM public;

GRANT EXECUTE ON FUNCTION update_user_order(ordering_date timestamp(0), status varchar) TO user_client;

-----------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------
-- Function for getting orders for specific client
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_client_orders(login varchar)
RETURNS TABLE (
    book_title_ varchar,
    quantity_ int,
    sum_to_pay_ numeric(7, 2),
    order_status_ varchar,
    date_of_order_ timestamp(0),
    date_of_return_ timestamp(0)
) AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    title,quantity, sum_to_pay, order_status, date_of_order, date_of_return
                FROM
                    client_order, chosen, client, book, edition, authority
                WHERE
                    client_order.reciever = client.client_id
                AND
                    client.client_login = login
                AND
                    chosen.order_id = client_order.order_id
                AND
                    chosen.edition_number = edition.edition_number
                AND
                    edition.authority_id = authority.authority_id
                AND
                    authority.edition_book = book.book_id;
        END
    $$


LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;


REVOKE ALL ON FUNCTION get_client_orders(client_login varchar) FROM public;

GRANT EXECUTE ON FUNCTION get_client_orders(client_login varchar) TO user_client;

-----------------------------------------------------------------------------------------------------
