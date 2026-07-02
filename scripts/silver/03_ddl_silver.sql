/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables if they already exist.
	Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/

use DataWarehouse;

-- create silver crm tables

if object_id('silver.crm_cust_info') is not null
    drop table silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info(
    cst_id int,
    cst_key nvarchar(50),
    cst_first_name nvarchar(50),
    cst_last_name nvarchar(50),
    cst_marital_status nvarchar(50),
    cst_gndr nvarchar(50),
    cst_create_date date,
    dwh_create_date date default getdate(),
);

if object_id('silver.crm_prd_info') is not null
    drop table silver.crm_prd_info;
create table silver.crm_prd_info(
    prd_id int,
    prd_key nvarchar(50),
    prd_nm nvarchar(50),
    prd_cost int,
    prd_line nvarchar(50),
    prd_start_dt date,
    prd_end_dt date,
    dwh_create_date date default getdate(),
);

if object_id('silver.crm_sales_details') is not null
    drop table silver.crm_sales_details;
create table silver.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id int,
    sls_order_dt int,
    sls_ship_dt int,
    sls_due_dt int,
    sls_sales int,
    sls_quantity int,
    sls_price int,
    dwh_create_date date default getdate(),
);

--create silver erp tables

if object_id('silver.erp_cust_az12') is not null
    drop table silver.erp_cust_az12;
create table silver.erp_cust_az12(
    cid nvarchar(50),
    bdate date,
    gen nvarchar(50),
    dwh_create_date date default getdate(),
);

if object_id('silver.erp_loc_a101') is not null
    drop table silver.erp_loc_a101;
create table silver.erp_loc_a101(
    cid nvarchar(50),
    cntry nvarchar(50),
    dwh_create_date date default getdate(),
);

if object_id('silver.erp_px_cat_g1v2') is not null
    drop table silver.erp_px_cat_g1v2;
create table silver.erp_px_cat_g1v2(
    id nvarchar(50),
    cat nvarchar(50),
    subcat nvarchar(50),
    maintenance nvarchar(50),
    dwh_create_date date default getdate()
);  