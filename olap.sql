-- 1) Create database and use it (MySQL style)
CREATE DATABASE IF NOT EXISTS dw_sales;
USE dw_sales;

-- 2) Dimension tables
CREATE TABLE dim_date (
  date_id INT PRIMARY KEY AUTO_INCREMENT,
  date DATE NOT NULL,
  day INT,
  month INT,
  year INT,
  quarter INT
);

CREATE TABLE dim_product (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  product_name VARCHAR(100),
  category VARCHAR(50)
);

CREATE TABLE dim_store (
  store_id INT PRIMARY KEY AUTO_INCREMENT,
  store_name VARCHAR(100),
  region VARCHAR(50)
);

CREATE TABLE dim_customer (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_name VARCHAR(100),
  segment VARCHAR(50)
);

-- 3) Fact table
CREATE TABLE fact_sales (
  sale_id INT PRIMARY KEY AUTO_INCREMENT,
  date_id INT,
  product_id INT,
  store_id INT,
  customer_id INT,
  quantity INT,
  unit_price DECIMAL(10,2),
  total_amount DECIMAL(12,2),
  FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
  FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
  FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
  FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

-- 4) Insert dimension data (explicit ids are fine with AUTO_INCREMENT)
INSERT INTO dim_date (date_id, date, day, month, year, quarter) VALUES
 (1,'2025-08-01',1,8,2025,3),
 (2,'2025-08-15',15,8,2025,3),
 (3,'2025-09-05',5,9,2025,3),
 (4,'2025-09-10',10,9,2025,3),
 (5,'2025-09-20',20,9,2025,3),
 (6,'2025-10-01',1,10,2025,4);

INSERT INTO dim_product (product_id, product_name, category) VALUES
 (1,'Laptop','Electronics'),
 (2,'Mouse','Accessories'),
 (3,'Chair','Furniture'),
 (4,'Desk','Furniture');

INSERT INTO dim_store (store_id, store_name, region) VALUES
 (1,'Store A','North'),
 (2,'Store B','South'),
 (3,'Store C','East');

INSERT INTO dim_customer (customer_id, customer_name, segment) VALUES
 (1,'Alice','Retail'),
 (2,'Bob','Retail'),
 (3,'Charlie','Corporate');

-- 5) Insert some fact rows (total_amount = quantity * unit_price)
INSERT INTO fact_sales (date_id, product_id, store_id, customer_id, quantity, unit_price, total_amount) VALUES
 (1,1,1,1,1,1000.00,1000.00),
 (2,2,2,2,2,25.00,50.00),
 (3,1,1,3,1,1000.00,1000.00),
 (4,3,3,1,3,150.00,450.00),
 (5,4,2,2,1,300.00,300.00),
 (6,2,1,1,4,20.00,80.00),
 (4,2,1,3,1,25.00,25.00),
 (2,3,3,2,2,150.00,300.00),
 (3,4,3,3,1,300.00,300.00),
 (6,1,2,2,2,950.00,1900.00);

-- 6) Helpful indexes
CREATE INDEX idx_fact_date ON fact_sales(date_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_store ON fact_sales(store_id);

-- 7) Create a view to simplify OLAP queries
CREATE OR REPLACE VIEW v_sales AS
SELECT
  s.sale_id,
  d.date,
  d.day,
  d.month,
  d.year,
  d.quarter,
  p.product_name,
  p.category,
  st.store_name,
  st.region,
  c.customer_name,
  s.quantity,
  s.unit_price,
  s.total_amount
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
JOIN dim_product p ON s.product_id = p.product_id
JOIN dim_store st ON s.store_id = st.store_id
JOIN dim_customer c ON s.customer_id = c.customer_id;

---------------------------
-- OLAP operations start
---------------------------

-- SLICE: fix one dimension value. Example: all sales in region = 'North'
SELECT date, store_name, product_name, quantity, total_amount
FROM v_sales
WHERE region = 'North'
ORDER BY date;

-- DICE: choose a subcube by filtering multiple dimensions.
-- Example: Electronics or Furniture in North or East for year 2025
SELECT region, category, SUM(total_amount) AS total_sales, SUM(quantity) AS total_qty
FROM v_sales
WHERE category IN ('Electronics','Furniture')
  AND region IN ('North','East')
  AND year = 2025
GROUP BY region, category
ORDER BY region, category;

-- DRILLDOWN: move from summary to detail.
-- First get monthly sales summary (summary level)
SELECT year, month, SUM(total_amount) AS monthly_sales
FROM v_sales
GROUP BY year, month
ORDER BY year, month;

-- Then drill down to daily for Sept 2025 (more detailed)
SELECT date, SUM(total_amount) AS daily_sales
FROM v_sales
WHERE year = 2025 AND month = 9
GROUP BY date
ORDER BY date;

-- ROLLUP: subtotals plus grand total. Many engines support GROUP BY ROLLUP.
-- This gives totals per year, per year+month, plus grand total row.
SELECT
  COALESCE(CAST(year AS CHAR), 'ALL YEARS') AS year_label,
  COALESCE(CAST(month AS CHAR), 'ALL MONTHS') AS month_label,
  SUM(total_amount) AS sales
FROM v_sales
GROUP BY ROLLUP(year, month)
ORDER BY year_label, month_label;

-- PIVOT: convert rows to columns. Portable method using CASE.
-- Pivot monthly sales by category (Electronics, Furniture, Accessories)
SELECT
  month,
  SUM(CASE WHEN category = 'Electronics' THEN total_amount ELSE 0 END) AS electronics_sales,
  SUM(CASE WHEN category = 'Furniture' THEN total_amount ELSE 0 END) AS furniture_sales,
  SUM(CASE WHEN category = 'Accessories' THEN total_amount ELSE 0 END) AS accessories_sales,
  SUM(total_amount) AS total_sales
FROM v_sales
GROUP BY month
ORDER BY month;

-- Optional: SQL Server style PIVOT example (uncomment in SQL Server)
-- SELECT month, [Electronics], [Furniture], [Accessories], [NULL] FROM (
--   SELECT month, category, total_amount FROM v_sales
-- ) t
-- PIVOT (
--   SUM(total_amount) FOR category IN ([Electronics],[Furniture],[Accessories])
-- ) pvt
-- ORDER BY month;
