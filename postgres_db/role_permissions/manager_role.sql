--Shop manager role & permissions

------------------------------------------------------------------

CREATE USER user_manager WITH PASSWORD 'PALSDJJWKKS';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_manager;
GRANT USAGE ON SCHEMA public TO user_manager;

------------------------------------------------------------------

--Permissions

------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION
    get_publishing_agencies() TO user_manager;

GRANT EXECUTE ON FUNCTION
    not_sold_books(manager_pow integer) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_number_of_books(manager_pow integer) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_employee_main_data(login varchar) TO user_manager;

GRANT EXECUTE ON FUNCTION
    add_author(lastname_ varchar, firstname_ varchar, dob_ date, dod_ date) TO user_manager;

GRANT EXECUTE ON FUNCTION
    delete_author(author_id integer) TO user_manager;

GRANT EXECUTE ON FUNCTION
    add_edition(
    manager_pow integer,
    book_title_ varchar,
    book_genre_type varchar,

    book_author_id integer,

    publishing_agency_ varchar,
    price numeric(7, 2),
    publishing_date_ date,
    available_copies_ integer,
    pages_ integer,
    binding_type_ varchar,
    paper_quality_ varchar
)  TO user_manager;

GRANT EXECUTE ON FUNCTION
    delete_edition(edition_id integer) TO user_manager;

GRANT EXECUTE ON FUNCTION
    update_editions_number(edition_id integer, update_by integer) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_authors(author_name varchar) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_genre_sales(manager_pow integer, l_time timestamp(0), r_time timestamp(0)) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_sales_by_date(manager_pow integer, trunc_by varchar) TO user_manager;

GRANT EXECUTE ON FUNCTION
    get_top_selling_books(manager_id integer, l_time timestamp(0), r_time timestamp(0), n_top integer) TO user_manager;
------------------------------------------------------------------