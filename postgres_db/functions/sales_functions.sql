
------------------------------------------------------------------------------------------------------
--Sales by genre between two dates

DROP FUNCTION get_genre_sales(manager_pow integer, l_time timestamp(0), r_time timestamp(0));
CREATE OR REPLACE FUNCTION get_genre_sales(
manager_pow integer,
l_time timestamp(0),
r_time timestamp(0)
)
RETURNS TABLE (
                genre_type_ varchar,
                sum_per_genre_ numeric(10, 2),
                sold_copies_ integer
              )
AS
    $$
        BEGIN
            RETURN QUERY

            SELECT inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies FROM(

                SELECT
                    genre_type,
                    sum(sum_to_pay) OVER(PARTITION BY genre_type)::numeric(10, 2) AS sum_per_genre,
                    sum(quantity) OVER(PARTITION BY genre_type):: integer AS sold_copies
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_time AND r_time) AS inner_select

            GROUP BY inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies
            ORDER BY  inner_select.sum_per_genre DESC;

        END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_genre_sales(manager_pow integer, l_time timestamp(0), r_time timestamp(0)) FROM public;
GRANT EXECUTE ON FUNCTION
    get_genre_sales(manager_pow integer, l_time timestamp(0), r_time timestamp(0)) TO user_manager;

------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
--Function for getting ALL sales for each month / year
DROP FUNCTION get_sales_by_date(manager_pow integer, trunc_by varchar);
CREATE OR REPLACE FUNCTION get_sales_by_date(manager_pow integer, trunc_by varchar)
RETURNS TABLE (
    date_ date,
    sum_per_partition_ numeric(7, 2)
              )
AS
    $$
        BEGIN
            RETURN QUERY
            SELECT
                inner_select.month_of_sale, inner_select.sum_per_month
            FROM (

                SELECT
                    date_trunc(trunc_by, date_of_order)::date
                        AS month_of_sale,
                    SUM(sum_to_pay) OVER(PARTITION BY date_trunc(trunc_by, date_of_order))::numeric(7, 2)
                        AS sum_per_month
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                )
                AS inner_select

            GROUP BY
                month_of_sale, sum_per_month
            ORDER BY
                month_of_sale;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_sales_by_date(manager_pow integer, trunc_by varchar) FROM public;
GRANT EXECUTE ON FUNCTION get_sales_by_date(manager_pow integer, trunc_by varchar) TO user_manager;

------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
DROP FUNCTION get_top_selling_books(manager_pow integer, l_time timestamp(0), r_time timestamp(0), n_top integer);
CREATE OR REPLACE FUNCTION get_top_selling_books(
manager_pow integer, l_time timestamp(0), r_time timestamp(0), n_top integer
)
RETURNS TABLE (
    title_ varchar,
    sold_copies integer
              )
AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    title,
                    sum(sum(quantity)) OVER(PARTITION BY title)::integer as sold_cop_num
                FROM
                    sales
                WHERE
                    sales.concrete_shop = manager_pow
                AND
                    date_of_order BETWEEN l_time AND r_time
                GROUP BY title
                ORDER BY sold_cop_num DESC
                LIMIT n_top;
        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_top_selling_books(manager_id integer, l_time timestamp(0), r_time timestamp(0), n_top integer) FROM public;
GRANT EXECUTE ON FUNCTION
    get_top_selling_books(manager_id integer, l_time timestamp(0), r_time timestamp(0), n_top integer) TO user_manager;

------------------------------------------------------------------------------------------------------
DROP FUNCTION get_order_statuses_count(manager_pow integer, l_date timestamp, r_date timestamp);
CREATE OR REPLACE FUNCTION get_order_statuses_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0))
RETURNS TABLE (
    order_status_ varchar,
    counted_ integer
              )
AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    order_status,
                    count(order_status)::integer as counted
                FROM
                    sales
                WHERE
                    concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_date AND r_date
                GROUP BY order_status;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_order_statuses_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0)) FROM public;
GRANT EXECUTE ON FUNCTION
    get_order_statuses_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0)) TO user_manager;
------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
DROP FUNCTION get_payment_types_count(manager_pow integer, l_date timestamp, r_date timestamp);
CREATE OR REPLACE FUNCTION get_payment_types_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0))
RETURNS TABLE (
    payment_type_ varchar,
    counted_ integer
              )
AS
    $$
        BEGIN
            RETURN QUERY
                SELECT
                    payment_type,
                    count(payment_type)::integer as counted
                FROM
                    sales
                WHERE
                    concrete_shop = manager_pow
                AND
                    sales.date_of_order BETWEEN l_date AND r_date
                GROUP BY payment_type;

        END;
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION
    get_payment_types_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0)) FROM public;
GRANT EXECUTE ON FUNCTION
    get_payment_types_count(manager_pow integer, l_date timestamp(0), r_date timestamp(0)) TO user_manager;


------------------------------------------------------------------------------------------------------








