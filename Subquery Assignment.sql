-- subquery assignment
-- using sakila db


-- 1. customer details who made more than 5 payments
-- inner query gets customer ids with more than 5 payments, outer gets their details
select *
from sakila.customer
where customer_id in (
  select customer_id
  from sakila.payment
  group by customer_id
  having count(*) > 5
);


-- 2. actors who acted in more than 10 films
-- film_actor has actor + film, so count films per actor
select first_name, last_name
from sakila.actor
where actor_id in (
  select actor_id
  from sakila.film_actor
  group by actor_id
  having count(film_id) > 10
);


-- 3. customers who never made a payment
-- not in -> customer ids not in payment table
select first_name, last_name
from sakila.customer
where customer_id not in (
  select distinct customer_id from sakila.payment
);
-- getting 0 rows, all customers in sakila have paid atleast once


-- 4. films with rental rate higher than avg
select title, rental_rate
from sakila.film
where rental_rate > (select avg(rental_rate) from sakila.film);

-- select avg(rental_rate) from sakila.film;  -- just checking avg


-- 5. films that were never rented
-- rental table doesnt have film_id so had to join inventory
select title
from sakila.film
where film_id not in (
  select i.film_id
  from sakila.inventory i
  join sakila.rental r on i.inventory_id = r.inventory_id
);


-- 6. customers who rented in same month as customer 5
-- first get months customer 5 rented, then find others in those months
select distinct c.customer_id, c.first_name, c.last_name
from sakila.customer c
join sakila.rental r on c.customer_id = r.customer_id
where month(r.rental_date) in (
  select month(rental_date) from sakila.rental where customer_id = 5
)
and c.customer_id != 5;   -- not showing customer 5 itself


-- 7. staff who handled a payment greater than avg payment
-- nested subquery, avg inside another subquery
select staff_id, first_name, last_name
from sakila.staff
where staff_id in (
  select staff_id
  from sakila.payment
  where amount > (select avg(amount) from sakila.payment)
);


-- 8. title and rental duration of films more than avg duration
select title, rental_duration
from sakila.film
where rental_duration > (select avg(rental_duration) from sakila.film);


-- 9. customers with same address as customer 1
-- using = since subquery gives only one address
select customer_id, first_name, last_name, address_id
from sakila.customer
where address_id = (
  select address_id from sakila.customer where customer_id = 1
);
-- only customer 1 comes, no one else has same address


-- 10. payments greater than avg of all payments
select payment_id, customer_id, amount, payment_date
from sakila.payment
where amount > (select avg(amount) from sakila.payment);