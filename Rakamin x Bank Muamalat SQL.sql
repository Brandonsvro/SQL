--Step 1: Dataset Exploration
--Objective: To understand each aspect of the Sales Dataset for 2020-2021.	

SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM product_category;
SELECT * FROM products;

--Step 2: Combining Relevant Data
--Objective: To create a master table that consolidates the necessary data for analyzing sales performance
	
DROP TABLE IF EXISTS sales_table;
CREATE TABLE sales_table AS
	SELECT	o.customerid,
			c.customercity,
			c.customerstate,
			o.orderid,
			o.date,
			p.prodname,
			pc.categoryname,
			o.quantity,
			p.price,
			p.price*o.quantity as totalsales
	FROM customers AS c
	JOIN orders AS o USING(customerid)
	JOIN products AS p
		ON o.prodnumber = p.prodnumber
	JOIN product_category AS pc
		ON p.category = pc.categoryid;

--Step 3: Creating Key Sales Metrics
--Objective: To assess overall sales performance through various variables

	--Calculating key sales metrics for 2020 as a baseline for comparison
WITH data_2020 AS( 
	SELECT CAST(SUM (totalsales) AS NUMERIC) AS totalsales_2020,
		CAST(COUNT(orderid) AS NUMERIC) AS totaltrx_2020,
		CAST(SUM(quantity) AS NUMERIC) AS totalqty_2020,
		CAST(COUNT(DISTINCT(customerid)) AS NUMERIC) AS totalcust_2020,
		CAST(SUM(totalsales)/COUNT(orderid) AS NUMERIC) as AOV2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM DATE) = 2020
)

	--Calculating key sales metrics for 2021 and their growth (YoY)
SELECT EXTRACT(YEAR FROM date) AS year,
		--Total sales and YoY growth for each year
		SUM (totalsales) AS total_sales,
		ROUND(((SUM (totalsales)-(SELECT totalsales_2020 FROM data_2020))/(SELECT totalsales_2020 FROM data_2020))*100,1) AS sales_yoy,
		--Total transactions and YoY growth for each year
		COUNT(orderid) AS total_trx,
		ROUND(((COUNT (orderid)-(SELECT totaltrx_2020 FROM data_2020))/(SELECT totaltrx_2020 FROM data_2020))*100,1) AS trx_yoy, --YoY Transaction Growth
		--Total quantity of products sold and YoY growth for each year
		SUM(quantity) AS total_qty,
		ROUND(((SUM (quantity)-(SELECT totalqty_2020 FROM data_2020))/(SELECT totalqty_2020 FROM data_2020))*100,1) AS qty_yoy, --YoY Product Sold Growth
		--Total customers and YoY growth for each year
		COUNT(DISTINCT(customerid)) AS total_cust,
		ROUND(((COUNT(DISTINCT(customerid))-(SELECT totalcust_2020 FROM data_2020))/(SELECT totalcust_2020 FROM data_2020))*100,1) AS cust_yoy, --YoY Customer Growth
		--AOV dan YoY growth
		ROUND(SUM(totalsales)/COUNT(orderid)) as AOV,
		ROUND((((SUM(totalsales)/COUNT(orderid))-(SELECT AOV2020 FROM data_2020))/(SELECT AOV2020 FROM data_2020))*100,1) as AOV_yoy --YoY AOV Growth
FROM sales_table
GROUP BY 1;

--Step 4: Calculating Monthly Sales Trends
--Objective: To assess trends and fluctuations in sales and quantity of products sold each month in 2021

	--Calculate total and growth of sales and quantity of products sold each month for 2020 and 2021
WITH mom_sales AS(
	SELECT year,
			month,
			total_sales,
			ROUND(((total_sales-LAG(total_sales) OVER(PARTITION BY year ORDER BY year, month))/LAG(total_sales) OVER(PARTITION BY year ORDER BY year, month))*100,1) AS sales_momgrowth,
			total_qty,
			ROUND(((total_qty::numeric-LAG(total_qty) OVER(PARTITION BY year ORDER BY year, month))/LAG(total_qty) OVER(PARTITION BY year ORDER BY year, month))*100,1) AS qty_momgrowth
	FROM(
	SELECT EXTRACT(YEAR FROM DATE) as year,
			EXTRACT(MONTH FROM DATE) as month,
			SUM(totalsales) as total_sales,
			SUM(quantity) as total_qty
	FROM sales_table
	GROUP BY 1,2
	ORDER BY 1,2) as mom_sales_raw
)

	--Calculating the average MoM growth from the previous calculations
SELECT year,
		month,
		total_sales,
		sales_momgrowth, 
		ROUND(AVG(sales_momgrowth)OVER(PARTITION BY year),1) AS avg_momgrowth_sales,
		total_qty,
		qty_momgrowth,
		ROUND(AVG(qty_momgrowth)OVER(PARTITION BY year),1) AS avg_momgrowth_sales
FROM mom_sales;

--Step 5: Calculating Sales Data by Product Category
--Objective: To assess the overall sales performance for each product category

	--Calculating sales and quantity of products sold by product category for 2020 as a baseline for comparison
WITH category_sales2020 AS( 
	SELECT categoryname,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1
),

	--Calculating sales, quantity of products sold, transactions, AOV, and average quantity by product category for 2021
category_sales2021 AS(
	SELECT categoryname,
		COUNT(orderid) AS trx2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1
)

	--Combining the results of calculations for 2020 and 2021
SELECT a.categoryname,
		--Total sales, YoY growth, and average transaction value per order for each product category
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		--Total quantity of products sold, YoY growth, and average quantity per order for each product category
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty	
FROM category_sales2021 as a
JOIN category_sales2020 as b USING(categoryname)
ORDER BY 2 DESC;


--Step 6: Calculating Sales Data by Top Products in Each Category
--Objective: To identify the top 5 products in each category with the best sales performance

	--Calculating sales and quantity of products sold for each product item in 2020 as a baseline for comparison
WITH product_sales2020 AS( 
	SELECT prodname,
			categoryname,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1,2
),

	--Calculating sales, quantity of products sold, transactions, AOV, average quantity, and ranking by sales for each product item in 2021
product_sales2021 AS( 
	SELECT prodname,
			categoryname,
		COUNT(orderid) AS trx2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021,
		RANK()OVER(PARTITION BY categoryname ORDER BY SUM(totalsales) DESC) AS rank
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1,2
)

	--Combining the results of calculations for 2020 and 2021
SELECT a.prodname,
		a.categoryname,
		a.rank,
		--Total sales, YoY growth, and average transaction value per order for each product item
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		--Total quantity of products sold, YoY growth, and average quantity per order for each product item
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty	
FROM product_sales2021 as a
JOIN product_sales2020 as b USING(prodname)
WHERE rank BETWEEN 1 AND 5
ORDER BY 2,3;

--Step 7: Calculating Sales Data by Customer State
--Objective: To assess the overall sales performance for each customer state

	--Calculating sales and quantity of products sold by customer state for 2020 as a baseline for comparison
WITH state_sales2020 AS(
	SELECT customerstate,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1
),

	--Calculating sales, quantity of products sold, transactions (for AOV & Avg Order Qty calculations), and total customers for each customer state in 2021
state_sales2021 AS(
	SELECT customerstate,
		COUNT(orderid) AS trx2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021,
		COUNT(DISTINCT(customerid)) as cust2021
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1
)

	--Combining the results of calculations for 2020 and 2021
SELECT a.customerstate,
		--Total sales, YoY growth, and average transaction value per order for each customer state
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		--Total quantity of products sold, YoY growth, and average quantity per order for each customer state
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty,
		--Total transactions for each state
		trx2021 AS total_trx,
		--Total customers for each state
		cust2021 AS total_cust
FROM state_sales2021 as a
JOIN state_sales2020 as b USING(customerstate)
ORDER BY 2 DESC;


--Step 8: Calculating Sales Data by Top Customer Cities in Each State
--Objective: To identify the top 5 cities in each state with the best sales performance

	--Calculating sales and quantity of products sold for each city in 2020 as a baseline for comparison
WITH city_sales2020 AS( 
	SELECT customercity,
			customerstate,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1,2
),

	--Calculating sales, quantity of products sold, total transactions, AOV, average quantity, total customers, and ranking by sales for each city in 2021
city_sales2021 AS( 
	SELECT customercity,
			customerstate,
		COUNT(orderid) AS trx2021,
		COUNT(DISTINCT(customerid)) AS cust2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021,
		RANK()OVER(PARTITION BY customerstate ORDER BY SUM(totalsales) DESC) AS rank
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1,2
)

	--Combining the results of calculations for 2020 and 2021
SELECT a.customercity,
		a.customerstate,
		a.rank,
		--Total sales, YoY growth, and average transaction value per order for each city
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		--Total quantity of products sold, YoY growth, and average quantity per order for each city
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty,
		trx2021 AS total_trx,
		cust2021 AS total_cust
FROM city_sales2021 as a
JOIN city_sales2020 as b USING(customercity)
WHERE rank BETWEEN 1 AND 5
ORDER BY 2,3;