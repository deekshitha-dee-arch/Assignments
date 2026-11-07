-- my sql notes
-- using sakila db (mysql 8)


-- DDL - create alter drop truncate
-- DML - insert update delete
-- DQL - select
-- DCL - grant revoke
-- TCL - commit rollback
-- schema = database in mysql basically


-- create table + insert

drop database if exists company_db;
create database company_db;

create table company_db.test_table (
  id int,
  name varchar(100)
);

insert into company_db.test_table values (1,'Alice'),(2,'Bob'),(3,'Charlie');

-- this works?? 5 becomes '5'
insert into company_db.test_table values (5, 5);

-- this one errors, joey is not int
-- insert into company_db.test_table values ('joey', 5);

select * from company_db.test_table;

ALTER TABLE company_db.test_table add email varchar(255);
alter table company_db.test_table rename column email to email_id;

select * from company_db.test_table;


-- constraints

create table company_db.Persons (
  ID int not null unique,
  LastName varchar(255) not null,
  FirstName varchar(255),
  Age int
);

insert into company_db.Persons values (1,'Smith','John',30);
insert into company_db.Persons values (2,'Doe',null,null);   -- null ok here

-- error, duplicate id
-- insert into company_db.Persons values (1,'Brown','Charlie',25);
-- error, lastname not null
-- insert into company_db.Persons values (3,null,'Alice',28);

-- pk = not null + unique, only one per table
alter table company_db.Persons add primary key (ID);

-- to see constraints
SELECT constraint_name FROM information_schema.table_constraints
WHERE table_schema = 'sakila' AND table_name = 'actor';

-- foreign key -> child points to parent pk
create table company_db.Orders (
  OrderID int primary key,
  OrderDate date,
  PersonID int,
  foreign key (PersonID) references company_db.Persons(ID)
    on delete restrict
    on update cascade
);

insert into company_db.Orders values (1001,'2024-06-10',1);

-- error, 999 not in persons
-- insert into company_db.Orders values (1002,'2024-06-11',999);

-- error bc of restrict
-- delete from company_db.Persons where ID = 1;

update company_db.Persons set ID = 4 where ID = 1;  -- orders also changes to 4 (cascade)
select * from company_db.Persons;
select * from company_db.Orders;

-- check + default
create table company_db.employee (
  ID int,
  name varchar(100),
  Age int check (Age >= 18),
  city varchar(100) default 'new york'
);

insert into company_db.employee values (1,'joey',19,'texas');
insert into company_db.employee (ID,name,Age) values (2,'jim',22);
-- age 17 fails
-- insert into company_db.employee (ID,name,Age) values (3,'chandler',17);
select * from company_db.employee;

-- delete = rows, truncate = all rows table stays, drop = table gone
set sql_safe_updates = 0;   -- workbench wont let delete without this
delete from company_db.test_table where id = 1;
truncate table company_db.employee;

drop table company_db.Orders;   -- drop child first
drop database company_db;


-- select basics

select * from sakila.actor;
select actor_id, last_name from sakila.actor;
select distinct first_name from sakila.actor;

select count(first_name) from sakila.actor;
select count(distinct first_name) from sakila.actor;   -- less than above

select * from sakila.actor where first_name = 'PENELOPE';

select first_name, last_name from sakila.actor limit 10;

select distinct rating from sakila.film;
select * from sakila.film where rating = 'R' and length >= 92;
select * from sakila.film where rating = 'PG' or rental_duration = 5;

-- not
select * from sakila.film where rental_duration not in (6,4,7);
select * from sakila.film where rental_duration != 6;

-- brackets matter
select * from sakila.film
where rental_duration = 6 and (rating = 'G' or rating = 'PG');

select title, rental_rate from sakila.film order by rental_rate desc;

-- like  % any chars  _ one char
select city from sakila.city where city like 'a%';
select title from sakila.film where title like '%super%';
select title from sakila.film where title like '__s_s%';

-- null -> is null not = null
select * from sakila.rental where return_date is null;

select * from sakila.rental
where return_date between '2005-05-26' and '2005-05-30';  -- includes both dates


-- group by having
-- order: from > join > where > group by > having > select > order by > limit
-- where filters rows, having filters groups

select first_name, count(*)
from sakila.actor
group by first_name
having count(*) > 1;   -- duplicates

-- customers with less than 3 rentals not returned
select customer_id, count(rental_id) as cnt
from sakila.rental
where return_date is null
group by customer_id
having count(rental_id) < 3
order by cnt desc;

select customer_id, sum(amount) as total
from sakila.payment
group by customer_id
having sum(amount) > 100;


-- dates

select rental_id, rental_date, return_date, datediff(return_date, rental_date) as days
from sakila.rental
where return_date is not null;

select last_update, month(last_update), monthname(last_update) from sakila.film;

select date(payment_date), sum(amount)
from sakila.payment
group by date(payment_date);

select now(), curdate(), current_time;

-- last 24 hrs gives nothing, data is old (2005)
select * from sakila.payment where payment_date >= now() - interval 1 day;

select max(payment_date) from sakila.payment;

-- so use max date instead
select customer_id, amount, payment_date
from sakila.payment
where payment_date >= (select max(payment_date) - interval 2 day from sakila.payment);


-- subquery

select customer_id, amount
from sakila.payment
where amount > (select avg(amount) from sakila.payment);

select avg(amount) from sakila.payment;  -- checking

select actor_id, first_name
from sakila.actor
where actor_id in (
  select actor_id from sakila.film_actor
  group by actor_id
  having count(*) >= 10
);

-- in select it should give only 1 value, else error so limit 1
select first_name,
  (select address_id from sakila.address where district = 'California' limit 1) as cali
from sakila.customer;

-- correlated - runs for each row
select title,
  (select count(*) from sakila.film_actor fa where fa.film_id = f.film_id) as actors
from sakila.film f;

-- payments more than that customers own avg
select payment_id, customer_id, amount
from sakila.payment t1
where amount > (
  select avg(amount) from sakila.payment t2
  where t2.customer_id = t1.customer_id
);

-- derived table, needs alias
select * from (
  select customer_id, sum(amount) as total
  from sakila.payment
  group by customer_id
) t
order by total desc;

-- case
select * from (
  select last_name,
    case
      when left(last_name,1) between 'A' and 'M' then 'A-M'
      else 'N-Z'
    end as grp
  from sakila.customer
) x
where grp = 'N-Z'
limit 15;


-- cte
-- temp result just for that query, easier to read than subquery

with totals as (
  select customer_id, sum(amount) as total
  from sakila.payment
  group by customer_id
)
select * from totals
where total > (select avg(total) from totals);

with payment_counts as (
  select customer_id, count(*) as total_payments
  from sakila.payment
  group by customer_id
)
select c.first_name, c.last_name, p.total_payments
from sakila.customer c
join payment_counts p on c.customer_id = p.customer_id
where p.total_payments > 5;

-- 2 ctes
with tp as (
  select customer_id, sum(amount) as total from sakila.payment group by customer_id
),
lp as (
  select customer_id, max(payment_date) as last_pay from sakila.payment group by customer_id
)
select c.customer_id, c.first_name, tp.total, lp.last_pay
from sakila.customer c
left join tp on c.customer_id = tp.customer_id
left join lp on c.customer_id = lp.customer_id;

-- recursive
with recursive nums as (
  select 1 as n          -- start
  union all
  select n+1 from nums where n < 20    -- stop at 20
)
select * from nums;

-- rentals for last 10 days
with recursive dates as (
  select date(max(rental_date)) - interval 9 day as d from sakila.rental
  union all
  select d + interval 1 day from dates
  where d + interval 1 day <= (select date(max(rental_date)) from sakila.rental)
)
select dates.d, count(r.rental_id) as rentals
from dates
left join sakila.rental r on date(r.rental_date) = dates.d
group by dates.d;


-- joins tables

drop database if exists joins;
create database joins;

create table joins.users (user_id int primary key, user_name varchar(50));
insert into joins.users values (1,'Alice'),(2,'Bob'),(3,'Charlie'),(4,'David'),(5,'Eve'),(6,'NULL_User');

create table joins.orders (order_id int primary key, user_id int, order_status char(1));
insert into joins.orders values (101,1,'A'),(102,2,'B'),(103,2,'C'),(104,3,'A'),(105,null,'B'),(106,6,'C'),(108,null,null);

create table joins.products (product_id int primary key, order_id int, product_name varchar(50));
insert into joins.products values (201,101,'Pen'),(202,102,'Book'),(203,103,'Bag'),(204,106,'Laptop'),(205,null,null),(206,102,'Marker');

create table joins.user_profiles (user_id int primary key, profile_status varchar(20));
insert into joins.user_profiles values (1,'Active'),(2,'Inactive'),(4,'Active');

create table joins.friendships (user_id int, friend_id int);
insert into joins.friendships values (1,2),(2,1),(2,3),(4,5),(5,1);

alter table joins.orders add constraint fk_orders_users foreign key (user_id) references joins.users(user_id);

select * from joins.users;
select * from joins.orders;


-- 1:1 users - profiles
select u.user_id, u.user_name, p.profile_status
from joins.users u
join joins.user_profiles p on u.user_id = p.user_id;

-- 1:many one user many orders

-- inner
select u.user_name, o.order_id
from joins.users u
join joins.orders o on u.user_id = o.user_id;

-- left
select u.user_name, o.order_id
from joins.users u
left join joins.orders o on u.user_id = o.user_id;

-- users with no orders
select u.user_name
from joins.users u
left join joins.orders o on u.user_id = o.user_id
where o.user_id is null;

-- orders with no user
select o.order_id, o.user_id
from joins.orders o
left join joins.users u on o.user_id = u.user_id
where u.user_id is null;

-- right
select u.user_name, o.order_id
from joins.users u
right join joins.orders o on u.user_id = o.user_id;

-- full outer - not in mysql so union
select u.user_name, o.order_id from joins.users u left join joins.orders o on u.user_id = o.user_id
union
select u.user_name, o.order_id from joins.users u right join joins.orders o on u.user_id = o.user_id;

-- cross, 6 x 7 = 42 rows
select u.user_name, o.order_id from joins.users u cross join joins.orders o;

-- self join (friends) / many to many
select u.user_name as user, f.user_name as friend
from joins.friendships fs
join joins.users u on fs.user_id = u.user_id
join joins.users f on fs.friend_id = f.user_id;

-- 3 tables
select u.user_name, o.order_id, p.product_name
from joins.users u
join joins.orders o on u.user_id = o.user_id
join joins.products p on o.order_id = p.order_id;


-- temp table - only for this session

drop temporary table if exists sakila.top_categories;

create temporary table sakila.top_categories as
select c.name, c.category_id, count(*) as rentals
from sakila.rental r
join sakila.inventory i on r.inventory_id = i.inventory_id
join sakila.film_category fc on i.film_id = fc.film_id
join sakila.category c on c.category_id = fc.category_id
group by c.name, c.category_id
order by rentals desc
limit 5;

select * from sakila.top_categories;

-- can join it too
select tc.name, fc.film_id
from sakila.top_categories tc
join sakila.film_category fc on fc.category_id = tc.category_id;


-- view - saved query, no data stored
-- also used to hide columns

create or replace view sakila.recent_rentals as
select customer_id, max(rental_date) as last_rental
from sakila.rental
group by customer_id;

select * from sakila.recent_rentals;

select c.first_name, rr.last_rental
from sakila.customer c
join sakila.recent_rentals rr on c.customer_id = rr.customer_id;

create or replace view sakila.customer_public_view as
select customer_id, first_name, last_name, email from sakila.customer;

select * from sakila.customer_public_view;
-- note: if u alias columns in view, use alias name when querying


-- procedures
-- in = input, out = output
-- delimiter // so the ; inside doesnt break it

drop procedure if exists sakila.GetCustomerPayments;
drop procedure if exists sakila.TotalPaid;
drop procedure if exists sakila.DynamicQuery;

delimiter //

create procedure sakila.GetCustomerPayments(in cid int)
begin
  select * from sakila.payment where customer_id = cid;
end //

create procedure sakila.TotalPaid(in cid int, out total decimal(10,2))
begin
  select sum(amount) into total from sakila.payment where customer_id = cid;
end //

-- dynamic - query as string
create procedure sakila.DynamicQuery(in tbl varchar(64))
begin
  set @s = concat('select count(*) from ', tbl);
  prepare stmt from @s;
  execute stmt;
  deallocate prepare stmt;
end //

delimiter ;

call sakila.GetCustomerPayments(12);

call sakila.TotalPaid(8, @total);
select @total;

call sakila.DynamicQuery('sakila.actor');
call sakila.DynamicQuery('sakila.film');