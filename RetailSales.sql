-- Data Exploration

SELECT * FROM retailsales
ORDER BY 2;

-- Cleaning Data
-- 1. Checking for Duplicate Data By Transaction_ID

with rownum as
(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY customer_ID, Date, Customer_ID ORDER BY Transaction_id) as identifier
	FROM RetailSales
)

SELECT * FROM rownum WHERE identifier >1;  -- No duplicate data found base on transaction_ID


-- Question To Explore

-- 1. How does customer gender and age influence their purchasing behavior?

-- Purchasing Behavior Base on Gender

SELECT Gender, 
	COUNT(Transaction_ID) PurchaseFreq, 
	SUM(quantity) TotalQuantity,
	AVG(quantity) AvgQuantity,
	AVG(Total_Amount) AvgSpending, 
	SUM(Total_Amount) TotalSpending
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Gender
ORDER BY 2 DESC;

-- Purchasing Behavior Base on Age

SELECT Age, 
	COUNT(Transaction_ID) PurchaseFreq, 
	SUM(quantity) TotalQuantity,
	AVG(quantity) AvgQuantity,
	AVG(Total_Amount) AvgSpending, 
	SUM(Total_Amount) TotalSpending
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Age
ORDER BY 6 DESC;

-- Gender and Age Classification

DROP TABLE IF EXISTS #genclassification	
;with genbehav as
(
	SELECT *,
		CASE WHEN gender = 'Male' and Age >=18 and age <=30 THEN 'Young Men'
			 WHEN gender = 'Male' and Age >30 and age <=50 THEN 'Adult Men'
			 WHEN gender = 'Male' and Age >50 THEN 'Old Men'
			 WHEN gender = 'Female' and Age >=18 and age <=30 THEN 'Young Woman'
			 WHEN gender = 'Female' and Age >30 and age <=50 THEN 'Adult Woman'
			 WHEN gender = 'Female' and Age >50 THEN 'Old Woman'
		END as GendClass
	FROM RetailSales
)

SELECT * 
INTO #genclassification
FROM genbehav;

SELECT GendClass, 
	COUNT(Transaction_ID) PurchaseFreq, 
	SUM(quantity) TotalQuantity,
	AVG(quantity) AvgQuantity,
	AVG(Total_Amount) AvgSpending, 
	SUM(Total_Amount) TotalSpending
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY GendClass
ORDER BY 2 DESC;


-- 1.1 Which product categories hold the highest appeal among customers?

SELECT Gendclass,
		Product_Category,
		COUNT(Product_Category) TotalPurchase,
		SUM(Quantity) TotalQuantity,
		SUM(Total_Amount) Revenue
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Gendclass, Product_Category
ORDER BY 1, 3 DESC;


-- 1.2 Willingness To Pay Per Unit

-- In General 

SELECT Gendclass,  
	   Price_Per_Unit,
	   COUNT(Transaction_ID) NumbofPurchase,
	   SUM(Quantity) Quantity,
	   SUM(Total_Amount) TotalSales
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Gendclass, 
	     Price_Per_Unit
ORDER BY 1;

-- Base On Product Category

SELECT Gendclass, 
	   Product_Category, 
	   Price_Per_Unit,
	   COUNT(Transaction_ID) NumbofPurchase,
	   SUM(Quantity) Quantity,
	   SUM(Total_Amount) TotalSales
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Gendclass, 
		 Product_Category, 
	     Price_Per_Unit
ORDER BY 1;


-- 1.3 Who is Our TOP 5 Customer?

-- In General

SELECT TOP 5 Customer_ID,  
			SUM(Total_Amount) as TotalSpend 
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Customer_ID
ORDER BY 2 DESC;

-- For Every Product Category

SELECT TOP 5 Customer_ID,
			Product_Category,
			SUM(Total_Amount) as TotalSpend 
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023 AND Product_Category = 'Beauty'  -- Change Product_Category to Beauty, Clothing, Electronic
GROUP BY Customer_ID, Product_Category
ORDER BY 3 DESC;


-- 1.4 Who is Our BOTTOM 5 Customer?

-- In General

SELECT TOP 5 Customer_ID,  
			SUM(Total_Amount) as TotalSpend 
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Customer_ID
ORDER BY 2 ASC;

-- For Every Product Category

SELECT TOP 5 Customer_ID,
			Product_Category,
			SUM(Total_Amount) as TotalSpend 
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023 AND Product_Category = 'Beauty'  -- Change Product_Category to Beauty, Clothing, Electronic
GROUP BY Customer_ID, Product_Category
ORDER BY 3 ASC;

-- 2. Are there distinct purchasing behaviors based on the number of items bought per transaction?

DROP TABLE IF EXISTS #numbtransac
;with a as
(
	SELECT *,
		CASE WHEN Quantity = 1 THEN 'Single Item'
			 WHEN Quantity > 1 THEN 'Multiple Item'
		END numbitem
	FROM RetailSales
	WHERE DATEPART(YEAR, date) = 2023
)

SELECT *
INTO #numbtransac
FROM a

-- General

SELECT numbitem, 
	COUNT(Transaction_ID) PurchaseFreq, 
	SUM(quantity) TotalQuantity,
	AVG(quantity) AvgQuantity,
	AVG(Total_Amount) AvgSpending, 
	SUM(Total_Amount) TotalSpending
FROM #numbtransac
GROUP BY numbitem
ORDER BY 2 DESC;

-- Base on Gender and Age Segmentation

SELECT Gendclass,
		numbitem,
		COUNT(n.Transaction_ID) PurchaseFreq, 
		SUM(n.Quantity) TotalQuantity,
		AVG(n.Quantity) AvgQuantity,
		AVG(n.Total_Amount) AvgSpending, 
		SUM(n.Total_Amount) TotalSpending
FROM #numbtransac n
JOIN #genclassification g 
ON n.Transaction_ID = g.Transaction_ID
GROUP BY Gendclass, numbitem
ORDER BY 1;

-- Base on Product Category

SELECT Product_Category,
		numbitem,
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #numbtransac
GROUP BY Product_Category, numbitem
ORDER BY 1;
	 
-- Base on Price Distribution

SELECT Product_Category,
	   numbitem,
	   Price_Per_Unit,
	   COUNT(Transaction_ID) NumbofPurchase,
	   SUM(Quantity) Quantity,
	   SUM(Total_Amount) TotalSales
FROM #numbtransac
GROUP BY Product_Category,
		 numbitem,
	     Price_Per_Unit
ORDER BY 1;

-- 3. Are there discernible patterns in sales across different time periods?

-- 3.1 Base on Month, Quarter, and Month Segmentation

--General Sales Trend in Month

SELECT	DATEPART(MONTH, date) Month,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(MONTH, date)
ORDER BY 5 DESC;

-- General Sales Trend in Quartal

SELECT	'Q' + CAST(DATEPART(QUARTER, date) AS VARCHAR(1)) Quartal,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(QUARTER, date)
ORDER BY 5 DESC;

-- General Sales Trend Base On Early, Mid, End of Month

DROP TABLE IF EXISTS #monthsegmentation
;with Monthclass as
(
	SELECT *,
		CASE WHEN DATEPART(DAY, Date) <=10 THEN 'Early Month'
			 WHEN DATEPART(DAY, Date) <=20 THEN 'Mid Month'
			 WHEN DATEPART(DAY, Date) <=31 THEN 'End Month'
		END Monthseg,
		CASE WHEN DATEPART(WEEKDAY, date) = 1 THEN 'Weekend'
			 WHEN DATEPART(WEEKDAY, date) = 7 THEN 'Weekend'
			 WHEN DATEPART(WEEKDAY, date) > 1 THEN 'Weekday'
			 WHEN DATEPART(WEEKDAY, date) < 7 THEN 'Weekday'
		END Dayseg
	FROM retailsales
	WHERE DATEPART(YEAR, date) = 2023
)

SELECT *
INTO #monthsegmentation
FROM Monthclass;

SELECT * FROM #monthsegmentation

-- In General

SELECT	Monthseg,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #monthsegmentation
GROUP BY Monthseg
ORDER BY 2 DESC;

-- For Every Month

SELECT	DATEPART(MONTH, date) Month,
		Monthseg,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #monthsegmentation
GROUP BY Monthseg, DATEPART(MONTH, date)
ORDER BY 1;


-- Trend Weekday VS Weekend

-- In General

SELECT Dayseg,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #monthsegmentation
GROUP BY Dayseg;

-- For Weekday in Every Month

SELECT Dayseg,
		DATEPART(MONTH, date) Month,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #monthsegmentation
WHERE Dayseg = 'Weekday'
GROUP BY Dayseg, DATEPART(MONTH, date);

-- For Weekend in Every Month

SELECT Dayseg,
		DATEPART(MONTH, date) Month,
		COUNT(Transaction_ID) NumbTransc,
		SUM(Quantity) TotalQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #monthsegmentation
WHERE Dayseg = 'Weekend'
GROUP BY Dayseg, DATEPART(MONTH, date);


--  3.2 Sales Trend Base On Gender & Age Classification in Month & Quarter

-- In Month

SELECT DATEPART(MONTH, date) Month,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(quantity) TotalQuantity,
		AVG(quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(MONTH, date), Gender
ORDER BY 1;

SELECT	DATEPART(MONTH, date) Month, 
		GendClass,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(MONTH, date), GendClass
ORDER BY 1;

-- In Quarter

SELECT 'Q'+ CAST(DATEPART(QUARTER, date) AS VARCHAR(1)) Quarter,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(quantity) TotalQuantity,
		AVG(quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(QUARTER, date), Gender
ORDER BY 1;

SELECT	'Q'+ CAST(DATEPART(QUARTER, date) AS VARCHAR(1)) Quarter, 
		GendClass,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM #genclassification
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(QUARTER, date), GendClass
ORDER BY 1;

-- In Early, Mid, End Month Segmentation

SELECT Monthseg,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Monthseg, Gender
ORDER BY 1;

SELECT Monthseg,
		Gendclass, 
		COUNT(g.Transaction_ID) PurchaseFreq, 
		SUM(g.Quantity) TotalQuantity,
		AVG(g.Quantity) AvgQuantity,
		AVG(g.Total_Amount) AvgSpending, 
		SUM(g.Total_Amount) TotalSpending
FROM #genclassification g
JOIN #monthsegmentation m
ON g.Transaction_ID = m.Transaction_ID
GROUP BY Monthseg, Gendclass
ORDER BY 1;

-- Weekday VS Weekend

-- Gender in General

SELECT Dayseg,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Dayseg, Gender
ORDER BY 1;

-- For Weekday in Every Month

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekday'
GROUP BY DATEPART(MONTH, date), Dayseg, Gender
ORDER BY 1;

-- For Weekend in Every Month

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Gender, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekend'
GROUP BY DATEPART(MONTH, date), Dayseg, Gender
ORDER BY 1;

-- Gender and Age Classification in General

SELECT Dayseg,
		Gendclass, 
		COUNT(g.Transaction_ID) PurchaseFreq, 
		SUM(g.Quantity) TotalQuantity,
		AVG(g.Quantity) AvgQuantity,
		AVG(g.Total_Amount) AvgSpending, 
		SUM(g.Total_Amount) TotalSpending
FROM #genclassification g
JOIN #monthsegmentation m
ON g.Transaction_ID = m.Transaction_ID
GROUP BY Dayseg, Gendclass
ORDER BY 2;

-- For Weekday in Every Month

SELECT  DATEPART(MONTH, g.date) Month,
		Dayseg,
		Gendclass, 
		COUNT(g.Transaction_ID) PurchaseFreq, 
		SUM(g.Quantity) TotalQuantity,
		AVG(g.Quantity) AvgQuantity,
		AVG(g.Total_Amount) AvgSpending, 
		SUM(g.Total_Amount) TotalSpending
FROM #genclassification g
JOIN #monthsegmentation m
ON g.Transaction_ID = m.Transaction_ID
WHERE Dayseg = 'Weekday'
GROUP BY DATEPART(MONTH, g.date), Dayseg, Gendclass
ORDER BY 2;

-- For Weekend in Every Month

SELECT  DATEPART(MONTH, g.date) Month,
		Dayseg,
		Gendclass, 
		COUNT(g.Transaction_ID) PurchaseFreq, 
		SUM(g.Quantity) TotalQuantity,
		AVG(g.Quantity) AvgQuantity,
		AVG(g.Total_Amount) AvgSpending, 
		SUM(g.Total_Amount) TotalSpending
FROM #genclassification g
JOIN #monthsegmentation m
ON g.Transaction_ID = m.Transaction_ID
WHERE Dayseg = 'Weekend'
GROUP BY DATEPART(MONTH, g.date), Dayseg, Gendclass
ORDER BY 2;

-- 3.3 Sales Trend Base On Product Category

-- In General

SELECT	Product_Category,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY Product_Category
ORDER BY 2 DESC;

-- In Month

SELECT	DATEPART(MONTH, date) Month,
		Product_Category,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(MONTH, date), Product_Category
ORDER BY 1;

SELECT	DATEPART(MONTH, date) Month,
		Product_Category,
		Price_Per_Unit,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(MONTH, date), Product_Category, Price_Per_Unit
ORDER BY 1;

-- In Quarter

SELECT	'Q'+ CAST(DATEPART(QUARTER, date) AS VARCHAR(1)) Quarter,
		Product_Category,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(QUARTER, date), Product_Category
ORDER BY 1;

SELECT	'Q'+ CAST(DATEPART(QUARTER, date) AS VARCHAR(1)) Quarter,
		Product_Category,
		Price_per_Unit,
		COUNT(Transaction_ID) NumberofPurchase,
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSales,
		SUM(Total_Amount) TotalSales
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023
GROUP BY DATEPART(QUARTER, date), Product_Category, Price_per_Unit
ORDER BY 1;

-- In Early, Mid, End Month Segmentation

SELECT Monthseg,
		Product_Category, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Monthseg, Product_Category
ORDER BY 1;

SELECT Monthseg,
		Product_Category, 
		Price_Per_Unit,
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Monthseg, Product_Category, Price_per_Unit
ORDER BY 1, 2, 4 DESC;

-- Weekday VS Weekend

SELECT Dayseg,
		Product_Category, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Dayseg, Product_Category
ORDER BY 2;

SELECT Dayseg,
		Product_Category,
		Price_Per_Unit,
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
GROUP BY Dayseg, Product_Category, Price_per_Unit
ORDER BY 1,2,4 DESC;

-- For Weekday in Every Month

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Product_Category, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekday'
GROUP BY DATEPART(MONTH, date), Dayseg, Product_Category
ORDER BY 1,3;

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Product_Category,
		Price_Per_Unit,
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekday'
GROUP BY DATEPART(MONTH, date), Dayseg, Product_Category, Price_per_Unit
ORDER BY 1,3,4;

-- For Weekend in Every Month

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Product_Category, 
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekend'
GROUP BY DATEPART(MONTH, date), Dayseg, Product_Category
ORDER BY 1,3;

SELECT  DATEPART(MONTH, date) Month,
		Dayseg,
		Product_Category,
		Price_Per_Unit,
		COUNT(Transaction_ID) PurchaseFreq, 
		SUM(Quantity) TotalQuantity,
		AVG(Quantity) AvgQuantity,
		AVG(Total_Amount) AvgSpending, 
		SUM(Total_Amount) TotalSpending
FROM #monthsegmentation
WHERE Dayseg = 'Weekend'
GROUP BY DATEPART(MONTH, date), Dayseg, Product_Category, Price_per_Unit
ORDER BY 1,3,4;


-- CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW retailsalesdata AS
SELECT *,
	CASE WHEN gender = 'Male' and Age >=18 and age <=30 THEN 'Young Men'
		 WHEN gender = 'Male' and Age >30 and age <=50 THEN 'Adult Men'
		 WHEN gender = 'Male' and Age >50 THEN 'Old Men'
		 WHEN gender = 'Female' and Age >=18 and age <=30 THEN 'Young Woman'
		 WHEN gender = 'Female' and Age >30 and age <=50 THEN 'Adult Woman'
		 WHEN gender = 'Female' and Age >50 THEN 'Old Woman'
	END as GenderSeg,
	CASE WHEN DATEPART(DAY, Date) <=10 THEN 'Early Month'
		 WHEN DATEPART(DAY, Date) <=20 THEN 'Mid Month'
		 WHEN DATEPART(DAY, Date) <=31 THEN 'End Month'
	END Monthseg,
	CASE WHEN DATEPART(WEEKDAY, date) = 1 THEN 'Weekend'
		 WHEN DATEPART(WEEKDAY, date) = 7 THEN 'Weekend'
		 WHEN DATEPART(WEEKDAY, date) > 1 THEN 'Weekday'
		 WHEN DATEPART(WEEKDAY, date) < 7 THEN 'Weekday'
	END Dayseg,
	CASE WHEN Quantity = 1 THEN 'Single Item'
		 WHEN Quantity > 1 THEN 'Multiple Item'
	END itemseg
FROM retailsales
WHERE DATEPART(YEAR, date) = 2023

SELECT * FROM retailsalesdata