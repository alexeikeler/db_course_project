-- Table users for clients and employees for connection check
------------------------------------------------------------------
create table users(
    user_id SERIAL NOT NULL PRIMARY KEY,
    user_login VARCHAR(64) UNIQUE NOT NULL CHECK(length(user_login) > 0),
    user_role VARCHAR(32) NOT NULL CHECK(length(user_role) > 0)
);