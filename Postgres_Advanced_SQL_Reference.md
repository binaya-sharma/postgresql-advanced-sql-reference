# PostgreSQL Advanced SQL Reference & Practice Guide

**Purpose:** A detailed and professional PostgreSQL quick-reference document covering stored procedures, functions, deduplication, string/date manipulation, joins, counting logic, and analytical SQL design patterns. This will cover 90 to 95 percent of task you do on daily basis as a analyst or data engineer.

## Table of Contents
1. [Basic Stored Procedure](#1-basic-stored-procedure)  
2. [Basic Function](#2-basic-function)  
3. [Deduplication (Removing Duplicate Records)](#3-deduplication-removing-duplicate-records)  
4. [String Manipulation](#4-string-manipulation)  
5. [Self Join Example](#5-self-join-example)  
6. [Duplicate Explosion in Joins](#6-duplicate-explosion-in-joins)  
7. [Count Variations Explained](#7-count-variations-explained)  
8. [Inline View Example](#8-inline-view-example)  
9. [EXISTS vs IN](#9-exists-vs-in)  
10. [UNION vs UNION ALL](#10-union-vs-union-all)  
11. [MERGE INTO (ANSI SQL Style)](#11-merge-into-ansi-sql-style-with-filter-condition)  
12. [Analytical SQL and Optimization Tips](#12-analytical-sql-and-optimization-tips)  
13. [SQL Logical Execution Order](#13-sql-logical-execution-order-with-window-functions)  

---

## 1. Basic Stored Procedure

```sql
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

CALL sp_random('Binaya');
```

**Explanation:**

* Demonstrates procedure creation and execution in PostgreSQL.
* `RAISE NOTICE` logs a message to the console.
* Procedures in PostgreSQL do not return a value (use `FUNCTION` for that purpose).

---

## 2. Basic Function (Example Placeholder)

```sql
CREATE OR REPLACE FUNCTION fn_add(a INT, b INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN a + b;
END;
$$;

SELECT fn_add(10, 5);
```

**Explanation:**

* Functions return a value and can be directly used in queries.
* Parameters are strongly typed.

---

## 3. Deduplication (Removing Duplicate Records)

```sql
CREATE TABLE sales_1 (
    sale_id     NUMERIC(10) PRIMARY KEY,  -- Unique sale identifier
    customer_id NUMERIC(10),              -- Customer identifier
    product_id  NUMERIC(10),              -- Product identifier
    sale_date   DATE,                     -- Date of the sale
    sale_amount NUMERIC(10, 2)            -- Amount of the sale
);

INSERT INTO sales_1 (sale_id, customer_id, product_id, sale_date, sale_amount)
VALUES
(2, 1002, 502, '2025-01-10', 200.00),
(3, 1001, 501, '2025-01-10', 150.00),
(4, 1003, 503, '2025-01-11', 300.00),
(5, 1001, 501, '2025-01-10', 150.00),
(6, 1004, 504, '2025-01-12', 400.00);

WITH dedup AS (
    SELECT 
        ctid, customer_id, product_id, sale_date, sale_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id, product_id, sale_date, sale_amount ORDER BY ctid DESC) AS rn
    FROM sales_1
)
DELETE FROM sales_1 a USING dedup b
WHERE a.ctid = b.ctid AND rn > 1; -- ctid acts as a pseudo-unique row identifier
```

**Explanation:**

* `ROW_NUMBER()` assigns a sequential rank to duplicates.
* Deletes all but the first occurrence within each duplicate set.
* `ctid` is PostgreSQL's internal unique row identifier.

---

## 4. String Manipulation

### 4.1 Using `LEFT()`, `RIGHT()`, and `LENGTH()`

```sql
SELECT 
    'ktm123456' AS txt,
    RIGHT('ktm123456', 6) AS pin_code,
    LEFT('ktm123456', LENGTH('ktm123456') - LENGTH(RIGHT('ktm123456', 6))) AS city;
```

**Explanation:**

* Extracts city and PIN parts using basic string slicing.

### 4.2 Extracting Email and Domain

```sql
SELECT 'binaya.sharma@cotiviti.com' AS email,
       SPLIT_PART('binaya.sharma@cotiviti.com', '@', 1) AS name,
       SPLIT_PART('binaya.sharma@cotiviti.com', '@', 2) AS domain;
```

**Explanation:**

* `SPLIT_PART()` splits text using a delimiter and extracts parts.

### 4.3 Date Manipulation

```sql
SELECT 
    EXTRACT(YEAR FROM '2025-01-01'::DATE) AS year_val,
    DATE_PART('month', '2025-01-01'::DATE) AS month_val,
    TO_DATE(TO_CHAR(DATE_TRUNC('year', '2025-02-01'::DATE), 'YYYY-MM-DD'), 'YYYY-MM-DD');
```

**Explanation:**

* `EXTRACT()` and `DATE_PART()` retrieve components from dates.
* `DATE_TRUNC()` resets lower precision to a specified boundary (like start of year).

### 4.4 Date Arithmetic and Cleaning Strings

```sql
SELECT CURRENT_DATE - INTERVAL '6 days' AS six_days_back;
SELECT TRIM('  binaya ') AS cleaned_name;
SELECT RTRIM('  binaya ') AS cleaned_name;
SELECT LTRIM('  binaya ') AS cleaned_name;
SELECT CONCAT('binaya', ' ', 'sharma') AS full_name, 'binaya' || ' ' || 'sharma' AS alt_concat;
SELECT AGE(CURRENT_DATE, '2000-01-01'::DATE);
SELECT (CURRENT_DATE - '2000-01-01'::DATE) / 365;
```

---

## 5. Self Join Example

```sql
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
    CONSTRAINT fk_manager FOREIGN KEY (manager_id) REFERENCES hr.employees (employee_id) ON DELETE SET NULL
);

INSERT INTO hr.employees (first_name, last_name, job_id, salary, manager_id, hire_date)
VALUES
('John', 'Smith', 'MGR', 8000, NULL, '2022-01-01'),
('Alice', 'Brown', 'DEV', 9000, 1, '2023-03-15'),
('Bob', 'Taylor', 'DEV', 7000, 1, '2023-05-20'),
('Clara', 'White', 'DEV', 8500, 1, '2023-06-01');

SELECT 
    m.employee_id AS manager_id,
    e.employee_id AS employee_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    m.salary AS manager_salary,
    e.salary AS employee_salary
FROM hr.employees e
LEFT JOIN hr.employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;
```

**Explanation:**

* A self-join is used to relate employees with their managers.
* Filters employees whose salary exceeds their manager’s.

---

## 6. Duplicate Explosion in Joins

```sql
DROP TABLE IF EXISTS order_tbl;
CREATE TABLE order_tbl (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    amount NUMERIC(10,2)
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id INT,
    customer_name VARCHAR(50),
    city VARCHAR(50)
);

INSERT INTO order_tbl (customer_id, order_date, amount)
VALUES (101, '2025-10-01', 200.00), (102, '2025-10-02', 150.00), (103, '2025-10-03', 300.00);

INSERT INTO customers (customer_id, customer_name, city)
VALUES
(101, 'Alice', 'New York'),
(101, 'Alice', 'NYC Duplicate'),
(102, 'Bob', 'Chicago'),
(103, 'Charlie', 'Boston'),
(103, 'Charlie', 'Boston Duplicate');

SELECT COUNT(*)
FROM order_tbl o
INNER JOIN customers c ON o.customer_id = c.customer_id;
```

**Explanation:**

* Demonstrates how absence of primary keys in joins can lead to duplicate record multiplication.
* 1×N relationships inflate result count.
* Always deduplicate or enforce constraints before joining.

---

## 7. Count Variations Explained

| Expression      | Includes NULLs | Description                                             |
| --------------- | -------------- | ------------------------------------------------------- |
| `COUNT(*)`      | ✅ Yes          | Counts all rows; fastest due to internal optimizations. |
| `COUNT(1)`      | ✅ Yes          | Equivalent to `COUNT(*)`; constant evaluated per row.   |
| `COUNT(column)` | ❌ No           | Counts only non-null entries.                           |

**Recommendation:** Use `COUNT(*)` for total row counts — it’s the most optimized method in PostgreSQL.

---

## 8. Inline View Example

```sql
SELECT * FROM (
    SELECT DISTINCT customer_id FROM customers
) a;
```

**Explanation:**

* Inline views behave like temporary result sets.
* Useful for filtering, pre-aggregation, and nested joins.

---

## 9. EXISTS vs IN

**Key Differences:**

* `EXISTS` checks for existence and stops after the first match → faster for large datasets.
* `IN` evaluates all possible values first → better for small datasets.
* `NOT EXISTS` is preferred over `NOT IN` as it handles NULLs correctly.

---

## 10. UNION vs UNION ALL

| Operator    | Removes Duplicates | Performance                   |
| ----------- | ------------------ | ----------------------------- |
| `UNION`     | ✅ Yes              | Slower (sort + deduplication) |
| `UNION ALL` | ❌ No               | Faster (no sorting)           |

**Order By Note:** Only the final `SELECT` can have `ORDER BY`, though each subquery can have its own filters.

---

## 11. MERGE INTO (ANSI SQL Style) with filter condition

```sql
MERGE INTO target_table t
USING source_table s
ON t.id = s.id
WHEN MATCHED AND s.status = 'ACTIVE' THEN 
    UPDATE SET 
        t.col1 = s.col1,
        t.updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED AND s.is_valid = TRUE THEN 
    INSERT (id, col1, created_at)
    VALUES (s.id, s.col1, CURRENT_TIMESTAMP);
```

**Explanation:**

* MERGE performs UPDATE or INSERT (UPSERT) in a single atomic operation.
* The optional filter conditions (AND s.status = 'ACTIVE', AND s.is_valid = TRUE) let you restrict which source rows cause updates or inserts.
* Available in PostgreSQL 15+ natively (previously emulated via CTE or INSERT ... ON CONFLICT).
* Common use-cases:
* Loading incremental data into a data warehouse.
* Applying CDC (Change Data Capture) logic.
* Managing SCD Type 2 or Type 1 dimensional tables.

---

## 12. Analytical SQL and Optimization Tips

* Use CTEs (`WITH` clauses) to simplify and modularize complex logic.
* Prefer **window functions** (e.g., `RANK()`, `LAG()`, `SUM() OVER()`) for advanced analytics.
* Compute condition-based metrics using:

  ```sql
  COUNT(CASE WHEN condition THEN 1 END),
  SUM(CASE WHEN condition THEN amount ELSE 0 END)
  ```
* Use `EXPLAIN ANALYZE` before running heavy queries to review query plans.
* Apply **predicate pushdown**: filter as early as possible.
* Avoid unnecessary nested subqueries.

---

## 13. SQL logical execution order (with window functions)

```
FROM → WHERE → GROUP BY → HAVING → Window functions → SELECT → ORDER BY → LIMIT
```
1. FROM

2.	ON (join predicates)

3.	JOIN (form the row set)

4.	WHERE (row filtering; no window funcs here)

5.	GROUP BY (build groups)

6.	HAVING (filter groups; no window funcs here)

7.	WINDOW clause (defines named windows, if used)

8.	SELECT (evaluate expressions)

    • Aggregates are already resolved from step 5

    • Window functions are evaluated here (after GROUP BY/HAVING, on the current row set)

    • You can’t reference window functions inside WHERE/GROUP BY/HAVING because they don’t exist yet

9.	DISTINCT (if present, applied after SELECT expressions—including window results)

10.	ORDER BY (you can order by window-function results)

11.	LIMIT / OFFSET / FETCH


---

**End of Document — PostgreSQL Advanced SQL Guide**
