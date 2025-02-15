# Monday-Coffee-Company-Expansion

![4i1dxc7poxq2hwix1nredzr9i1y4](https://github.com/user-attachments/assets/77d993de-3779-4971-abe9-cf41cfad3083)





## Project Overview
**Project Title:** Monday Coffee Expansion 

The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

## Tools Used
- **Data Preparation** - Microsoft Excel
- **DBMS:** PostgreSQL 
- **Query Language:** SQL  
- **Data Visualization:** Power BI (Future Work)

  ### Data Source
- Dataset was downloaded from [Maven Analytics](www.maven.com)

  ## Project Objectives
1. **Data Preparation & Cleaning** - Data understanding, exploration, data loading. Detect and eliminate records containing missing or null values to ensure data quality.  
2. **SCHEMAS Setup** – Establish Schemas and populate using the provided data.  
3. **Key Business Insights** – Conduct an initial analysis to gain insights into the dataset's structure and key trends. Utilize SQL queries to address critical business questions and extract meaningful insights from the sales data.  
4. **Business Findings and Reccommendations** – Provide Business recommendations using insights & trends gotten from the sales data.

## Dataset Description
The dataset contains different tables with different records for Monday Coffee, such as:  
- **sales** – contains transaction-level data, including every sale the company has made.
- **city** –  contains informations about cities. including cities the company currently sells in and prospective cities they want to expnad to.
- **customers** – contains informations about every customer.  
- **products** – contains informations about every product type the company currently offers.   

## Project Structure

### 1. Data Preparation & Data Cleaning (Excel): 
- Data understanding, exploration, data loading.
- Check dataset structure using Column Headers & Data Types
- Standardizing Data Formats

### 2. SCHEMA Setup
- **Database Creation:** The project begins with setting up a database named `monday_coffee_db`.  
- **Table Creation:** Create all neccesary table to store required data.

```sql
  -- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS
```
### 3. Key Business Insights
- MONDAY COFFEE DATA ANALYSIS & BUSINESS PROBLEMS SOLVING

**Coffee Consumers Count:**
How many people in each city are estimated to consume coffee, given that 25% of the population does?
```sql
SELECT city_name,
	ROUND((population * 0.25)/1000000, 2) estimated_population_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC
```

**Total Revenue from Coffee Sales:**
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
```sql
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
 ```
**Order Count for Each Product:**
How many total order of each coffee product have been made?
```sql
SELECT p.product_name,
	COUNT (s.*) total_orders
FROM sales s
JOIN products p 
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY total_orders DESC
```

**Average Sales Amount per City:**
What is the average sales amount per customer in each city?
```sql
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
```	

**City Population and Coffee Consumers:**
Provide a list of cities along with their populations and estimated coffee consumers (assume 25% of total population).
```sql
SELECT c.city_name city_name,
	ROUND((population * 0.25)/1000000, 2) estimated_coffee_consumers_millions,
	COUNT(DISTINCT cus.customer_id) unique_customers
FROM city c
JOIN customers cus
ON c.city_id = cus.city_id
GROUP BY city_name, estimated_coffee_consumers_millions
	ORDER BY unique_customers DESC;
```
**Top Selling Products by City:**
What are the top 3 selling products in each city based on order volume?
```sql
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
```
**Customer Segmentation by City:**
How many unique customers are there in each city who have purchased products with ID 1-14?
```sql
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
```
**Average Sale vs Rent:**
Find each city and their average sale per customer and avg rent per customer
```sql
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
```
**Monthly Sales Growth:**
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
```sql
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
```
**Market Potential Analysis:**
Identify top 3 city based on highest sales.
```sql
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
```
## 4. Business Recommendations
After analyzing the data, the recommended top three cities for new store openings are:
	
### City 1: Pune
- Average rent per customer is very low.
- Highest total revenue.
- Average sales per customer is also high.

### City 2: Delhi
- Highest estimated coffee consumers at 7.7 million.
- Highest total number of customers, which is 68.
- Average rent per customer is 330 (still under 500).
	
### City 3: Jaipur	
- Highest number of customers, which is 69.
- Average rent per customer is very low at 156.
- Average sales per customer is better at 11.6k.

---

## Conclusion
This project demonstrates how SQL can be used to clean, analyze, and derive insights from retail sales data. The findings offer valuable business recommendations that can enhance marketing strategies, improve customer experience, and optimize sales performance.   

---

## 📌 About Me
Hi, I'm Oluwatosin Amosu Bolaji, a Data Analyst skilled in SQL, Power BI, and Excel. I enjoy turning complex datasets into actionable insights through data visualization and business intelligence techniques.

- **🔹 Key Skills:** Data Analysis | SQL Queries | Power BI Dashboards | Data Cleaning | Reporting
- **🔹 Passionate About:** Data storytelling, problem-solving, and continuous learning

- **📫 Let's connect!**
- 🔗 [Linkedin](www.linkedin.com/in/oluwatosin-amosu-722b88141) | 🌐 [Portfolio](https://github.com/Tbrown1998?tab=repositories) | 📩 oluwabolaji60@gmail.com












