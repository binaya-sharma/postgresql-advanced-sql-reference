# PostgreSQL Data Types Reference

This document provides a detailed explanation of PostgreSQL data types  including numeric, character, date/time, boolean, and advanced types  along with examples and real-world usage scenarios.

---

## 1. Numeric Data Types

PostgreSQL supports both **exact** and **approximate** numeric data types. The key distinction lies in precision and performance.

### 1.1 Integer Types

| Type              | Storage | Range                                                    | Example                            |
| ----------------- | ------- | -------------------------------------------------------- | ---------------------------------- |
| **SMALLINT**      | 2 bytes | -32,768 to 32,767                                        | `CREATE TABLE demo (id SMALLINT);` |
| **INTEGER / INT** | 4 bytes | -2,147,483,648 to +2,147,483,647                         | `CREATE TABLE demo (id INT);`      |
| **BIGINT**        | 8 bytes | -9,223,372,036,854,775,808 to +9,223,372,036,854,775,807 | `CREATE TABLE demo (id BIGINT);`   |

**Example:**

```sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    total_amount BIGINT
);
```

---

### 1.2 Decimal and Numeric (Exact Precision)

Used when you need **financial accuracy** (e.g., prices, billing, tax calculations).

| Type              | Description               | Example                                                  |
| ----------------- | ------------------------- | -------------------------------------------------------- |
| **NUMERIC(p, s)** | Fixed precision and scale | `NUMERIC(10,2)` → up to 10 digits total, 2 after decimal |
| **DECIMAL(p, s)** | Synonym for NUMERIC       | `DECIMAL(12,4)`                                          |

**Example:**

```sql
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    amount NUMERIC(10,2),
    tax DECIMAL(5,2)
);

INSERT INTO payments (amount, tax) VALUES (1999.99, 99.99);
SELECT amount + tax AS total_due FROM payments;
```

**Note:** NUMERIC and DECIMAL are exact types; no rounding errors occur.

---

### 1.3 Floating-Point (Approximate Precision)

Used when you prioritize performance and can tolerate rounding errors  ideal for analytical or scientific calculations.

| Type                          | Storage | Precision          | Example                                             |
| ----------------------------- | ------- | ------------------ | --------------------------------------------------- |
| **REAL / FLOAT4**             | 4 bytes | ~6 decimal digits  | `CREATE TABLE metrics (ratio REAL);`                |
| **DOUBLE PRECISION / FLOAT8** | 8 bytes | ~15 decimal digits | `CREATE TABLE metrics (accuracy DOUBLE PRECISION);` |

**Example:**

```sql
SELECT 0.1 + 0.2 AS result_float;  -- May return 0.30000000000004
SELECT CAST(0.1 AS NUMERIC) + CAST(0.2 AS NUMERIC);  -- Returns exact 0.3
```

**Comparison Summary:**

| Feature         | FLOAT / DOUBLE PRECISION | NUMERIC / DECIMAL       |
| --------------- | ------------------------ | ----------------------- |
| Precision       | Approximate (binary)     | Exact (fixed precision) |
| Performance     | Faster                   | Slower                  |
| Use Case        | Analytics, measurements  | Finance, accounting     |
| Rounding Errors | Possible                 | None                    |

**Rule of Thumb:**

> Use `NUMERIC` for accuracy, `FLOAT` for speed.

---

## 2. Character Data Types

PostgreSQL provides flexible options for text storage.

| Type           | Description                | Example                       |
| -------------- | -------------------------- | ----------------------------- |
| **CHAR(n)**    | Fixed-length string        | `CHAR(10)` → pads with spaces |
| **VARCHAR(n)** | Variable-length with limit | `VARCHAR(50)`                 |
| **TEXT**       | Unlimited variable-length  | No size restriction           |

**Example:**

```sql
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name TEXT,
    dept CHAR(10)
);

INSERT INTO employees VALUES (1, 'Binaya', 'Sharma', 'DATAENG');
```

**Notes:**

* `TEXT` and `VARCHAR` have identical performance.
* Use `TEXT` when no strict length constraint is required.

---

## 3. Date and Time Types

| Type                                       | Example                       | Description                      |
| ------------------------------------------ | ----------------------------- | -------------------------------- |
| **DATE**                                   | `'2025-10-28'`                | Calendar date only               |
| **TIME [WITHOUT TIME ZONE]**               | `'14:30:00'`                  | Time of day only                 |
| **TIMESTAMP [WITHOUT TIME ZONE]**          | `'2025-10-28 14:30:00'`       | Date + time                      |
| **TIMESTAMP WITH TIME ZONE (timestamptz)** | `'2025-10-28 14:30:00+05:45'` | Time zone-aware timestamp        |
| **INTERVAL**                               | `'5 days'`, `'2 hours'`       | Duration between two dates/times |

**Example:**

```sql
SELECT CURRENT_DATE;
SELECT CURRENT_TIMESTAMP;
SELECT CURRENT_TIMESTAMP - INTERVAL '7 days' AS one_week_ago;
```

**Date Function Examples:**

```sql
SELECT EXTRACT(YEAR FROM '2025-01-01'::DATE);
SELECT DATE_PART('month', '2025-01-01'::DATE);
SELECT AGE(CURRENT_DATE, '2000-01-01');
```

---

## 4. Boolean Type

| Type        | Example                 | Description             |
| ----------- | ----------------------- | ----------------------- |
| **BOOLEAN** | `TRUE`, `FALSE`, `NULL` | Logical true/false flag |

**Example:**

```sql
CREATE TABLE flags (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN
);

INSERT INTO flags VALUES (1, TRUE), (2, FALSE);
SELECT * FROM flags WHERE is_active = TRUE;
```

---

## 5. Miscellaneous and Advanced Types

| Type                   | Description                | Example                                    |
| ---------------------- | -------------------------- | ------------------------------------------ |
| **JSON / JSONB**       | Structured JSON storage    | `'{"name": "Binaya", "role": "Engineer"}'` |
| **ARRAY**              | Ordered list               | `ARRAY[1, 2, 3]`                           |
| **UUID**               | Unique identifier          | `'550e8400-e29b-41d4-a716-446655440000'`   |
| **BYTEA**              | Binary data (files, blobs) | Used for image/file storage                |
| **SERIAL / BIGSERIAL** | Auto-increment integer     | Commonly used for primary keys             |

**Example:**

```sql
CREATE TABLE projects (
    project_id UUID DEFAULT gen_random_uuid(),
    project_name TEXT,
    tags TEXT[],
    details JSONB
);

INSERT INTO projects (project_name, tags, details)
VALUES ('ETL Pipeline', ARRAY['Spark', 'Postgres'], '{"status": "active", "priority": "high"}');
```

---

## 6. Numeric Precision Summary

| Type     | Bytes    | Range                            |
| -------- | -------- | -------------------------------- |
| SMALLINT | 2        | -32,768 to 32,767                |
| INTEGER  | 4        | -2 billion to +2 billion         |
| BIGINT   | 8        | -9 quintillion to +9 quintillion |
| NUMERIC  | Variable | Defined by user                  |
| FLOAT8   | 8        | ~15 decimal digits precision     |

---

## 7. Real-World Usage Examples

### Example 1: Designing an Order Table with Proper Types

```sql
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_name TEXT NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    tax NUMERIC(6,2) DEFAULT 0.00,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_paid BOOLEAN DEFAULT FALSE
);
```

### Example 2: Using JSONB and Arrays

```sql
CREATE TABLE api_logs (
    log_id SERIAL PRIMARY KEY,
    request_details JSONB,
    response_codes INTEGER[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO api_logs (request_details, response_codes)
VALUES ('{"endpoint": "/login", "method": "POST"}', ARRAY[200, 201]);
```

---

## Key Takeaways

* **NUMERIC/DECIMAL** for exact values (billing, finance).
* **FLOAT/DOUBLE PRECISION** for performance (analytics, metrics).
* **TEXT** and **VARCHAR** perform equally well; use TEXT for flexibility.
* Always use **TIMESTAMP WITH TIME ZONE** for global data pipelines.
* **JSONB** is highly efficient for semi-structured data storage.

End of Document - PostgreSQL Data Types
