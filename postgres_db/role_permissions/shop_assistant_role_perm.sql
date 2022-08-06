--Shop assistant role & permissions

------------------------------------------------------------------
CREATE USER user_shop_assistant WITH PASSWORD 'JFDAOLSKJFA';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_shop_assistant;
GRANT USAGE ON SCHEMA public TO user_shop_assistant;
------------------------------------------------------------------


--Permissions

GRANT EXECUTE ON FUNCTION
    get_shop_assistant_orders(sa_place_of_work varchar) TO user_shop_assistant;
GRANT EXECUTE ON FUNCTION
    get_reviews_for_shop_assistant(sa_login varchar, reviews_about varchar) TO user_shop_assistant;
GRANT EXECUTE ON FUNCTION
    delete_review(id integer) TO user_client, user_shop_assistant;
GRANT EXECUTE ON FUNCTION
    update_user_order(current_order_id integer, status varchar) TO user_shop_assistant;
