/*
===============================================================================
DDL Script:       Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the Data Warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema).
    
    Each view performs transformations and combines data from the Silver layer 
    to produce clean, business-ready datasets for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- View: gold.dim_customers
-- Description: Creates a dimension table for customers.
--              Integrates customer data from CRM and ERP systems, handling 
--              missing data and mapping business keys to a single unified model.
-- =============================================================================

create or alter view gold.dim_customers as
select
    ROW_NUMBER() over(order by ci.cst_id) as customer_key,
    ci.cst_id as customer_id,
    ci.cst_key as customer_number,
    ci.cst_first_name as first_name,
    ci.cst_last_name as last_name,
    case when ci.cst_gndr != 'N/A' then ci.cst_gndr
        else coalesce(ca.gen, 'N/A')
    end as gender,
    ci.cst_marital_status as marital_status,
    ca.bdate as birthday,
    la.cntry as country,
    ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid
left join silver.erp_loc_a101 la on ci.cst_key = la.cid;
go

-- =============================================================================
-- View: gold.dim_products
-- Description: Creates a dimension table for products.
--              Integrates product categories from ERP into CRM product details.
--              Filters out historical records to present only the active catalog.
-- =============================================================================

create or alter view gold.dim_products as
select
    ROW_NUMBER() over (order by pi.prd_start_dt, pi.prd_id) as product_key,
    pi.prd_id as product_id,
    pi.prd_key as product_number,
    pi.prd_nm as product_name,
    pi.cat_id as category_id,
    pc.cat as category,
    pc.subcat as subcategory,
    pc.maintenance,
    pi.prd_cost as cost,
    pi.prd_line as product_line,
    pi.prd_start_dt as start_date
from silver.crm_prd_info pi
left join silver.erp_px_cat_g1v2 pc on pi.cat_id = pc.id
where prd_end_dt is null;
go

-- =============================================================================
-- View: gold.fact_sales
-- Description: Creates a fact table for sales transactions.
--              Translates business keys into surrogate keys for the Star Schema.
-- =============================================================================

create or alter view gold.fact_sales as
select
    sd.sls_ord_num as order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt as order_date,
    sd.sls_ship_dt as ship_date,
    sd.sls_due_dt as due_date,
    sd.sls_sales as sales_amount,
    sd.sls_quantity as quantity,
    sd.sls_price as price
from silver.crm_sales_details sd
left join gold.dim_products dp on sd.sls_prd_key = dp.product_number
left join gold.dim_customers dc on sd.sls_cust_id = dc.customer_id;