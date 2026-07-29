/*
Project: Customer Segmentation (RFM Analysis) - Northwind Database
Created By: Patrick Novas
Date: 07/28/2026
Description: Analysis of customer purchasing behavior using Recency,
Frequency, and Monetary metrics on the Northwind sample database,
plus supporting business questions (churn risk, spend segmentation,
product performance, and revenue trends).
*/


/*
Description: How many total customers are there?
*/
SELECT
	COUNT(*)
FROM
	Customers;


/*
Description: How many total orders are there?
*/
SELECT
	COUNT(DISTINCT OrderID)
FROM
	Orders;


/*
Description: What is the earliest and latest OrderDate in the invoice table?
*/
SELECT
	MIN(OrderDate) AS "Earliest Order Date",
	MAX(OrderDate) AS "Latest Order Date"
FROM
	Orders;


/*
Description: Combined RFM Query. Find most recent Order Date, how many
Total Orders, and Total Spent for each customer. Adds customer name via JOIN.
*/
SELECT
	o.CustomerID AS "Customer ID",
	c.CompanyName AS "Company Name",
	MAX(o.OrderDate) AS "Most Recent Purchase",
	COUNT(DISTINCT o.OrderID) AS "Total Orders",
	SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent"
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
INNER JOIN
	Customers c
ON
	c.CustomerID = o.CustomerID
GROUP BY
	o.CustomerID
ORDER BY
	o.CustomerID;


/*
Description: Top 10 customers by total spend.
*/
SELECT
	o.CustomerID AS "Customer ID",
	c.CompanyName AS "Company Name",
	MAX(o.OrderDate) AS "Most Recent Purchase",
	COUNT(DISTINCT o.OrderID) AS "Total Orders",
	SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent"
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
INNER JOIN
	Customers c
ON
	c.CustomerID = o.CustomerID
GROUP BY
	o.CustomerID
ORDER BY
	"Total Spent" DESC
LIMIT 10;


/*
Description: Bottom 10 customers by total spend.
*/
SELECT
	o.CustomerID AS "Customer ID",
	c.CompanyName AS "Company Name",
	MAX(o.OrderDate) AS "Most Recent Purchase",
	COUNT(DISTINCT o.OrderID) AS "Total Orders",
	SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent"
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
INNER JOIN
	Customers c
ON
	c.CustomerID = o.CustomerID
GROUP BY
	o.CustomerID
ORDER BY
	"Total Spent" ASC
LIMIT 10;


/*
Description: Which customers haven't ordered recently (at risk of churning)?
Cutoff set at 2023-08-01, calibrated to this customer base's high order
frequency (a standard 6-month window returned zero results).
*/
SELECT
	CustomerID,
	MAX(OrderDate) AS "Most Recent Order Date"
FROM
	Orders
GROUP BY
	CustomerID
HAVING
	"Most Recent Order Date" < '2023-08-01'
ORDER BY
	CustomerID;


/*
Description: Find the MIN, MAX, and AVG Total Spent across all customers.
Used to inform the spend tier thresholds in the segmentation query below.
*/
SELECT
	MIN("Total Spent"),
	MAX("Total Spent"),
	AVG("Total Spent")
FROM (
	SELECT
		o.CustomerID AS "Customer ID",
		c.CompanyName AS "Company Name",
		MAX(o.OrderDate) AS "Most Recent Purchase",
		COUNT(DISTINCT o.OrderID) AS "Total Orders",
		SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent"
	FROM
		Orders o
	INNER JOIN
		OrderDetails od
	ON
		o.OrderID = od.OrderID
	INNER JOIN
		Customers c
	ON
		c.CustomerID = o.CustomerID
	GROUP BY
		o.CustomerID
);


/*
Description: Segment customers into Low, Medium, and High Spend categories.
Low: < $4,300,000 | Medium: $4,300,000-$5,199,999 | High: >= $5,200,000
Thresholds set based on the observed Min/Max/Avg Total Spent across customers.
*/
SELECT
	o.CustomerID AS "Customer ID",
	c.CompanyName AS "Company Name",
	MAX(o.OrderDate) AS "Most Recent Purchase",
	COUNT(DISTINCT o.OrderID) AS "Total Orders",
	SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent",
	CASE
		WHEN SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) < 4300000 THEN 'Low Spend'
		WHEN SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) BETWEEN 4300000 AND 5199999 THEN 'Medium Spend'
		ELSE 'High Spend'
	END AS SpendTier
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
INNER JOIN
	Customers c
ON
	c.CustomerID = o.CustomerID
GROUP BY
	o.CustomerID
ORDER BY
	"Total Spent" DESC;


/*
Description: Average order value per customer.
*/
SELECT
	o.CustomerID AS "Customer ID",
	c.CompanyName AS "Company Name",
	MAX(o.OrderDate) AS "Most Recent Purchase",
	COUNT(DISTINCT o.OrderID) AS "Total Orders",
	ROUND(SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) / COUNT(DISTINCT o.OrderID), 2) AS "Average Order Value"
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
INNER JOIN
	Customers c
ON
	c.CustomerID = o.CustomerID
GROUP BY
	o.CustomerID
ORDER BY
	o.CustomerID;


/*
Description: Top 10 best-selling products by units sold.
*/
SELECT
	p.ProductID AS "Product ID",
	p.ProductName AS "Product Name",
	SUM(od.Quantity) AS "Total Units Sold"
FROM
	Products p
INNER JOIN
	OrderDetails od
ON
	p.ProductID = od.ProductID
GROUP BY
	od.ProductID
ORDER BY
	"Total Units Sold" DESC
LIMIT 10;


/*
Description: Top 10 best-selling products by revenue.
*/
SELECT
	p.ProductID AS "Product ID",
	p.ProductName AS "Product Name",
	ROUND(SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)), 2) AS "Total Revenue Per Product"
FROM
	Products p
INNER JOIN
	OrderDetails od
ON
	p.ProductID = od.ProductID
GROUP BY
	od.ProductID
ORDER BY
	"Total Revenue Per Product" DESC
LIMIT 10;


/*
Description: Revenue by year (2012-2023). Note: 2012 and 2023 are partial
years, since the dataset begins mid-2012 and ends in October 2023.
*/
SELECT
	strftime('%Y', o.OrderDate) AS "Order Year",
	SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Revenue"
FROM
	Orders o
INNER JOIN
	OrderDetails od
ON
	o.OrderID = od.OrderID
GROUP BY
	strftime('%Y', o.OrderDate)
ORDER BY
	"Order Year";