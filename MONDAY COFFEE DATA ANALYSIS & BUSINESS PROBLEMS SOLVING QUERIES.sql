
-- MONDAY COFFEE DATA ANALYSIS & BUSINESS PROBLEMS SOLVING

/* Coffee Consumers Count:
How many people in each city are estimated to consume coffee, given that 25% of the population does?
*/

SELECT city_name,
	ROUND((population * 0.25)/1000000, 2) estimated_population_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

/* Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
*/

SELECT
    c.city_name,
    SUM(s.total) AS total_sales
FROM 
    sales s
JOIN customers cus
    ON s.customer_id = cus.customer_id
JOIN city c
    ON cus.city_id = c.city_id
WHERE 
    DATE_TRUNC('month', sale_date) BETWEEN DATE '2023-10-01' AND DATE '2023-12-31'
GROUP BY c.city_name
ORDER BY total_sales DESC;

SELECT
    c.city_name,
    SUM(s.total) AS total_sales
FROM 
    sales s
JOIN customers cus
    ON s.customer_id = cus.customer_id
JOIN city c
    ON cus.city_id = c.city_id
WHERE 
    EXTRACT (YEAR FROM sale_date) = 2023 AND
	EXTRACT (quarter FROM sale_date) = 4
GROUP BY c.city_name
ORDER BY total_sales DESC;
 
/* Order Count for Each Product
How many total order of each coffee product have been made?
*/

SELECT p.product_name,
	COUNT (s.*) total_orders
FROM sales s
JOIN products p 
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY total_orders DESC

/* Average Sales Amount per City
What is the average sales amount per customer in each city?
*/ 


SELECT c.city_name,
	COUNT (s.*) total_orders,
	SUM (p.price) revenue,
	AVG (p.price) average_price
FROM city c
JOIN customers cus
ON c.city_id = cus.city_id
	JOIN sales s 
	ON cus.customer_id = s.customer_id
	JOIN products p
	ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


SELECT c.city_name,
	COUNT (DISTINCT cus.customer_id) total_customers,
	SUM (p.price) revenue,
	ROUND(SUM (p.price)::numeric/COUNT (DISTINCT cus.customer_id)::numeric,0) avg_price
FROM city c
JOIN customers cus
ON c.city_id = cus.city_id
	JOIN sales s 
	ON cus.customer_id = s.customer_id
	JOIN products p
	ON s.product_id = p.product_id
GROUP BY 1
ORDER BY avg_price DESC
	

/* City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers.
return city_name, total current customers, estimated coffee consumers (25% of population)
*/

SELECT c.city_name city_name,
	ROUND((population * 0.25)/1000000, 2) estimated_coffee_consumers_millions,
	COUNT(DISTINCT cus.customer_id) unique_customers
FROM city c
JOIN customers cus
ON c.city_id = cus.city_id
GROUP BY city_name, estimated_coffee_consumers_millions
	ORDER BY unique_customers DESC;


/* 
Top Selling Products by City
What are the top 3 selling products in each city based on order volume?
*/

SELECT *
	FROM (
			SELECT c.city_name city,
			p.product_name product_name,
			COUNT (s.sale_id) total_order,
			DENSE_RANK () OVER (PARTITION BY c.city_name ORDER BY COUNT (s.sale_id) DESC) product_rank
		FROM sales s
		JOIN products p
		ON s.product_id = p.product_id
		JOIN customers cus
		ON s.customer_id = cus.customer_id
		JOIN city c
		ON cus.city_id = c.city_id
		GROUP BY city, product_name
		)
WHERE product_rank BETWEEN 1 AND 3

/* 
Customer Segmentation by City
How many unique customers are there in each city who have purchased products with ID 1-14?
*/

SELECT c.city_name city,
	COUNT (DISTINCT s.customer_id) customer_count
FROM sales s
JOIN customers cus
ON s.customer_id = cus.customer_id
JOIN city c
ON c.city_id = cus.city_id
JOIN products p
ON s.product_id = p.product_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY city
ORDER BY customer_count DESC;

/* 
Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer
*/

SELECT 
    c.city_name,
    COUNT(DISTINCT cus.customer_id) AS total_customers,
    ROUND(SUM(p.price)::numeric / COUNT(DISTINCT cus.customer_id)::numeric, 0) AS avg_price,
    ROUND(c.estimated_rent::numeric / COUNT(DISTINCT cus.customer_id)::numeric, 2) AS avg_rent_per_customer
FROM city c
JOIN customers cus
    ON c.city_id = cus.city_id
JOIN sales s 
    ON cus.customer_id = s.customer_id
JOIN products p
    ON s.product_id = p.product_id
GROUP BY c.city_name, c.estimated_rent
ORDER BY avg_price DESC;

/* 
Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
*/

SELECT 
    *,
   ROUND(((cr_sale - last_month_sale)::numeric / last_month_sale)::numeric * 100,2) AS growth_rate
FROM (
    SELECT 
        city,
        month,
        year,
        total_sale AS cr_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city ORDER BY year, month) AS last_month_sale
    FROM (
        SELECT 
            c.city_name AS city,
            EXTRACT(MONTH FROM s.sale_date) AS month,
            EXTRACT(YEAR FROM s.sale_date) AS year,
            SUM(s.total) AS total_sale
        FROM 
            sales s
        JOIN customers cus
            ON s.customer_id = cus.customer_id
        JOIN city c
            ON c.city_id = cus.city_id
        JOIN products p
            ON s.product_id = p.product_id
        GROUP BY c.city_name, EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)
        ORDER BY c.city_name, year, month
    ) sub
) final;

/* 
Market Potential Analysis
Identify top 3 city based on highest sales, 
return city name, total sale, total rent, total customers, estimated coffee consumer
*/

SELECT 
    c.city_name AS city,
    SUM(s.total) AS revenue,
    c.estimated_rent,
    COUNT(DISTINCT cus.customer_id) AS customer_count,
    ROUND((c.population * 0.25) / 1000000, 2) AS estimated_coffee_consumers_millions,
    ROUND(c.estimated_rent::numeric / COUNT(DISTINCT cus.customer_id)::numeric, 2) AS avg_rent_per_customer
FROM 
    sales s
JOIN customers cus
    ON s.customer_id = cus.customer_id
JOIN city c
    ON c.city_id = cus.city_id
JOIN products p
    ON s.product_id = p.product_id
GROUP BY 
    c.city_name, 
    c.estimated_rent, 
    c.population
ORDER BY revenue DESC;

/* Recommendations:
	After analyzing the data, the recommended top three cities for new store openings are:
	
City 1: Pune
	Average rent per customer is very low.
	Highest total revenue.
	Average sales per customer is also high.

City 2: Delhi
	Highest estimated coffee consumers at 7.7 million.
	Highest total number of customers, which is 68.
	Average rent per customer is 330 (still under 500).
	
City 3: Jaipur
	
	Highest number of customers, which is 69.
	Average rent per customer is very low at 156.
	Average sales per customer is better at 11.6k.
	
	*/














