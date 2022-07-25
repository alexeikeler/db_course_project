--Shop assistant role

------------------------------------------------------------------
CREATE USER user_shop_assistant WITH PASSWORD 'JFDAOLSKJFA';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_shop_assistant;
GRANT USAGE ON SCHEMA public TO user_shop_assistant;
------------------------------------------------------------------
