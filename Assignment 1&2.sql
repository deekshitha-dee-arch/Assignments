USE sakila;


-- Q1 Active customers whose first name starts with 'J'
-- Used LIKE 'J%' to match any name starting with J, and active = 1 to keep only active customers.
SELECT *
FROM customer
WHERE first_name LIKE 'J%' AND active = 1;

-- Q2 Films with 'ACTION' in the title or 'WAR' in the description
-- The % on both sides means the word can appear anywhere. OR because either condition is enough.
SELECT film_id, title, description
FROM film
WHERE title LIKE '%ACTION%' OR description LIKE '%WAR%';

-- Q3 Customers whose last name isn't SMITH and whose first name ends with 'a'
--  <> means "not equal". '%a' matches names that end with a.
SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name <> 'SMITH' AND first_name LIKE '%a';

-- Q4 Films with rental rate above 3.0 and a replacement cost filled in
-- Used IS NOT NULL since = NULL doesn't work in SQL.
SELECT film_id, title, rental_rate, replacement_cost
FROM film
WHERE rental_rate > 3.0 AND replacement_cost IS NOT NULL;

-- Q5 Number of active customers in each store
--  Filtered active customers first with WHERE, then grouped by store to count them.
SELECT store_id, COUNT(*) AS active_customers
FROM customer
WHERE active = 1
GROUP BY store_id;

-- Q6 All the different film ratings
-- DISTINCT removes duplicates so each rating shows up once.
SELECT DISTINCT rating FROM film;

-- Q7 Number of films per rental duration, only where average length is over 100 minutes
-- Grouped by rental_duration. Used HAVING (not WHERE) because the filter is on an average.
SELECT rental_duration, COUNT(*) AS num_films, AVG(length) AS avg_length
FROM film
GROUP BY rental_duration
HAVING AVG(length) > 100;

-- Q8 Total payment amount per day, only for days with more than 100 payments
-- DATE() strips the time so all payments on the same day are grouped together.
SELECT DATE(payment_date) AS pay_date, COUNT(*) AS num_payments, SUM(amount) AS total_amount
FROM payment
GROUP BY DATE(payment_date)
HAVING COUNT(*) > 100;

-- Q9 Customers with no email or an email ending in .org
--  Checked for NULL separately since LIKE doesn't match NULL values.
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE email IS NULL OR email LIKE '%.org';

-- Q10  PG and G rated films, highest rental rate first
-- IN is a shorter way of writing rating = 'PG' OR rating = 'G'.
SELECT film_id, title, rating, rental_rate
FROM film
WHERE rating IN ('PG', 'G')
ORDER BY rental_rate DESC;

-- Q11 Film count per length for titles starting with 'T', only where count is more than 5
-- WHERE filters titles before grouping, HAVING filters the groups after counting.
-- This can return very few or zero rows depending on the data.
SELECT length, COUNT(*) AS num_films
FROM film
WHERE title LIKE 'T%'
GROUP BY length
HAVING COUNT(*) > 5;

-- Q12 Actors who have been in more than 10 films
-- Joined actor with film_actor to count each actor's films, then kept only those above 10.
SELECT a.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS num_films
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(fa.film_id) > 10
ORDER BY num_films DESC;

-- Q13 Top 5 films by rental rate, then by length
-- Sorted by rental rate first. Films with the same rate are then sorted by length.
SELECT film_id, title, rental_rate, length
FROM film
ORDER BY rental_rate DESC, length DESC
LIMIT 5;

-- Q14 Every customer with their total number of rentals, most to least
-- LEFT JOIN keeps customers even if they never rented.
-- COUNT(r.rental_id) gives 0 for them instead of 1.
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_rentals
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_rentals DESC;

-- Q15  Films that have never been rented
-- Rentals connect to films through inventory, so I checked film -> inventory -> rental.
-- NOT EXISTS keeps a film only if none of its copies were ever rented.
SELECT f.film_id, f.title
FROM film f
WHERE NOT EXISTS (
  SELECT 1 FROM inventory i
  JOIN rental r ON r.inventory_id = i.inventory_id
  WHERE i.film_id = f.film_id
);

-- ===== JOINS =====

-- J1 All customers with the films they rented
-- Customers don't link to films directly, so I went customer -> rental -> inventory -> film.
-- LEFT JOIN so every customer is included even if they haven't rented anything.
SELECT c.customer_id, c.first_name, c.last_name, f.title
FROM customer c
JOIN rental r    ON c.customer_id  = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f      ON i.film_id      = f.film_id
ORDER BY c.customer_id;

-- J2 All customers and their rental count, including those with no rentals
-- LEFT JOIN keeps every customer. Counting rental_id (not *) makes non-renters show 0.
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS rental_count
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY rental_count DESC;

-- J3 All films with their category, including films without one
-- film_category connects films and categories. LEFT JOIN on both keeps films with no category (shown as NULL).
SELECT f.film_id, f.title, cat.name AS category
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category cat     ON fc.category_id = cat.category_id;

-- J4 All customer and staff emails using a full outer join
-- MySQL doesn't have FULL OUTER JOIN, so I combined a LEFT JOIN and a RIGHT JOIN with UNION.
-- UNION also removes duplicate rows between the two halves.
SELECT c.email AS customer_email, s.email AS staff_email
FROM customer c
LEFT JOIN staff s ON c.email = s.email
UNION
SELECT c.email, s.email
FROM customer c
RIGHT JOIN staff s ON c.email = s.email;

-- J5 Actors in the film 'ACADEMY DINOSAUR'
-- film_actor is the bridge table between actors and films. Filtered on the film title.
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f        ON fa.film_id = f.film_id
WHERE f.title = 'ACADEMY DINOSAUR';

-- J6 Every store and how many staff work there, even if it's zero
-- Started from store and used LEFT JOIN so stores with no staff still show up with 0.
SELECT st.store_id, COUNT(s.staff_id) AS num_staff
FROM store st
LEFT JOIN staff s ON st.store_id = s.store_id
GROUP BY st.store_id;

-- J7 Customers who rented more than 5 times, with name and rental count
-- Counted rentals per customer and used HAVING to keep only those above 5.
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) > 5
ORDER BY total_rentals DESC;


