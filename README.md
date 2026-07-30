# Customer Segmentation (RFM Analysis) - Northwind Database

## Overview
This project analyzes customer purchasing behavior using **RFM analysis** (Recency, Frequency, Monetary value) on the Northwind sample database, a classic relational dataset modeling a small wholesale trading company (customers, orders, order details, products).

The goal was to identify high-value customers, flag at-risk customers who haven't ordered recently, and segment the customer base by spend. I wanted to answer common business questions a data analyst might be asked to answer.

## Tools Used
- **SQLite** (via DB Browser for SQLite)
- SQL only, no external libraries or visualization tools

## Dataset
[Northwind](https://github.com/jpwhite3/northwind-SQLite3), a classic relational sample database representing a small wholesale trading company. This version includes:
- 93 customers
- 16,282 orders
- Order data spanning 2012–2023

Unlike the traditional textbook version of Northwind, this dataset has been scaled up significantly (more orders, more line items per order), giving it more realistic range and variance for analysis than smaller sample datasets typically offer.



## Key Steps

**1. Data exploration.** I confirmed row counts, distinct customers, and the date range of the dataset before building any analysis.

**2. RFM calculation.** I calculated Recency (most recent order date), Frequency (distinct order count), and Monetary value (total spend) per customer, joining `Orders`, `OrderDetails`, and `Customers`.

**3. Monetary value required a discount-adjusted formula.** Order line items include a `Discount` field stored as a decimal percentage (e.g., `0.1` = 10% off). The actual amount charged per line item is:

```sql
UnitPrice * Quantity * (1 - Discount)
```

**4. Verified an unusually large total spend figure.** The initial totals in the millions per customer seemed too high at first glance. I cross-checked average unit price, average quantity, and average line items per order (~37 per order, well above a typical order) to confirm the numbers were internally consistent rather than a query error.

**5. Customer segmentation.** I segmented customers into High/Medium/Low spend tiers using `CASE WHEN`, with thresholds set from the observed min/max/average total spend across all customers.

**6. Churn-risk flagging.** I flagged customers with no orders in the last several months. A standard 6-month lookback window returned zero results, since this customer base orders too frequently for that window to be meaningful, so the cutoff was recalibrated to a little over 3 months based on the actual distribution of "most recent order" dates across customers.

**7. Product-level analysis.** I compared top 10 products by **units sold** vs. top 10 products by **revenue generated**. These were almost entirely different products, highlighting the difference between high-volume, everyday items and lower-volume, premium products.

**8. Revenue trend by year**, I extracted the year from each order date to see overall growth across the dataset's 11-year span.

## Sample Query: Combined RFM Analysis

```sql
SELECT
    o.CustomerID AS "Customer ID",
    c.CompanyName AS "Company Name",
    MAX(o.OrderDate) AS "Most Recent Purchase",
    COUNT(DISTINCT o.OrderID) AS "Total Orders",
    SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS "Total Spent"
FROM
    Orders o
INNER JOIN
    OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN
    Customers c ON c.CustomerID = o.CustomerID
GROUP BY
    o.CustomerID
ORDER BY
    o.CustomerID;
```

## Findings
- Customer spend ranges from roughly **$3.97M to $6.15M**, with an average around **$4.82M**, a meaningful spread despite a fairly consistent order count per customer (about 150 to 210 orders each).
- The highest-spending customer, B's Beverages, also places the most orders (210), so in this dataset order frequency and order value point in the same direction for the top customer. Further down the list, though, spend and order count do not always track together, so both metrics are worth tracking separately rather than assuming one predicts the other.
- **5 of 93 customers** (about 5%) qualify as at-risk under a recalibrated 4-month inactivity window.
- **Best-selling products by volume and by revenue are almost entirely different lists.** Only one product appeared on both top-10 rankings. This distinction matters for inventory planning (volume) versus profitability focus (revenue).
- Revenue held fairly steady in the high $30M to low $40M range per year from 2013 to 2022, with 2012 and 2023 appearing lower. Both are partial years in the dataset, not a genuine decline.

## Next Steps
I plan on plugging this analysis on Tableau once I get more experience on the platform to extend this analysis into an interactive dashboard, filterable by spend tier, region, or time period, to make these findings easier to explore to present stakeholders.

## Files
- `northwind_customer_analysis.sql`: full SQL script covering all queries described above, with inline comments documenting each step.
