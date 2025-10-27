# PostgreSQL Advanced SQL Reference & Practice Guide

## Overview
This repository serves as a compact PostgreSQL practice and reference guide for data engineers.  
It covers essential SQL concepts used in ETL pipelines, data modeling, and analytics.

---

## Topics Covered

1. **Stored Procedures and Functions**  
   Demonstrates how to create reusable PL/pgSQL blocks for parameterized logic and automation.  
   Includes examples for basic procedures, functions, and differences between them.

2. **Deduplication (Data Cleaning)**  
   Explains how to remove duplicate records using window functions and ctid.  
   Shows the importance of uniqueness in staging and analytical layers.

3. **String and Date Manipulation**  
   Covers key string functions such as LEFT, RIGHT, SPLIT_PART, and LENGTH.  
   Includes date operations using EXTRACT, DATE_PART, and DATE_TRUNC for reporting needs.

4. **Self Join (Hierarchical Queries)**  
   Demonstrates self-joins to create employee–manager hierarchies.  
   Useful for modeling organizational or recursive relationships.

5. **Duplicate Explosion in Joins**  
   Highlights how missing keys or duplicate data in dimension tables can multiply records.  
   Emphasizes deduplication and key enforcement before joins.

6. **COUNT Logic**  
   Describes the difference between COUNT(*), COUNT(1), and COUNT(column).  
   Explains when to use each type for auditing or aggregation.

7. **Inline Views and EXISTS vs IN**  
   Shows how inline views simplify subqueries.  
   Discusses the performance benefits of EXISTS over IN for large datasets.

8. **UNION vs UNION ALL**  
   Explains the difference between duplicate elimination (UNION) and performance (UNION ALL).  
   Recommends when to use each based on data volume and requirements.

9. **MERGE (UPSERT)**  
   Introduces the MERGE command (PostgreSQL 15+).  
   Describes its use in performing insert/update operations atomically for incremental data loads.

10. **Analytical SQL and Window Functions**  
    Covers ranking, aggregation, and cumulative analytics using window functions.  
    Explains SQL execution order and placement of window functions in queries.

11. **Query Plans and Indexing**  
    Describes how EXPLAIN and EXPLAIN ANALYZE work for query optimization.  
    Discusses how indexing improves performance by reducing full table scans.

---

## Best Practices

- Deduplicate data before joining large datasets.  
- Use WITH (CTE) clauses to simplify complex queries.  
- Prefer EXISTS and NOT EXISTS over IN for performance.  
- Use EXPLAIN ANALYZE to verify index usage and execution paths.  
- Choose UNION ALL unless duplicates must be eliminated.  
- Avoid unnecessary subqueries when window functions can achieve the same result.  

---

## SQL Logical Execution Order
FROM → WHERE → GROUP BY → HAVING → WINDOW → SELECT → DISTINCT → ORDER BY → LIMIT

---

## Repository Structure
postgresql-advanced-sql-reference/

├── PostgreSQL_Advanced_SQL_Practice.sql   # Complete SQL examples

├── Postgres_Advanced_SQL_Reference.md

└── README.md                              # Description and reference

