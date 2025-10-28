/* ======================================================================
   PostgreSQL Advanced SQL Reference & Practice – Full Script
   Purpose: Procedures, functions, dedup, strings/dates, joins, counts,
            inline views, EXISTS/IN, UNIONs, MERGE (PG15+), window funcs,
            EXPLAIN, and indexing best practices.
   ====================================================================== */

/* ======================================================================
   1) Stored Procedure (no return)
   ====================================================================== */
CREATE OR REPLACE PROCEDURE sp_random(pName TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    vName TEXT;
BEGIN
    vName := pName;
    RAISE NOTICE 'Hello %', vName;
END;
$$;

-- Example call
CALL sp_random('Binaya');

/* ======================================================================
   2) Basic Function (returns value)
   ====================================================================== */
CREATE OR REPLACE FUNCTION fn_add(a INT, b INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN a + b;
END;
$$;

-- Example call
SELECT fn_add(10, 5);

/* ======================================================================
   3) Deduplication Pattern (using ROW_NUMBER and ctid)
   ====================================================================== */
DROP TABLE IF EXISTS sales_1;
CREATE TABLE sales_1 (
    sale_id     NUMERIC(10) PRIMARY KEY,
    customer_id NUMERIC(10),
    product_id  NUMERIC(10),
    sale_date   DATE,
    sale_amount NUMERIC(10, 2)
);

INSERT INTO sales_1 (sale_id, customer_id, product_id, sale_date, sale_amount) VALUES
(2, 1002, 502, DATE '2025-01-10', 200.00),
(3, 1001, 501, DATE '2025-01-10', 150.00),
(4, 1003, 503, DATE '2025-01-11', 300.00),
(5, 1001, 501, DATE '2025-01-10', 150.00),  -- duplicate of (3) on key fields below
(6, 1004, 504, DATE '2025-01-12', 400.00);

WITH dedup AS (
    SELECT
        ctid,
        customer_id, product_id, sale_date, sale_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, product_id, sale_date, sale_amount
            ORDER BY ctid DESC
        ) AS rn
    FROM sales_1
)
DELETE FROM sales_1 a
USING dedup b
WHERE a.ctid = b.ctid
  AND b.rn > 1; -- keep rn=1, delete later ones

/* ======================================================================
   4) String & Date Utilities
   ====================================================================== */
-- 4a) LEFT/RIGHT with LENGTH
SELECT
    'ktm123456'                                 AS txt,
    RIGHT('ktm123456', 6)                       AS pin_code,
    LEFT('ktm123456', LENGTH('ktm123456') - LENGTH(RIGHT('ktm123456', 6))) AS city;

-- 4b) Email split
SELECT
    'binaya.sharma@cotiviti.com' AS email,
    SPLIT_PART('binaya.sharma@cotiviti.com', '@', 1) AS user_name,
    SPLIT_PART('binaya.sharma@cotiviti.com', '@', 2) AS domain;

-- 4c) Date parts + truncation
SELECT
    EXTRACT(YEAR  FROM DATE '2025-01-01') AS year_val,
    DATE_PART('month', DATE '2025-01-01') AS month_val,
    TO_DATE(TO_CHAR(DATE_TRUNC('year', DATE '2025-02-01'), 'YYYY-MM-DD'), 'YYYY-MM-DD') AS year_start;

-- 4d) Date arithmetic + text cleanup + age
SELECT CURRENT_DATE - INTERVAL '6 days' AS six_days_back;
SELECT TRIM('  binaya ') AS cleaned_name, LTRIM('  binaya ') AS left_trimmed, RTRIM('  binaya ') AS right_trimmed;
SELECT CONCAT('binaya', ' ', 'sharma') AS full_name, 'binaya' || ' ' || 'sharma' AS full_name_alt;
SELECT AGE(CURRENT_DATE, DATE '2000-01-01') AS human_age;
SELECT (CURRENT_DATE - DATE '2000-01-01') / 365.0 AS approx_years;

/* ======================================================================
   5) Self Join (Managers vs Employees)
   ====================================================================== */
CREATE SCHEMA IF NOT EXISTS hr;

DROP TABLE IF EXISTS hr.employees;
CREATE TABLE hr.employees (
    employee_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    email           VARCHAR(100) UNIQUE,
    phone_number    VARCHAR(20),
    hire_date       DATE NOT NULL,
    job_id          VARCHAR(20) NOT NULL,
    salary          NUMERIC(10,2),
    commission_pct  NUMERIC(5,2),
    manager_id      INT,
    department_id   INT,
    CONSTRAINT fk_manager
        FOREIGN KEY (manager_id)
        REFERENCES hr.employees (employee_id)
        ON DELETE SET NULL
);

INSERT INTO hr.employees (first_name, last_name, job_id, salary, manager_id, hire_date) VALUES
('John',  'Smith',  'MGR', 8000, NULL, DATE '2022-01-01'),
('Alice', 'Brown',  'DEV', 9000, 1, DATE '2023-03-15'),
('Bob',   'Taylor', 'DEV', 7000, 1, DATE '2023-05-20'),
('Clara', 'White',  'DEV', 8500, 1, DATE '2023-06-01');

-- Employees who earn more than their manager:
SELECT
    m.employee_id AS manager_id,
    e.employee_id AS employee_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    m.salary AS manager_salary,
    e.salary AS employee_salary
FROM hr.employees e
LEFT JOIN hr.employees m
       ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

/* ======================================================================
   6) Join Duplicate Explosion Demo
   ====================================================================== */
DROP TABLE IF EXISTS order_tbl;
CREATE TABLE order_tbl (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT,
    order_date  DATE,
    amount      NUMERIC(10,2)
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id   INT,
    customer_name VARCHAR(50),
    city          VARCHAR(50)
);

INSERT INTO order_tbl (customer_id, order_date, amount) VALUES
(101, DATE '2025-10-01', 200.00),
(102, DATE '2025-10-02', 150.00),
(103, DATE '2025-10-03', 300.00);

INSERT INTO customers (customer_id, customer_name, city) VALUES
(101, 'Alice','New York'),
(101, 'Alice','NYC Duplicate'),
(102, 'Bob','Chicago'),
(103, 'Charlie','Boston'),
(103, 'Charlie','Boston Duplicate');

-- N duplicates on dimension → multiplies fact rows
SELECT COUNT(*)
FROM order_tbl o
JOIN customers c
  ON o.customer_id = c.customer_id;

-- Fix approach: deduplicate dimension first (inline view / CTE)
WITH cust_dedup AS (
  SELECT DISTINCT customer_id
  FROM customers
)
SELECT COUNT(*)
FROM order_tbl o
JOIN cust_dedup c
  ON o.customer_id = c.customer_id;

/* ======================================================================
   7) COUNT(*) vs COUNT(1) vs COUNT(column)
   ====================================================================== */
-- COUNT(*) and COUNT(1) behave the same (both count rows, include NULLs).
-- COUNT(column) counts only non-NULL values in that column.
SELECT
  COUNT(*) AS all_rows,
  COUNT(1) AS all_rows_same,
  COUNT(customer_name) AS non_null_names
FROM customers;

/* ======================================================================
   8) Inline View (subselect in FROM)
   ====================================================================== */
SELECT *
FROM (
  SELECT DISTINCT customer_id FROM customers
) AS a;

/* ======================================================================
   9) EXISTS vs IN (and NOT variants)
   ====================================================================== */
-- EXISTS: stops at first match (good for large right-side)
SELECT o.*
FROM order_tbl o
WHERE EXISTS (
  SELECT 1
  FROM customers c
  WHERE c.customer_id = o.customer_id
);

-- IN: better when right-side is small and pre-materialized
SELECT o.*
FROM order_tbl o
WHERE o.customer_id IN (SELECT customer_id FROM customers);

-- NOT EXISTS is generally safer than NOT IN (NULL pitfalls)
SELECT o.*
FROM order_tbl o
WHERE NOT EXISTS (
  SELECT 1
  FROM customers c
  WHERE c.customer_id = o.customer_id
);

/* ======================================================================
   10) UNION vs UNION ALL (and ORDER BY rule)
   ====================================================================== */
-- UNION removes duplicates (slower); UNION ALL keeps all (faster).
-- Only the final SELECT block may include ORDER BY in standard SQL.
SELECT customer_id FROM customers WHERE city = 'Chicago'
UNION ALL
SELECT customer_id FROM customers WHERE city LIKE 'Boston%'
ORDER BY customer_id;

/* ======================================================================
   11) MERGE (PostgreSQL 15+) with filters (UPSERT pattern)
   ====================================================================== */
-- Requires PostgreSQL 15 or newer.
-- Prior versions: emulate with INSERT ... ON CONFLICT or CTEs.
-- Demo tables:
DROP TABLE IF EXISTS target_table;
DROP TABLE IF EXISTS source_table;

CREATE TABLE target_table (
  id   INT PRIMARY KEY,
  col1 TEXT,
  status TEXT DEFAULT 'ACTIVE',
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE source_table (
  id       INT PRIMARY KEY,
  col1     TEXT,
  status   TEXT,
  is_valid BOOLEAN
);

INSERT INTO target_table (id, col1, status, created_at) VALUES
(1, 'old', 'ACTIVE', now());

INSERT INTO source_table (id, col1, status, is_valid) VALUES
(1, 'new',  'ACTIVE', TRUE),
(2, 'insert-me', 'ACTIVE', TRUE),
(3, 'skip-me',   'INACTIVE', TRUE);

MERGE INTO target_table AS t
USING source_table AS s
ON t.id = s.id
WHEN MATCHED AND s.status = 'ACTIVE' THEN
  UPDATE SET col1 = s.col1, updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED AND s.is_valid = TRUE AND s.status = 'ACTIVE' THEN
  INSERT (id, col1, status, created_at)
  VALUES (s.id, s.col1, s.status, CURRENT_TIMESTAMP);

/* ======================================================================
   12) Window Functions & Execution Order Reminder
   ====================================================================== */
-- Logical SQL order (conceptual):
-- FROM -> WHERE -> GROUP BY -> HAVING -> WINDOW -> SELECT -> DISTINCT -> ORDER BY -> LIMIT

-- Example: window function evaluated AFTER GROUP BY/HAVING and before ORDER BY
WITH sales AS (
  SELECT customer_id, sale_date, sale_amount FROM sales_1
)
SELECT
  customer_id,
  SUM(sale_amount) AS total_amount,
  RANK() OVER (ORDER BY SUM(sale_amount) DESC) AS rank_by_total
FROM sales
GROUP BY customer_id
ORDER BY total_amount DESC;

-- Another example: partitioned window
SELECT
  customer_id,
  sale_date,
  sale_amount,
  SUM(sale_amount) OVER (PARTITION BY customer_id ORDER BY sale_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM sales_1
ORDER BY customer_id, sale_date;

/* ======================================================================
   13) EXPLAIN / EXPLAIN ANALYZE (always verify heavy queries)
   ====================================================================== */
EXPLAIN
SELECT o.*
FROM order_tbl o
JOIN customers c ON o.customer_id = c.customer_id;

-- Runtime plan + timings (use sparingly on prod)
EXPLAIN ANALYZE
SELECT o.*
FROM order_tbl o
JOIN (
  SELECT DISTINCT customer_id FROM customers
) c ON o.customer_id = c.customer_id;

/* ======================================================================
   14) Indexing Basics (avoid full table scans on selective predicates)
   ====================================================================== */
-- Example: queries filtering on customers.customer_id → add an index
CREATE INDEX IF NOT EXISTS idx_customers_customer_id ON customers(customer_id);

-- Example: composite index for frequent join+filter patterns
-- (order of columns matters; put most selective first for many workloads)
CREATE INDEX IF NOT EXISTS idx_order_tbl_customer_date ON order_tbl(customer_id, order_date);

-- Verify usage via EXPLAIN, adjust if not chosen by planner

/* ======================================================================
   15) Bonus Tips
   ====================================================================== */
-- • Prefer CTEs to break complex logic, but inline views can be faster on older PG (CTEs were optimization fences pre-PG12).
-- • Push filters early; avoid unnecessary SELECT *; select only needed columns.
-- • Use numeric/boolean flags over text for hot predicates when possible.
-- • For high-ingest tables, consider partitioning by date/key for manageability.
-- • Use VACUUM (AUTO) + ANALYZE for healthy statistics and bloat control.

/* ======================================================================
   End of Script
   ====================================================================== */
