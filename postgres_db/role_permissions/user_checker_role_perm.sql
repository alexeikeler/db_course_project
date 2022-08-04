-- User user_checker for checking if user who tries to connect exist
-------------------------------------------------------

CREATE USER user_checker WITH PASSWORD 'IqmKKJHTbT38';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_checker;
GRANT USAGE ON SCHEMA public TO user_checker;

-------------------------------------------------------

GRANT EXECUTE ON FUNCTION verify_user(login varchar, password varchar) TO user_checker;