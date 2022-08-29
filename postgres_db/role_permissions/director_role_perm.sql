CREATE USER user_director WITH PASSWORD 'AOAOSDK23SD';
GRANT CONNECT ON DATABASE "BigBook_db" TO user_director;
GRANT USAGE ON SCHEMA public TO user_director;
