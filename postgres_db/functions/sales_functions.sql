
------------------------------------------------------------------------------------------------------
--Sales by genre between two dates

DROP FUNCTION get_genre_sales(manager_id integer, l_time timestamp(0), r_time timestamp(0));
CREATE OR REPLACE FUNCTION get_genre_sales(
manager_id integer,
l_time timestamp(0),
r_time timestamp(0)
)
RETURNS TABLE (
                genre_type_ varchar,
                sum_per_genre_ numeric(7, 2),
                sold_copies_ integer
              )
AS
    $$
        BEGIN
            RETURN QUERY

            SELECT inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies FROM(

                SELECT
                    genre_type,
                    sum(sum_to_pay) OVER(PARTITION BY genre_type)::numeric(7, 2) AS sum_per_genre,
                    sum(quantity) OVER(PARTITION BY genre_type):: integer AS sold_copies
                FROM
                    sales, employee
                WHERE
                    employee.employee_id = manager_id
                AND
                    employee.place_of_work = sales.concrete_shop
                AND
                    date_of_order BETWEEN l_time AND r_time) AS inner_select

            GROUP BY inner_select.genre_type, inner_select.sum_per_genre, inner_select.sold_copies
            ORDER BY  inner_select.sum_per_genre DESC;

        END
    $$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION get_genre_sales(manager_id integer, l_time timestamp(0), r_time timestamp(0)) FROM public;
GRANT EXECUTE ON FUNCTION get_genre_sales(manager_id integer, l_time timestamp(0), r_time timestamp(0)) TO 7;
------------------------------------------------------------------------------------------------------
DROP FUNCTION get_sales_by_date(manager_id integer, trunc_by varchar);
CREATE OR REPLACE FUNCTION get_sales_by_date(manager_id integer, trunc_by varchar)
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
                    sales, employee
                WHERE
                    employee.employee_id = manager_id
                AND
                    sales.concrete_shop = employee.place_of_work
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

REVOKE ALL ON FUNCTION get_sales_by_date(manager_id integer, trunc_by varchar) FROM public;
GRANT EXECUTE ON FUNCTION get_sales_by_date(manager_id integer, trunc_by varchar) TO user_manager;

------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
DROP FUNCTION get_top_selling_books(manager_id integer, l_time timestamp(0), r_time timestamp(0), n_top integer);
CREATE OR REPLACE FUNCTION get_top_selling_books(
manager_id integer, l_time timestamp(0), r_time timestamp(0), n_top integer
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
                    sales, employee
                WHERE
                    employee.employee_id = manager_id
                AND
                    employee.place_of_work = sales.concrete_shop
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
