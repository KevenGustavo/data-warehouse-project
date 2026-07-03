/*
===============================================================================
Data Quality Checks - Silver Layer
===============================================================================
Script Purpose:
    This script contains quality assurance (QA) checks to validate the integrity,
    consistency, and standardization of the data within the Silver Layer.

    How to read the results:
    - If a query returns 0 rows: The test PASSED.
    - If a query returns > 0 rows: The test FAILED (Data anomalies detected).
===============================================================================
*/

use DataWarehouse;

-- ====================================================================
-- TABLE: silver.crm_cust_info
-- ====================================================================

-- QA CHECK 01: Check for duplicates in Primary Key
-- The ETL script uses ROW_NUMBER() to pick the latest record.
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- QA CHECK 02: Check for unwanted spaces
-- The ETL script uses TRIM() on names.
SELECT cst_first_name, cst_last_name
FROM silver.crm_cust_info
WHERE cst_first_name != TRIM(cst_first_name)
   OR cst_last_name != TRIM(cst_last_name);

-- QA CHECK 03: Check Data Standardization for Marital Status and Gender
-- The ETL script maps genders to 'Male', 'Female', 'N/A' and statuses to 'Married', 'Single', 'N/A'.
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Married', 'Single', 'N/A');

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'N/A');

-- ====================================================================
-- TABLE: silver.crm_prd_info
-- ====================================================================

-- QA CHECK 04: Check for NULL Costs
-- The ETL script replaces NULL costs with 0.
SELECT prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL;

-- QA CHECK 05: Check Product Line Standardization
-- The ETL script maps lines to 'Mountain', 'Road', 'Touring', 'Other Sales', 'N/A'.
SELECT DISTINCT prd_line
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Touring', 'Other Sales', 'N/A');

-- QA CHECK 06: Check Date Overlaps (Slowly Changing Dimensions)
-- The ETL script calculates end dates using LEAD(start_date) - 1. End dates should not be older than start dates.
SELECT prd_id, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- ====================================================================
-- TABLE: silver.crm_sales_details
-- ====================================================================

-- QA CHECK 07: Validate Sales Math and Negative Values
-- The ETL script recalculates sales if they are <= 0 or mismatched with qty * abs(price).
-- It also fixes prices if they are <= 0 or NULL.
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * ABS(sls_price)
   OR sls_sales IS NULL 
   OR sls_sales <= 0
   OR sls_price IS NULL 
   OR sls_price <= 0;

-- QA CHECK 08: Validate Date Logical Order
-- An order date cannot happen after a shipping date or a due date.
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- ====================================================================
-- TABLE: silver.erp_cust_az12
-- ====================================================================

-- QA CHECK 09: Check Invalid CID Prefixes
-- The ETL script removes the 'NAS' prefix from customer IDs.
SELECT cid
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- QA CHECK 10: Check Future Birthdates
-- The ETL script maps birthdates in the future to NULL.
SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- QA CHECK 11: Check Gender Standardization
-- The ETL script cleans carriage returns and maps genders to 'Male', 'Female', 'N/A'.
SELECT DISTINCT gen
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'N/A');

-- ====================================================================
-- TABLE: silver.erp_loc_a101
-- ====================================================================

-- QA CHECK 12: Check CID format
-- The ETL script removes hyphens ('-') from the customer ID.
SELECT cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- QA CHECK 13: Check Country Standardization
-- The ETL script maps 'USA'/'US' to 'United States' and 'DE' to 'Germany'.
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
WHERE cntry IN ('USA', 'US', 'DE', '') 
   OR cntry IS NULL;

-- ====================================================================
-- TABLE: silver.erp_px_cat_g1v2
-- ====================================================================

-- QA CHECK 14: Check Carriage Return cleanup
-- The ETL script removes carriage returns (CHAR 13) from the maintenance column.
SELECT maintenance
FROM silver.erp_px_cat_g1v2
WHERE maintenance LIKE '%' + CHAR(13) + '%';