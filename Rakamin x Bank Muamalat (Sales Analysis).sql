--Step 1: Eksplorasi dataset
--Tujuan: Untuk memahami setiap ada yang ada pada Sales Dataset 2020-2021 
	
SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM product_category;
SELECT * FROM products;

--Step 2: Menggabungkan berbagai data yang dibutuhkan
--Tujuan: Membuat tabel utama yang berisi berbagai data yang dibutuhkan untuk analisis performa penjualan 
	
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


--Step 3: Membuat Key Metrics penjualan
--Tujuan: Menghitung Key Metrics (Total Sales, Trx, Qty Product Sold, Customers) untuk menilai performa penjualan secara umum

	--Menghitung Key Metrics penjualan tahun 2020 untuk pembanding
WITH data_2020 AS( 
	SELECT CAST(SUM (totalsales) AS NUMERIC) AS totalsales_2020,
		CAST(COUNT(orderid) AS NUMERIC) AS totaltrx_2020,
		CAST(SUM(quantity) AS NUMERIC) AS totalqty_2020,
		CAST(COUNT(DISTINCT(customerid)) AS NUMERIC) AS totalcust_2020,
		CAST(SUM(totalsales)/COUNT(orderid) AS NUMERIC) as AOV2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM DATE) = 2020
)

	--Menghitung Key Metrics penjualan tahun 2021 dan pertumbuhannya (YoY)
SELECT EXTRACT(YEAR FROM date) AS year,
		--Total Sales dan YoY Growth
		SUM (totalsales) AS total_sales,
		ROUND(((SUM (totalsales)-(SELECT totalsales_2020 FROM data_2020))/(SELECT totalsales_2020 FROM data_2020))*100,1) AS sales_yoy,
		--Total Trx dan YoY Growth
		COUNT(orderid) AS total_trx,
		ROUND(((COUNT (orderid)-(SELECT totaltrx_2020 FROM data_2020))/(SELECT totaltrx_2020 FROM data_2020))*100,1) AS trx_yoy, --YoY Transaction Growth
		--Total Product Sold dan YoY Growth
		SUM(quantity) AS total_qty,
		ROUND(((SUM (quantity)-(SELECT totalqty_2020 FROM data_2020))/(SELECT totalqty_2020 FROM data_2020))*100,1) AS qty_yoy, --YoY Product Sold Growth
		--Total Customers dan YoY Growth
		COUNT(DISTINCT(customerid)) AS total_cust,
		ROUND(((COUNT(DISTINCT(customerid))-(SELECT totalcust_2020 FROM data_2020))/(SELECT totalcust_2020 FROM data_2020))*100,1) AS cust_yoy, --YoY Customer Growth
		--AOV dan YoY Growth
		ROUND(SUM(totalsales)/COUNT(orderid)) as AOV,
		ROUND((((SUM(totalsales)/COUNT(orderid))-(SELECT AOV2020 FROM data_2020))/(SELECT AOV2020 FROM data_2020))*100,1) as AOV_yoy --YoY AOV Growth
FROM sales_table
GROUP BY 1;

--Step 4: Menghitung total penjualan dan kuantitas produk terjual setiap bulannya
--Tujuan: Menilai tren dan fluktuasi penjualan dan kuantitas produk terjual setiap bulannya di tahun 2021 dan 2020 untuk pembanding

	--Hitung total dan pertumbuhan penjualan dan kuantitas produk terjual setiap bulannya untuk tahun 2020 dan 2021
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

	--Menghitung rata-rata pertumbuhan MoM penjualan dan kuantitas produk terjual untuk tahun 2020 dan 2021 dari hasil perhitungan sebelumnya
SELECT year,
		month,
		total_sales,
		sales_momgrowth, 
		ROUND(AVG(sales_momgrowth)OVER(PARTITION BY year),1) AS avg_momgrowth_sales,
		total_qty,
		qty_momgrowth,
		ROUND(AVG(qty_momgrowth)OVER(PARTITION BY year),1) AS avg_momgrowth_sales
FROM mom_sales;

--Step 5: Menghitung penjualan dan kuantitas produk terjual berdasarkan setiap kategori produk
--Tujuan: Menilai performa penjualan tiap kategori produk

	--Menghitung penjualan dan kuantitas produk terjual tiap kategori produk tahun 2020 untuk pembanding
WITH category_sales2020 AS( 
	SELECT categoryname,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1
),

	--Menghitung penjualan, kuantitas produk terjual, dan trx(keperluan perhitungan AOV) tiap kategori produk tahun 2021
category_sales2021 AS( --Agregrasi data setiap kategori produk di tahun 2021
	SELECT categoryname,
		COUNT(orderid) AS trx2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1
)

	--Menggabungkan hasil perhitungan tahun 2020 dan 2021 untuk performa penjualan tiap kategori produk secara lengkap
SELECT a.categoryname,
		--Total Sales, YoY Growth, dan rata-rata nilai transaksi per order setiap kategori produk
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		--Total Kuantitas Produk Terjual, YoY Growth, dan rata-rata kuantitas per order setiap kategori produk
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty	
FROM category_sales2021 as a
JOIN category_sales2020 as b USING(categoryname)
ORDER BY 2 DESC;

--Menghitung data total penjualan dan kuantitas serta pertumbuhannya untuk setiap produk disetiap kategori

WITH product_sales2020 AS( --Agregasi data setiap kategori produk di tahun 2020 untuk pembanding
	SELECT prodname,
			categoryname,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1,2
),

product_sales2021 AS( --Agregrasi data setiap kategori produk di tahun 2021
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

--Agregasi data total penjualan dan kuantitas serta pertumbuhan setiap kategori

SELECT a.prodname,
		a.categoryname,
		a.rank,
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty	
FROM product_sales2021 as a
JOIN product_sales2020 as b USING(prodname)
WHERE rank BETWEEN 1 AND 5
ORDER BY 2,3;



'''
Mengevaluasi performa penjualan dan jumlah produk terjual
berdasarkan customer state
'''

WITH state_sales2020 AS( --Agregasi data setiap state di tahun 2020 untuk pembanding
	SELECT customerstate,
		SUM(totalsales) AS sales2020,
		SUM(quantity) AS qty2020
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2020
	GROUP BY 1
),

state_sales2021 AS( --Agregrasi data setiap state di tahun 2021
	SELECT customerstate,
		COUNT(orderid) AS trx2021,
		SUM(totalsales) AS sales2021,
		SUM(quantity) AS qty2021,
		COUNT(DISTINCT(customerid)) as cust2021
	FROM sales_table
	WHERE EXTRACT(YEAR FROM date)=2021
	GROUP BY 1
)

--Agregasi data total penjualan dan kuantitas serta pertumbuhan setiap state

SELECT a.customerstate,
		ROUND(sales2021) AS total_sales,
		ROUND(((sales2021-sales2020)/sales2020)*100,1) AS sales_yoygrowth,
		ROUND(sales2021/trx2021) AS AOV,
		qty2021 AS total_qty,
		ROUND(((qty2021-qty2020)/qty2020::NUMERIC)*100,1) AS qty_yoygrowth,
		ROUND(qty2021::NUMERIC/trx2021) AS avg_order_qty,
		trx2021,
		cust2021
FROM state_sales2021 as a
JOIN state_sales2020 as b USING(customerstate)
ORDER BY 2 DESC;
