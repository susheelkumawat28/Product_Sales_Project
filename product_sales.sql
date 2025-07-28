CREATE DATABASE IF NOT EXISTS product_sales;
USE  product_sales;
CREATE TABLE sales (
    segment VARCHAR(30),
    country VARCHAR(30),
    product_name VARCHAR(40),
    unit_sold INT,
    manufacturing_price DECIMAL(10,2),
    sales_price DECIMAL(10,2),
    gross_sales DECIMAL(15,2),
    discount DECIMAL(10,2),
    sales DECIMAL(15,2),
    cogs DECIMAL(15,2),
    profit DECIMAL(15,2),
    date DATE
);

-- "What is the total revenue (Sales) generated each year?"

SELECT YEAR(date) AS year, SUM(sales) AS total_revenue
FROM sales
GROUP BY year
ORDER BY year;

-- Top 5 countries by total sales

SELECT country, SUM(sales) AS total_sales
FROM sales
GROUP BY country
ORDER BY total_sales DESC
LIMIT 5;

-- Total profit by segment

 SELECT segment, SUM(profit) AS total_profit
 FROM sales
 GROUP BY segment
 ORDER BY total_profit DESC;
 
-- "Which customer segment (e.g., Government, Small Business) is the most profitable?"

SELECT segment, SUM(profit) AS total_profit
FROM sales
GROUP BY segment
ORDER BY total_profit DESC LIMIT 1;


-- "How do monthly sales vary throughout the year?"

SELECT DATE_FORMAT(date, "%Y-%m") AS monthly, SUM(sales) AS total_sales
FROM sales
GROUP BY monthly
ORDER BY monthly;

-- "Which products have the highest profit margins relative to units sold?"

SELECT product_name, unit_sold, profit , profit/unit_sold AS profit_margin
FROM sales
WHERE profit > 0
ORDER BY profit_margin DESC LIMIT 5;

-- "Which product performs best in each country?"

WITH ranked_products AS (
  SELECT 
    country,
    product_name,
    SUM(sales) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY country ORDER BY SUM(sales) DESC) AS rn
  FROM sales
  GROUP BY country, product_name
)
SELECT 
  country,
  product_name,
  total_sales
FROM ranked_products
WHERE rn = 1;

-- "How do discounts affect profit and sales?"

SELECT 
  discount,
  COUNT(*) AS total_transactions,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
  ROUND(AVG(sales), 2) AS avg_sales_per_txn,
  ROUND(AVG(profit), 2) AS avg_profit_per_txn
FROM sales
WHERE discount > 0
GROUP BY discount
ORDER BY discount DESC;

-- "What is the percentage change in sales and profit year-over-year?"

WITH yearly_summary AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY EXTRACT(YEAR FROM date)
),
yoy_change AS (
    SELECT
        year,
        total_sales,
        total_profit,
        LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
        LAG(total_profit) OVER (ORDER BY year) AS prev_year_profit
    FROM yearly_summary
)
SELECT
    year,
    total_sales,
    total_profit,
    ROUND(((total_sales - prev_year_sales) / prev_year_sales) * 100, 2) AS sales_yoy_pct_change,
    ROUND(((total_profit - prev_year_profit) / prev_year_profit) * 100, 2) AS profit_yoy_pct_change
FROM yoy_change
WHERE prev_year_sales IS NOT NULL;

-- "What is the running total of sales per month in a given year?"

WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(MONTH FROM date) AS month,
        DATE_FORMAT(date, '%b') AS month_name,
        SUM(sales) AS monthly_sales
    FROM sales
    GROUP BY EXTRACT(YEAR FROM date), EXTRACT(MONTH FROM date), DATE_FORMAT(date, '%b')
)
SELECT
    year,
    month,
    month_name,
    monthly_sales,
    SUM(monthly_sales) OVER (
        PARTITION BY year
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales
FROM monthly_sales
ORDER BY year, month;


-- "Which months consistently show high or low sales across years?"

WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(MONTH FROM date) AS month,
        MONTHNAME(date) AS month_name,
        SUM(sales) AS total_sales
    FROM sales
    GROUP BY year, month, MONTHNAME(date)
),
 monthly_avg AS (
    SELECT
        month,
        month_name,
        ROUND(AVG(total_sales), 2) AS avg_sales,
        ROUND(STDDEV(total_sales), 2) AS sales_stddev
    FROM monthly_sales
    GROUP BY month, month_name
)
SELECT
    month,
    month_name,
    avg_sales,
    sales_stddev,
    CASE
        WHEN avg_sales >= (SELECT AVG(avg_sales) FROM monthly_avg) THEN 'High Sales Month'
        ELSE 'Low Sales Month'
    END AS sales_trend
FROM monthly_avg
ORDER BY avg_sales DESC;









