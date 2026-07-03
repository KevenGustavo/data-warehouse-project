/*
===============================================================================
Data Quality Checks - Gold Layer
===============================================================================
Script Purpose:
    This script contains quality assurance (QA) checks to validate the integrity
    of the Star Schema model, ensuring that surrogate keys are unique and 
    referential integrity is maintained between facts and dimensions.

    How to read the results:
    - If a query returns 0 rows: The test PASSED.
    - If a query returns > 0 rows: The test FAILED (Data anomalies detected).
===============================================================================
*/

use DataWarehouse;

-- ====================================================================
-- DIMENSION: gold.dim_customers
-- ====================================================================

-- QA CHECK 01: Surrogate Key Uniqueness
-- Ensures that the generated customer_key is absolutely unique.
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- QA CHECK 02: Business Key Uniqueness & Left Join Fan-out Prevention
-- Ensures that the original customer_id remains unique after the LEFT JOINs 
-- with ERP tables. If this fails, the ERP tables caused a Cartesian product.
SELECT customer_id, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- QA CHECK 03: Data Integration Validation
-- Ensures that the COALESCE logic between CRM and ERP correctly handled 
-- genders, leaving no NULLs behind.
SELECT customer_key, gender
FROM gold.dim_customers
WHERE gender IS NULL;


-- ====================================================================
-- DIMENSION: gold.dim_products
-- ====================================================================

-- QA CHECK 04: Surrogate Key Uniqueness
-- Ensures that the generated product_key is absolutely unique.
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- QA CHECK 05: Business Key Uniqueness & Left Join Fan-out Prevention
-- Ensures that the original product_number remains unique after the LEFT JOIN 
-- with the categories table, considering we filtered for active records only.
SELECT product_number, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


-- ====================================================================
-- FACT: gold.fact_sales
-- ====================================================================

-- QA CHECK 06: Referential Integrity (Lookup Failures)
-- This is the most critical check. It ensures that every sales record successfully
-- found a matching customer and product in the dimensions. 
-- If product_key or customer_key is NULL, it means the LEFT JOIN failed to match 
-- the business keys (sls_prd_key or sls_cust_id).
SELECT 
    order_number, 
    product_key, 
    customer_key
FROM gold.fact_sales
WHERE product_key IS NULL 
   OR customer_key IS NULL;

-- QA CHECK 07: Grain Validation (Duplicate Sales)
-- Ensure that an order_number combined with a product_key is unique. 
-- A single order shouldn't have the exact same product billed twice on separate lines 
-- (unless differentiated by an item_line_number, which this dataset doesn't have).
SELECT 
    order_number, 
    product_key, 
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY order_number, product_key
HAVING COUNT(*) > 1;