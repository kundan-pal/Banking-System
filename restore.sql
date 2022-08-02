--
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9 (Ubuntu 12.9-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.9 (Ubuntu 12.9-0ubuntu0.20.04.1)

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

DROP DATABASE bank;
--
-- Name: bank; Type: DATABASE; Schema: -; Owner: aditya
--

CREATE DATABASE bank WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_IN' LC_CTYPE = 'en_IN';


ALTER DATABASE bank OWNER TO aditya;

\connect bank

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

--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: calculate_amount(); Type: FUNCTION; Schema: public; Owner: rupesh
--

CREATE FUNCTION public.calculate_amount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    amt numeric;
    
BEGIN
    amt = new.loan_amount + (new.loan_amount*new.loan_interest*new.loan_years)/100;
    new.loan_amount = amt;
    return new;
END;
$$;


ALTER FUNCTION public.calculate_amount() OWNER TO rupesh;

--
-- Name: check_amount(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_amount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    amount numeric;
BEGIN
    
	amount = new.acc_balance;
	if(amount <= 5000) then 
		raise notice 'Your account has reached minimum balance limit';
	end if;
	if(amount > 500000) then 
		raise notice 'Your account has reached maximum balance limit';
	end if;
    return new;
END;
$$;


ALTER FUNCTION public.check_amount() OWNER TO postgres;

--
-- Name: delete_customer_account(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_customer_account(account_no integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$


BEGIN
    
    if NOT EXISTS (SELECT acc_number from account where acc_number = account_no) then
        raise exception 'Not a valid account number';
    else
        update account set status = 'Inactive' where acc_number = account_no;
		update  account set acc_balance = 0 where acc_number = account_no;
    end if;


    return 1;
    
END;
$$;


ALTER FUNCTION public.delete_customer_account(account_no integer) OWNER TO postgres;

--
-- Name: deposit(integer, numeric); Type: PROCEDURE; Schema: public; Owner: rupesh
--

CREATE PROCEDURE public.deposit(receiver integer, amount numeric)
    LANGUAGE plpgsql
    AS $$
declare stat VARCHAR;
BEGIN
    IF NOT EXISTS(select acc_number from has_acc where receiver=acc_number)  then
        Raise exception 'Account number does not exists!';
    ELSIF amount<=0 then
        RAISE EXCEPTION 'Not a valid amount!'; 
    END if;
    
    select status into stat from account where acc_number = receiver;
    if (stat = 'Inactive') then
        Raise exception 'Entered account is not active anymore';
    else
        UPDATE account 
        SET acc_balance = acc_balance + amount
        WHERE
        acc_number = receiver;
 
        INSERT INTO transaction(receivers_acc_number, transaction_amount)
        VALUES (receiver, amount);
    End if;
    
    COMMIT;
END; $$;


ALTER PROCEDURE public.deposit(receiver integer, amount numeric) OWNER TO rupesh;

--
-- Name: get_account_details(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_account_details(customer_id integer) RETURNS TABLE(account_number integer, account_balance numeric, account_type character varying)
    LANGUAGE plpgsql
    AS $$
declare 
countt integer;
BEGIN
	IF NOT EXISTS(select cust_id from customer where customer_id=cust_id) then 
		RAISE EXCEPTION 'customer_id doesn’t exist in the database';
	
	ELSIF NOT EXISTS(select cust_id from has_acc where customer_id=cust_id) then 
		RAISE EXCEPTION 'No account exist for this customer in the database';
	end if;
	
	select count(*) into countt from account, has_acc 
	where has_acc.cust_id = customer_id and account.acc_number = has_acc.acc_number and account.status = 'Active';
	
	IF (countt = 0)then 
		RAISE EXCEPTION 'No active account exist in the database';
	else 
	return query 
		select account.acc_number, account.acc_balance, account.acc_type from account, has_acc 
		where has_acc.cust_id = customer_id and account.acc_number = has_acc.acc_number and account.status = 'Active';
END IF;
END;
$$;


ALTER FUNCTION public.get_account_details(customer_id integer) OWNER TO postgres;

--
-- Name: get_customer_details(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_customer_details(customer_id integer) RETURNS TABLE(first_name character varying, last_name character varying, phone_number numeric, dob date, street character varying, city character varying, pincode numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
IF NOT EXISTS(select cust_id from customer where customer_id=cust_id) then 
RAISE EXCEPTION 'customer_id doesn’t exist in the database';
else
return query
select customer.first_name, customer.last_name, customer.phone_number, customer.dob, address.street, address.city, address.pincode
from customer, address
where customer.cust_id = customer_id and customer.address_id = address.address_id ;


END IF;
END;
$$;


ALTER FUNCTION public.get_customer_details(customer_id integer) OWNER TO postgres;

--
-- Name: get_employee_details(integer); Type: FUNCTION; Schema: public; Owner: aditya
--

CREATE FUNCTION public.get_employee_details(employee_id integer) RETURNS TABLE(first_name character varying, last_name character varying, phone_no numeric, dob date, manager_first_name character varying, manager_last_name character varying, street character varying, city character varying, pincode numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE 
 Id INT;
BEGIN
 IF NOT EXISTS(select emp_id from employee where employee_id=emp_id) then 
RAISE EXCEPTION 'employee_id doesn’t exist in the database';
End if;
SELECT manager_id INTO id FROM employee where emp_id = employee_id;
 If exists (SELECT manager_id  FROM employee where emp_id =  employee_id) then 
     RETURN QUERY 
SELECT employee.first_name, employee.last_name, employee.phone_no, employee.dob,
manager.first_name, manager.last_name, address.city, address.street, address.pincode 
FROM employee, employee AS manager, address
WHERE employee.emp_id = employee_id and manager.emp_id = employee.manager_id and employee.address_id = address.address_id;
 Else
 RETURN QUERY
 

select employee.first_name, employee.last_name, manager.first_name = null  , manager.last_name = null , address.street, address.city  from employee, employee as manager, address where employee.emp_id = '1' and address.address_id = employee.address_id;

 End if;

END;
$$;


ALTER FUNCTION public.get_employee_details(employee_id integer) OWNER TO aditya;

--
-- Name: get_loan_details(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_loan_details(customer_id integer) RETURNS TABLE(loan_number integer, loan_amount numeric, branch_id integer, loan_years integer, loan_interest numeric, loan_timestamp timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
declare 
countt integer;

BEGIN
IF NOT EXISTS(select cust_id from customer where customer.cust_id = customer_id) then 
RAISE EXCEPTION 'customer doesn’t exist in the database';
ELSIF NOT EXISTS (select cust_id from borrower where borrower.cust_id = customer_id) then 
	raise exception 'No loan exist for this customer';
END IF;
select count(*) into countt from loan, borrower 
where borrower.cust_id = customer_id and loan.loan_number = borrower.loan_number and loan.loan_amount > 0;


IF(countt = 0) then 
	raise exception 'all loans are cleared for this customer';
Else 
    RETURN QUERY
		select loan.loan_number, loan.loan_amount, loan.branch_id, loan.loan_years, loan.loan_interest, loan.loan_timestamp from loan, borrower 
		where borrower.cust_id = customer_id and loan.loan_number = borrower.loan_number and loan.loan_amount > 0;

		
End if;
END;
$$;


ALTER FUNCTION public.get_loan_details(customer_id integer) OWNER TO postgres;

--
-- Name: hire_employee(character varying, character varying, numeric, character varying, date, integer, numeric, character varying, character varying, numeric); Type: FUNCTION; Schema: public; Owner: aditya
--

CREATE FUNCTION public.hire_employee(f_name character varying, l_name character varying, p_no numeric, gen character varying, db date, manag_id integer, sal numeric, srt character varying, ct character varying, pc numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
a_id int;
begin
if (p_no<1000000000 or p_no > 9999999999) then
raise exception 'Not a valid phone number!';
elsif (db >= current_date - '18 years' :: interval) then 
raise exception 'Age of the employee is less than 18 years';
end if;
if not exists(select * from address where street=srt and city=ct and pc=pincode) then
insert into address (street,city,pincode) values(srt,ct,pc);
end if;
select address_id into a_id from address where street=srt and city=ct and pc=pincode;
insert into employee (first_name,last_name,phone_no,gender,dob,emp_salary,manager_id,address_id) values(f_name,l_name,p_no,gen,db,sal,manag_id,a_id);
return 1;end;
$$;


ALTER FUNCTION public.hire_employee(f_name character varying, l_name character varying, p_no numeric, gen character varying, db date, manag_id integer, sal numeric, srt character varying, ct character varying, pc numeric) OWNER TO aditya;

--
-- Name: loan_completion(); Type: FUNCTION; Schema: public; Owner: rupesh
--

CREATE FUNCTION public.loan_completion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    if(new.loan_amount = 0) then
        RAISE NOTICE 'Total Loan amount has been paid';
    end if;
    return new;
END;
$$;


ALTER FUNCTION public.loan_completion() OWNER TO rupesh;

--
-- Name: loan_payment(integer, numeric); Type: PROCEDURE; Schema: public; Owner: rupesh
--

CREATE PROCEDURE public.loan_payment(loan_id integer, amount numeric)
    LANGUAGE plpgsql
    AS $$
declare
amt NUMERIC;

BEGIN
    IF NOT EXISTS(select loan_number from loan where loan_id=loan_number)  then
        Raise exception 'No loan exist with this loan id!';
    Elsif amount <= 0 then
        Raise exception 'Invalid amount';
    END IF;
    
    select loan_amount into amt from loan where loan_number = loan_id;
    if amt = 0 then
        RAISE NOTICE 'Total loan amount has already been paid';
        return;
    ELsif amt < amount then
        UPDATE loan
        SET loan_amount = 0
        WHERE loan_number = loan_id;
        
        INSERT INTO payment(loan_number, amount)
        VALUES (loan_id, amt);
    Else 
        UPDATE loan 
        SET loan_amount = loan_amount - amount
        WHERE
        loan_number = loan_id;
 
     INSERT INTO payment(loan_number, amount)
     VALUES (loan_id, amount);
End if;
     COMMIT;
END; $$;


ALTER PROCEDURE public.loan_payment(loan_id integer, amount numeric) OWNER TO rupesh;

--
-- Name: open_account(character varying[], character varying[], character varying[], date[], numeric[], character varying[], character varying[], integer[], character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.open_account(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], a_type character varying, b_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
declare 
n integer := array_length(f_name, 1);
add_id integer[];
customer_id integer [];
a_number integer;
tempp integer;
begin 
-- 	n = array_length(f_name, 1);
	if not exists (select branch_id from branch where branch_id = b_id) then 
	raise exception 'Invalid branch id ';
	end if;
-- 	checking corner cases 
	for i in 1..n
	loop
	
		if (dob_[i] >= CURRENT_DATE - '18 years'::interval) then 
		raise exception 'Not eligible to open account due to age constraint';
		end if;
		if ((p_number[i] <= 999999999 OR p_number[i] > 9999999999)) then 
		raise exception 'Phone number of customer is not valid';
		end if;
	end loop;
	
-- 	using the for loop here to check address exist or not 
for i in 1..n
	loop
 		if not exists (select address_id from address where street = str[i] and city = ct[i] and pincode = pin[i]) then 
 			insert into address (street, city, pincode) values (str[i], ct[i], pin[i]);
			select address_id into tempp from address where street = str[i] and city = ct[i] and pincode = pin[i];
			add_id[i] = tempp;
		else
			select address_id into tempp from address where street = str[i] and city = ct[i] and pincode = pin[i];
			add_id[i] = tempp;
 		end if;
 		
 end loop;


	
 	for i in 1..n
 	loop
 		if not exists (select cust_id from customer where first_name = f_name[i] and last_name = l_name[i] and dob = dob_[i] and
					  phone_number = p_number[i] and address_id = add_id[i]) then 
					  insert into customer (gender, first_name, last_name, dob, phone_number, address_id) values 
					  (gen[i], f_name[i], l_name[i], dob_[i], p_number[i], add_id[i]);
		end if;				  
		  select cust_id into tempp from customer where first_name = f_name[i] and last_name = l_name[i] and dob = dob_[i] and
		  phone_number = p_number[i] and address_id = add_id[i];
			customer_id[i] = tempp;
 	end loop;
	if (a_type = 'Savings') then 
	insert into account (acc_balance, interest_rate, acc_type, branch_id, status) values (0, 5, a_type, b_id, 'Active');
	else 
		insert into account (acc_balance, interest_rate, acc_type, branch_id, status) values (0, 0, a_type, b_id, 'Active');
	END IF;
-- 	select acc_number into a_number from account where 
	select acc_number INTO a_number from account where acc_number = (select max(acc_number) from account);
	
	for i in 1..n
 	loop
 		insert into has_acc values (customer_id[i], a_number);
 	end loop;

	return 1;

end;
$$;


ALTER FUNCTION public.open_account(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], a_type character varying, b_id integer) OWNER TO postgres;

--
-- Name: open_loan(character varying[], character varying[], character varying[], date[], numeric[], character varying[], character varying[], integer[], integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.open_loan(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], l_years integer, l_amount numeric, b_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
declare 
n integer := array_length(f_name, 1);
add_id integer[];
customer_id integer [];
l_number integer;
tempp integer;
begin 
-- 	n = array_length(f_name, 1);
	if (l_amount <=0) then 
	raise exception 'Not a valid amount';
	elsif (l_years  <= 0) then 
	raise exception 'not a valid time span for loan';
	end if;
	if not exists (select branch_id from branch where branch_id = b_id) then 
	raise exception 'Invalid branch id ';
	end if;
-- 	checking corner cases 
	for i in 1..n
	loop
	
		if (dob_[i] >= CURRENT_DATE - '18 years'::interval) then 
		raise exception 'Not eligible to open account due to age constraint';
		end if;
		if ((p_number[i] <= 999999999 OR p_number[i] > 9999999999)) then 
		raise exception 'Phone number of customer is not valid';
		end if;
	end loop;
	
-- 	using the for loop here to check address exist or not 
for i in 1..n
	loop
 		if not exists (select address_id from address where street = str[i] and city = ct[i] and pincode = pin[i]) then 
 			insert into address (street, city, pincode) values (str[i], ct[i], pin[i]);
			select address_id into tempp from address where street = str[i] and city = ct[i] and pincode = pin[i];
			add_id[i] = tempp;
		else
			select address_id into tempp from address where street = str[i] and city = ct[i] and pincode = pin[i];
			add_id[i] = tempp;
 		end if;
 		
 end loop;


	
 	for i in 1..n
 	loop
 		if not exists (select cust_id from customer where first_name = f_name[i] and last_name = l_name[i] and dob = dob_[i] and
					  phone_number = p_number[i] and address_id = add_id[i]) then 
					  insert into customer (gender, first_name, last_name, dob, phone_number, address_id) values 
					  (gen[i], f_name[i], l_name[i], dob_[i], p_number[i], add_id[i]);
		end if;				  
		  select cust_id into tempp from customer where first_name = f_name[i] and last_name = l_name[i] and dob = dob_[i] and
		  phone_number = p_number[i] and address_id = add_id[i];
			customer_id[i] = tempp;
 	end loop;
	
	insert into loan (loan_amount, branch_id, loan_years, loan_interest) values (l_amount, b_id, l_years, 8);
-- 	select acc_number into a_number from account where 
	select loan_number INTO l_number from loan where loan_number = (select max(loan_number) from loan);
	
	for i in 1..n
 	loop
 		insert into borrower values (customer_id[i], l_number);
 	end loop;

	return 1;

end;
$$;


ALTER FUNCTION public.open_loan(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], l_years integer, l_amount numeric, b_id integer) OWNER TO postgres;

--
-- Name: transfer(integer, integer, numeric); Type: PROCEDURE; Schema: public; Owner: rupesh
--

CREATE PROCEDURE public.transfer(sender integer, receiver integer, amount numeric)
    LANGUAGE plpgsql
    AS $$
Declare
account_balance integer;
stat VARCHAR;
BEGIN
    IF NOT EXISTS(select acc_number from has_acc where sender=acc_number)  then
        Raise exception 'Sender’s Account number does not exists!';
    Elsif  NOT EXISTS(select acc_number from has_acc where receiver=acc_number)  then
        Raise exception 'Receivers Account number does not exists!';
    End if;
     
    select acc_balance into account_balance  from account where acc_number = sender;
    IF amount<=0 then
        RAISE EXCEPTION 'Not a valid amount!'; 
    end if;
    
    
    select status into stat from account where acc_number = sender;
    if (stat = 'Inactive') then
        Raise exception 'Entered Sender account is not active anymore';
    end if;
    
    select status into stat from account where acc_number = receiver;
    if (stat = 'Inactive') then
        Raise exception 'Entered Receiver account is not active anymore';
    ELSIF account_balance < amount then 
        Raise exception 'Not enough balance!';
    else
        UPDATE account 
        SET acc_balance = acc_balance - amount
        WHERE acc_number = sender;
    
        UPDATE account 
        SET acc_balance = acc_balance + amount
        WHERE acc_number = receiver;
     
        INSERT INTO transaction (senders_acc_number, receivers_acc_number, transaction_amount)
        VALUES(sender, receiver, amount);
    END IF;
    COMMIT;
END;  $$;


ALTER PROCEDURE public.transfer(sender integer, receiver integer, amount numeric) OWNER TO rupesh;

--
-- Name: withdraw(integer, numeric); Type: PROCEDURE; Schema: public; Owner: rupesh
--

CREATE PROCEDURE public.withdraw(account_no integer, amount numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
account_balance integer; 
stat VARCHAR;
BEGIN
    select acc_balance into account_balance  from account where acc_number = account_no;
    IF NOT EXISTS(select acc_number from has_acc where account_no=acc_number)  then
        Raise exception 'Account number does not exists!';
    ELSIF amount<=0 then
        RAISE EXCEPTION 'Not a valid amount!'; 
    END if;
    
    select status into stat from account where acc_number = account_no;
    if (stat = 'Inactive') then
        Raise exception 'Entered account is not active anymore';
    ELSIF account_balance < amount then 
        Raise exception 'Not enough balance!';
    else
        UPDATE account 
        SET acc_balance = acc_balance - amount
        WHERE
        acc_number = account_no;
 
        INSERT INTO transaction(senders_acc_number, transaction_amount)
        VALUES (account_no, amount);
    End if;
    COMMIT;
END; $$;


ALTER PROCEDURE public.withdraw(account_no integer, amount numeric) OWNER TO rupesh;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.account (
    acc_number integer NOT NULL,
    acc_balance numeric NOT NULL,
    interest_rate numeric,
    acc_type character varying(50) NOT NULL,
    branch_id integer,
    status character varying DEFAULT 'Active'::character varying NOT NULL,
    CONSTRAINT account_acc_balance_check CHECK ((acc_balance >= (0)::numeric)),
    CONSTRAINT account_acc_type_check CHECK ((((acc_type)::text = 'Savings'::text) OR ((acc_type)::text = 'Current'::text))),
    CONSTRAINT account_interest_rate_check CHECK (((interest_rate >= (0)::numeric) AND (interest_rate <= (100)::numeric))),
    CONSTRAINT account_status_check CHECK (((status)::text = ANY (ARRAY[('Active'::character varying)::text, ('Inactive'::character varying)::text])))
);


ALTER TABLE public.account OWNER TO rupesh;

--
-- Name: account_acc_number_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.account_acc_number_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_acc_number_seq OWNER TO rupesh;

--
-- Name: account_acc_number_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.account_acc_number_seq OWNED BY public.account.acc_number;


--
-- Name: account_accountant; Type: VIEW; Schema: public; Owner: aditya
--

CREATE VIEW public.account_accountant AS
 SELECT account.acc_number,
    account.acc_balance,
    account.interest_rate,
    account.acc_type,
    account.branch_id,
    account.status
   FROM public.account;


ALTER TABLE public.account_accountant OWNER TO aditya;

--
-- Name: account_cashier; Type: VIEW; Schema: public; Owner: aditya
--

CREATE VIEW public.account_cashier AS
 SELECT account.acc_number,
    account.acc_balance,
    account.interest_rate,
    account.acc_type,
    account.status
   FROM public.account;


ALTER TABLE public.account_cashier OWNER TO aditya;

--
-- Name: address; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.address (
    address_id integer NOT NULL,
    street character varying(50) NOT NULL,
    city character varying(50) NOT NULL,
    pincode numeric(6,0) NOT NULL,
    CONSTRAINT pincode_constraint CHECK (((pincode > (99999)::numeric) AND (pincode <= (999999)::numeric)))
);


ALTER TABLE public.address OWNER TO rupesh;

--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.address_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_address_id_seq OWNER TO rupesh;

--
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.address_address_id_seq OWNED BY public.address.address_id;


--
-- Name: borrower; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.borrower (
    cust_id integer,
    loan_number integer
);


ALTER TABLE public.borrower OWNER TO rupesh;

--
-- Name: branch; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.branch (
    branch_id integer NOT NULL,
    branch_name character varying(50) NOT NULL,
    address_id integer
);


ALTER TABLE public.branch OWNER TO rupesh;

--
-- Name: branch_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.branch_branch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.branch_branch_id_seq OWNER TO rupesh;

--
-- Name: branch_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.branch_branch_id_seq OWNED BY public.branch.branch_id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.customer (
    cust_id integer NOT NULL,
    gender character varying(10) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    dob date NOT NULL,
    phone_number numeric NOT NULL,
    address_id integer,
    CONSTRAINT customer_dob_check CHECK ((dob <= CURRENT_DATE)),
    CONSTRAINT customer_gender_check CHECK (((gender)::text = ANY (ARRAY[('Male'::character varying)::text, ('Female'::character varying)::text, ('Other'::character varying)::text]))),
    CONSTRAINT customer_phone_number_check CHECK (((phone_number >= (1000000000)::numeric) AND (phone_number <= ('9999999999'::bigint)::numeric))),
    CONSTRAINT dob_cons CHECK ((dob <= (CURRENT_DATE - '18 years'::interval)))
);


ALTER TABLE public.customer OWNER TO rupesh;

--
-- Name: customer_accountant; Type: VIEW; Schema: public; Owner: aditya
--

CREATE VIEW public.customer_accountant AS
 SELECT customer.cust_id,
    customer.gender,
    customer.first_name,
    customer.last_name,
    customer.dob,
    customer.phone_number,
    customer.address_id
   FROM public.customer;


ALTER TABLE public.customer_accountant OWNER TO aditya;

--
-- Name: customer_cust_id_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.customer_cust_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_cust_id_seq OWNER TO rupesh;

--
-- Name: customer_cust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.customer_cust_id_seq OWNED BY public.customer.cust_id;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.employee (
    emp_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone_no numeric NOT NULL,
    gender character varying(10) NOT NULL,
    dob date NOT NULL,
    hire_date date DEFAULT CURRENT_DATE NOT NULL,
    manager_id integer,
    address_id integer,
    emp_salary numeric NOT NULL,
    status character varying DEFAULT 'Active'::character varying NOT NULL,
    CONSTRAINT dob_emp_cons CHECK ((dob <= (CURRENT_DATE - '20 years'::interval))),
    CONSTRAINT emp_manager_id CHECK ((emp_id <> manager_id)),
    CONSTRAINT emp_status_cons CHECK ((((status)::text = 'Active'::text) OR ((status)::text = 'Inactive'::text))),
    CONSTRAINT employee_dob_check CHECK ((dob < CURRENT_DATE)),
    CONSTRAINT employee_emp_salary_check CHECK ((emp_salary > (0)::numeric)),
    CONSTRAINT employee_gender_check CHECK (((gender)::text = ANY (ARRAY[('Other'::character varying)::text, ('Male'::character varying)::text, ('Female'::character varying)::text]))),
    CONSTRAINT employee_hire_date_check CHECK ((hire_date <= CURRENT_DATE)),
    CONSTRAINT employee_phone_no_check CHECK (((phone_no >= (1000000000)::numeric) AND (phone_no <= ('9999999999'::bigint)::numeric)))
);


ALTER TABLE public.employee OWNER TO rupesh;

--
-- Name: employee_emp_id_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.employee_emp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_emp_id_seq OWNER TO rupesh;

--
-- Name: employee_emp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.employee_emp_id_seq OWNED BY public.employee.emp_id;


--
-- Name: employee_rcm; Type: VIEW; Schema: public; Owner: aditya
--

CREATE VIEW public.employee_rcm AS
 SELECT employee.emp_id,
    employee.first_name,
    employee.last_name,
    employee.phone_no,
    employee.gender,
    employee.dob,
    employee.hire_date,
    employee.manager_id,
    employee.address_id,
    employee.emp_salary,
    employee.status
   FROM public.employee;


ALTER TABLE public.employee_rcm OWNER TO aditya;

--
-- Name: has_acc; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.has_acc (
    cust_id integer NOT NULL,
    acc_number integer
);


ALTER TABLE public.has_acc OWNER TO rupesh;

--
-- Name: has_acc_accountant; Type: VIEW; Schema: public; Owner: aditya
--

CREATE VIEW public.has_acc_accountant AS
 SELECT has_acc.cust_id,
    has_acc.acc_number
   FROM public.has_acc;


ALTER TABLE public.has_acc_accountant OWNER TO aditya;

--
-- Name: loan; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.loan (
    loan_number integer NOT NULL,
    loan_amount numeric NOT NULL,
    branch_id integer,
    loan_years integer NOT NULL,
    loan_interest numeric NOT NULL,
    loan_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT loan_loan_amount_check CHECK ((loan_amount >= (0)::numeric)),
    CONSTRAINT loan_loan_interest_check CHECK (((loan_interest > (0)::numeric) AND (loan_interest <= (100)::numeric))),
    CONSTRAINT loan_loan_years_check CHECK ((loan_years > 0))
);


ALTER TABLE public.loan OWNER TO rupesh;

--
-- Name: loan_loan_number_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.loan_loan_number_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_loan_number_seq OWNER TO rupesh;

--
-- Name: loan_loan_number_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.loan_loan_number_seq OWNED BY public.loan.loan_number;


--
-- Name: payment; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.payment (
    payment_id integer NOT NULL,
    amount numeric NOT NULL,
    payment_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    loan_number integer,
    CONSTRAINT payment_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.payment OWNER TO rupesh;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: rupesh
--

CREATE SEQUENCE public.payment_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_payment_id_seq OWNER TO rupesh;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rupesh
--

ALTER SEQUENCE public.payment_payment_id_seq OWNED BY public.payment.payment_id;


--
-- Name: transaction; Type: TABLE; Schema: public; Owner: rupesh
--

CREATE TABLE public.transaction (
    transaction_id uuid DEFAULT uuid_in((md5(((random())::text || (clock_timestamp())::text)))::cstring) NOT NULL,
    transaction_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    senders_acc_number integer,
    receivers_acc_number integer,
    transaction_amount numeric,
    CONSTRAINT transaction_transaction_amount_check CHECK ((transaction_amount >= (0)::numeric))
);


ALTER TABLE public.transaction OWNER TO rupesh;

--
-- Name: account acc_number; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.account ALTER COLUMN acc_number SET DEFAULT nextval('public.account_acc_number_seq'::regclass);


--
-- Name: address address_id; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.address ALTER COLUMN address_id SET DEFAULT nextval('public.address_address_id_seq'::regclass);


--
-- Name: branch branch_id; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.branch ALTER COLUMN branch_id SET DEFAULT nextval('public.branch_branch_id_seq'::regclass);


--
-- Name: customer cust_id; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.customer ALTER COLUMN cust_id SET DEFAULT nextval('public.customer_cust_id_seq'::regclass);


--
-- Name: employee emp_id; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.employee ALTER COLUMN emp_id SET DEFAULT nextval('public.employee_emp_id_seq'::regclass);


--
-- Name: loan loan_number; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.loan ALTER COLUMN loan_number SET DEFAULT nextval('public.loan_loan_number_seq'::regclass);


--
-- Name: payment payment_id; Type: DEFAULT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.payment ALTER COLUMN payment_id SET DEFAULT nextval('public.payment_payment_id_seq'::regclass);


--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.account (acc_number, acc_balance, interest_rate, acc_type, branch_id, status) FROM stdin;
\.
COPY public.account (acc_number, acc_balance, interest_rate, acc_type, branch_id, status) FROM '$$PATH$$/3285.dat';

--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.address (address_id, street, city, pincode) FROM stdin;
\.
COPY public.address (address_id, street, city, pincode) FROM '$$PATH$$/3287.dat';

--
-- Data for Name: borrower; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.borrower (cust_id, loan_number) FROM stdin;
\.
COPY public.borrower (cust_id, loan_number) FROM '$$PATH$$/3289.dat';

--
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.branch (branch_id, branch_name, address_id) FROM stdin;
\.
COPY public.branch (branch_id, branch_name, address_id) FROM '$$PATH$$/3290.dat';

--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.customer (cust_id, gender, first_name, last_name, dob, phone_number, address_id) FROM stdin;
\.
COPY public.customer (cust_id, gender, first_name, last_name, dob, phone_number, address_id) FROM '$$PATH$$/3292.dat';

--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.employee (emp_id, first_name, last_name, phone_no, gender, dob, hire_date, manager_id, address_id, emp_salary, status) FROM stdin;
\.
COPY public.employee (emp_id, first_name, last_name, phone_no, gender, dob, hire_date, manager_id, address_id, emp_salary, status) FROM '$$PATH$$/3294.dat';

--
-- Data for Name: has_acc; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.has_acc (cust_id, acc_number) FROM stdin;
\.
COPY public.has_acc (cust_id, acc_number) FROM '$$PATH$$/3296.dat';

--
-- Data for Name: loan; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.loan (loan_number, loan_amount, branch_id, loan_years, loan_interest, loan_timestamp) FROM stdin;
\.
COPY public.loan (loan_number, loan_amount, branch_id, loan_years, loan_interest, loan_timestamp) FROM '$$PATH$$/3297.dat';

--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.payment (payment_id, amount, payment_timestamp, loan_number) FROM stdin;
\.
COPY public.payment (payment_id, amount, payment_timestamp, loan_number) FROM '$$PATH$$/3299.dat';

--
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: rupesh
--

COPY public.transaction (transaction_id, transaction_timestamp, senders_acc_number, receivers_acc_number, transaction_amount) FROM stdin;
\.
COPY public.transaction (transaction_id, transaction_timestamp, senders_acc_number, receivers_acc_number, transaction_amount) FROM '$$PATH$$/3301.dat';

--
-- Name: account_acc_number_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.account_acc_number_seq', 1234567906, true);


--
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.address_address_id_seq', 19, true);


--
-- Name: branch_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.branch_branch_id_seq', 1001, true);


--
-- Name: customer_cust_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.customer_cust_id_seq', 12371, true);


--
-- Name: employee_emp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.employee_emp_id_seq', 16, true);


--
-- Name: loan_loan_number_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.loan_loan_number_seq', 1234566, true);


--
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rupesh
--

SELECT pg_catalog.setval('public.payment_payment_id_seq', 12345688, true);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (acc_number);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (branch_id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (cust_id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (emp_id);


--
-- Name: loan loan_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.loan
    ADD CONSTRAINT loan_pkey PRIMARY KEY (loan_number);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (transaction_id);


--
-- Name: acc_balance_idx; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX acc_balance_idx ON public.account USING btree (acc_balance);


--
-- Name: acc_number_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX acc_number_index ON public.account USING hash (acc_number);


--
-- Name: address_id_branch; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX address_id_branch ON public.branch USING hash (address_id);


--
-- Name: address_id_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX address_id_index ON public.address USING hash (address_id);


--
-- Name: branch_id_idx; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX branch_id_idx ON public.account USING hash (branch_id);


--
-- Name: branch_id_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX branch_id_index ON public.loan USING hash (branch_id);


--
-- Name: branch_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX branch_index ON public.branch USING hash (branch_id);


--
-- Name: cust_id_borrower; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX cust_id_borrower ON public.borrower USING hash (cust_id);


--
-- Name: cust_id_has_acc; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX cust_id_has_acc ON public.has_acc USING hash (cust_id);


--
-- Name: cust_id_hash; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX cust_id_hash ON public.customer USING hash (cust_id);


--
-- Name: emp_id_hash; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX emp_id_hash ON public.employee USING hash (emp_id);


--
-- Name: emp_salary_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX emp_salary_index ON public.employee USING btree (emp_salary);


--
-- Name: hire_date_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX hire_date_index ON public.employee USING btree (hire_date);


--
-- Name: loan_amount_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX loan_amount_index ON public.loan USING btree (loan_amount);


--
-- Name: loan_number_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX loan_number_index ON public.loan USING hash (loan_number);


--
-- Name: manager_id_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX manager_id_index ON public.employee USING hash (manager_id);


--
-- Name: multi_transaction; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX multi_transaction ON public.transaction USING btree (senders_acc_number, receivers_acc_number);


--
-- Name: partial_index1; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX partial_index1 ON public.account USING btree (acc_balance) WHERE ((acc_balance < (5000)::numeric) OR (acc_balance > (500000)::numeric));


--
-- Name: payment_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX payment_index ON public.payment USING hash (loan_number);


--
-- Name: pc_index; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX pc_index ON public.address USING hash (pincode);


--
-- Name: street_city_multicolumn; Type: INDEX; Schema: public; Owner: rupesh
--

CREATE INDEX street_city_multicolumn ON public.address USING gin (street, city);


--
-- Name: loan calculate_amount_trigger; Type: TRIGGER; Schema: public; Owner: rupesh
--

CREATE TRIGGER calculate_amount_trigger BEFORE INSERT ON public.loan FOR EACH ROW EXECUTE FUNCTION public.calculate_amount();


--
-- Name: loan loan_completion_trigger; Type: TRIGGER; Schema: public; Owner: rupesh
--

CREATE TRIGGER loan_completion_trigger AFTER UPDATE ON public.loan FOR EACH ROW EXECUTE FUNCTION public.loan_completion();


--
-- Name: account warn_max_min_amount; Type: TRIGGER; Schema: public; Owner: rupesh
--

CREATE TRIGGER warn_max_min_amount AFTER UPDATE ON public.account FOR EACH ROW EXECUTE FUNCTION public.check_amount();


--
-- Name: has_acc f_key_acc_number; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.has_acc
    ADD CONSTRAINT f_key_acc_number FOREIGN KEY (acc_number) REFERENCES public.account(acc_number);


--
-- Name: branch f_key_address_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT f_key_address_id FOREIGN KEY (address_id) REFERENCES public.address(address_id);


--
-- Name: customer f_key_address_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT f_key_address_id FOREIGN KEY (address_id) REFERENCES public.address(address_id);


--
-- Name: employee f_key_address_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT f_key_address_id FOREIGN KEY (address_id) REFERENCES public.address(address_id);


--
-- Name: account f_key_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT f_key_branch_id FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: loan f_key_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.loan
    ADD CONSTRAINT f_key_branch_id FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: has_acc f_key_cust_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.has_acc
    ADD CONSTRAINT f_key_cust_id FOREIGN KEY (cust_id) REFERENCES public.customer(cust_id);


--
-- Name: borrower f_key_cust_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.borrower
    ADD CONSTRAINT f_key_cust_id FOREIGN KEY (cust_id) REFERENCES public.customer(cust_id);


--
-- Name: borrower f_key_loan_number; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.borrower
    ADD CONSTRAINT f_key_loan_number FOREIGN KEY (loan_number) REFERENCES public.loan(loan_number);


--
-- Name: payment f_key_loan_number; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT f_key_loan_number FOREIGN KEY (loan_number) REFERENCES public.loan(loan_number);


--
-- Name: employee f_key_manager_id; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT f_key_manager_id FOREIGN KEY (manager_id) REFERENCES public.employee(emp_id);


--
-- Name: transaction f_key_receivers_acc_number; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT f_key_receivers_acc_number FOREIGN KEY (receivers_acc_number) REFERENCES public.account(acc_number);


--
-- Name: transaction f_key_senders_acc_number; Type: FK CONSTRAINT; Schema: public; Owner: rupesh
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT f_key_senders_acc_number FOREIGN KEY (senders_acc_number) REFERENCES public.account(acc_number);


--
-- Name: FUNCTION delete_customer_account(account_no integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.delete_customer_account(account_no integer) TO accountant;


--
-- Name: PROCEDURE deposit(receiver integer, amount numeric); Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON PROCEDURE public.deposit(receiver integer, amount numeric) TO cashier;


--
-- Name: FUNCTION get_account_details(customer_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_account_details(customer_id integer) TO cashier;
GRANT ALL ON FUNCTION public.get_account_details(customer_id integer) TO accountant;


--
-- Name: FUNCTION get_customer_details(customer_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_customer_details(customer_id integer) TO accountant;


--
-- Name: FUNCTION get_employee_details(employee_id integer); Type: ACL; Schema: public; Owner: aditya
--

GRANT ALL ON FUNCTION public.get_employee_details(employee_id integer) TO recruitment_manager;


--
-- Name: FUNCTION hire_employee(f_name character varying, l_name character varying, p_no numeric, gen character varying, db date, manag_id integer, sal numeric, srt character varying, ct character varying, pc numeric); Type: ACL; Schema: public; Owner: aditya
--

GRANT ALL ON FUNCTION public.hire_employee(f_name character varying, l_name character varying, p_no numeric, gen character varying, db date, manag_id integer, sal numeric, srt character varying, ct character varying, pc numeric) TO recruitment_manager;


--
-- Name: FUNCTION open_account(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], a_type character varying, b_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.open_account(f_name character varying[], l_name character varying[], gen character varying[], dob_ date[], p_number numeric[], str character varying[], ct character varying[], pin integer[], a_type character varying, b_id integer) TO accountant;


--
-- Name: PROCEDURE transfer(sender integer, receiver integer, amount numeric); Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON PROCEDURE public.transfer(sender integer, receiver integer, amount numeric) TO cashier;


--
-- Name: PROCEDURE withdraw(account_no integer, amount numeric); Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON PROCEDURE public.withdraw(account_no integer, amount numeric) TO cashier;


--
-- Name: TABLE account; Type: ACL; Schema: public; Owner: rupesh
--

GRANT SELECT,UPDATE ON TABLE public.account TO cashier;
GRANT SELECT,INSERT,UPDATE ON TABLE public.account TO accountant;


--
-- Name: SEQUENCE account_acc_number_seq; Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON SEQUENCE public.account_acc_number_seq TO accountant;


--
-- Name: TABLE account_accountant; Type: ACL; Schema: public; Owner: aditya
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.account_accountant TO accountant;


--
-- Name: TABLE account_cashier; Type: ACL; Schema: public; Owner: aditya
--

GRANT SELECT,UPDATE ON TABLE public.account_cashier TO cashier;


--
-- Name: TABLE customer; Type: ACL; Schema: public; Owner: rupesh
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.customer TO accountant;


--
-- Name: TABLE customer_accountant; Type: ACL; Schema: public; Owner: aditya
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.customer_accountant TO accountant;


--
-- Name: SEQUENCE customer_cust_id_seq; Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON SEQUENCE public.customer_cust_id_seq TO accountant;


--
-- Name: TABLE employee; Type: ACL; Schema: public; Owner: rupesh
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.employee TO recruitment_manager;


--
-- Name: SEQUENCE employee_emp_id_seq; Type: ACL; Schema: public; Owner: rupesh
--

GRANT ALL ON SEQUENCE public.employee_emp_id_seq TO recruitment_manager;


--
-- Name: TABLE employee_rcm; Type: ACL; Schema: public; Owner: aditya
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.employee_rcm TO recruitment_manager;


--
-- Name: TABLE has_acc; Type: ACL; Schema: public; Owner: rupesh
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.has_acc TO accountant;


--
-- Name: TABLE has_acc_accountant; Type: ACL; Schema: public; Owner: aditya
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.has_acc_accountant TO accountant;


--
-- Name: TABLE transaction; Type: ACL; Schema: public; Owner: rupesh
--

GRANT SELECT,INSERT ON TABLE public.transaction TO cashier;


--
-- PostgreSQL database dump complete
--

