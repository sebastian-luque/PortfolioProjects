/*
SQL for Data Analysis
The following data analysis in SQL includes a database of a startup in the agricultural sector, 
which helps farmers to sell directly to consumers. Through different exploratory queries, 
I got base information to increase the sales and income of farmers.
*/

--1. Clients by country
SELECT
	c.country,
	COUNT(client_id) AS total_customers
	FROM customers cl
	INNER JOIN cities c ON cl.city_id = c.city_id
	GROUP BY 1;

--2. Languages spoken by customers
SELECT	
	cl.name,
	cl.lastname,
	c.name,
	c.country,
CASE
	WHEN country IN ('mexico', 'chile', 'argentina', 'costa rica') then 'espanol'
	WHEN country IN ('brasil') THEN 'portugues'
ELSE 'otro'
END AS languages
FROM customers cl
INNER JOIN cities c ON cl.city_id = c.city_id
ORDER BY 4 ASC
LIMIT 10;

--3. Orders per day made in brazil
WITH orders_brasil AS (
	SELECT
	*
	FROM orders
	WHERE city_id IN (SELECT city_id FROM cities WHERE country = 'brasil')
)

SELECT
	date_placed,
	SUM(price) as total_sales,
	SUM(units) as unit_sold
FROM orders_brasil
GROUP BY 1
ORDER BY 1 ASC;

--4. First and last name of customers who bought "lettuce"
SELECT 
	cliente
FROM (
	SELECT
	o.order_id,
	p.name as Producto,
	CONCAT(cli.name, ' ', cli.lastname) AS cliente
	FROM orders as o
	LEFT JOIN customers as cli ON cli.client_id = o.client_id
	LEFT JOIN products as p ON p.product_id = o.product_id
) as sub
WHERE 
producto = 'lechuga';

--5. Farmer orders whose segment is "small"
SELECT 
	o.order_id,
	o.price,
	o.units,
	a.segment
FROM 
	orders as o
JOIN farmers as a
ON o.farmer_id = a.farmer_id
WHERE 
	segment IN (SELECT segment 
			   	FROM farmers
			   WHERE segment ='chico');

--6. Average price (ticket) sold per city
SELECT
c.name,
(
	SELECT
	AVG(price)
	FROM orders o
	WHERE c.city_id = o.city_id
) AS average_price

FROM cities c
GROUP BY city_id;	

--7. Monthly average of units sold and its difference from the total average
SELECT
EXTRACT(MONTH FROM date_placed) AS month_,
SUM(units) AS total_unit,
SUM(units) -
(SELECT AVG(unidades)
	FROM (
		SELECT EXTRACT(MONTH FROM date_placed) AS mes,
		SUM(units) AS unidades
		FROM orders
		GROUP BY 1
	) AS tabla
	) AS average_difference

FROM orders
GROUP BY 1
ORDER BY 1

--8. Orders per customer with a price greater than $100
SELECT
	CONCAT(cl.name,' ',cl.lastname) AS customers,
	o.price
FROM  customers AS cl
	JOIN orders AS o
	ON cl.client_id=o.client_id
WHERE o.price IN (
	SELECT 
	price
	FROM (
		SELECT
		price
		FROM orders
		WHERE price >=100
		) as A
)
ORDER BY 2 DESC;

--9. Farmer orders whose segment is “large”
WITH farmers_grande AS(
	SELECT *
	FROM farmers
	WHERE segment='grande'
)
SELECT
	order_id,
	date_placed
FROM orders AS o
JOIN farmers_grande AS ag
ON o.farmer_id=ag.farmer_id

--10. Orders per month made in Brazil
SELECT
	EXTRACT(MONTH FROM date_placed) as month_,
	COUNT (order_id)
FROM orders as o
LEFT JOIN cities as c 
	ON c.city_id= o.city_id
WHERE country = 'brasil'
GROUP BY 1

--11. Harvested products in Mexico after June 2020
WITH cities_mexico AS (
	SELECT *
	FROM cities
	WHERE country='mexico'
),
harvested_products AS (
SELECT *
FROM products
WHERE date_farmed >= '2020-07-01'
)
SELECT *
FROM orders AS o
	JOIN cities_mexico AS cm 
	ON o.city_id=cm.city_id
	JOIN harvested_products AS hp 
	ON o.product_id=hp.product_id
ORDER BY hp.date_farmed ASC

--12. Orders higher than the average in price made by farmers whose segment is "small"
WITH orders_grandes AS (
	SELECT
	*
	FROM orders
	WHERE
	price > (SELECT AVG(price) FROM orders)
),
farmers_chicos AS (
	SELECT
	*
	FROM farmers
	WHERE segment = 'chico'
	)
SELECT
	CONCAT(ac.name, ' ', ac.lastname) AS farmer_name,
	COUNT(og.order_id) as total_orders
FROM orders_grandes og
INNER JOIN farmers_chicos ac ON ac.farmer_id = og.farmer_id
GROUP BY 1

--13. Customers who buy the most per city
WITH citybeha AS (
SELECT
	CONCAT(cli.name,' ',cli.lastname) AS Name,
	c.name AS City,
	SUM(o.price) AS Sales
FROM orders AS o 
LEFT JOIN customers AS cli
	ON o.client_id=cli.client_id
LEFT JOIN cities AS c
	ON o.city_id=c.city_id
GROUP BY 1,2
)
SELECT
	name,
	city,
    sales,
RANK() OVER(PARTITION BY city ORDER BY sales DESC) AS Ranking
FROM citybeha;
