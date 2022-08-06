--Shop manager role & permissions

------------------------------------------------------------------

CREATE USER user_manager WITH PASSWORD 'PALSDJJWKKS';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_manager;
GRANT USAGE ON SCHEMA public TO user_manager;

------------------------------------------------------------------

--Permissions

GRANT EXECUTE ON FUNCTION
    get_employee_id(login varchar) TO user_manager;