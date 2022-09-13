--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5 (Ubuntu 14.5-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.5 (Ubuntu 14.5-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: publishing_agency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publishing_agency (
    publishing_agency_id integer NOT NULL,
    publishing_agency_name character varying(128) NOT NULL,
    phone_number character varying(16) NOT NULL,
    email character varying(64) NOT NULL,
    CONSTRAINT publishing_agency_email_check CHECK (((email)::text ~ similar_to_escape('[A-Za-z0-9._%+-]+@[A-Za-z0-9]+\.[A-Za-z]{2,4}'::text))),
    CONSTRAINT publishing_agency_phone_number_check CHECK (((phone_number)::text ~ similar_to_escape('\+?3?8?(0\d{9})'::text))),
    CONSTRAINT publishing_agency_publishing_agency_name_check CHECK ((length((publishing_agency_name)::text) > 0))
);


ALTER TABLE public.publishing_agency OWNER TO postgres;

--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publishing_agency_publishing_agency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publishing_agency_publishing_agency_id_seq OWNER TO postgres;

--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publishing_agency_publishing_agency_id_seq OWNED BY public.publishing_agency.publishing_agency_id;


--
-- Name: publishing_agency publishing_agency_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency ALTER COLUMN publishing_agency_id SET DEFAULT nextval('public.publishing_agency_publishing_agency_id_seq'::regclass);


--
-- Data for Name: publishing_agency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publishing_agency (publishing_agency_id, publishing_agency_name, phone_number, email) FROM stdin;
1	Ad Marginem	+380567343231	admarginem@gmail.com
2	BookChef	+380321785673	bookchefagency@gmail.com
3	ArtHuss	+380982728543	arthuss_agency@gmailc.com
4	Terra Incognita	+380788567761	terra_incognita@gmail.com
5	Pabulum	+380988275914	pabulum_bookagency@gmail.com
\.


--
-- Name: publishing_agency_publishing_agency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publishing_agency_publishing_agency_id_seq', 5, true);


--
-- Name: publishing_agency publishing_agency_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_email_key UNIQUE (email);


--
-- Name: publishing_agency publishing_agency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_pkey PRIMARY KEY (publishing_agency_id);


--
-- Name: publishing_agency publishing_agency_publishing_agency_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishing_agency
    ADD CONSTRAINT publishing_agency_publishing_agency_name_key UNIQUE (publishing_agency_name);


--
-- Name: TABLE publishing_agency; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.publishing_agency TO user_admin;


--
-- PostgreSQL database dump complete
--

