/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema, cleansing and standardizing raw data from 
    the 'bronze' schema.

    Transformations Applied:
    - Data Cleansing: Trimming whitespace, removing carriage returns.
    - Data Standardization: Mapping coded values to descriptive names.
    - Deduplication: Keeping the most recent record using window functions.
    - Handling Missing/Invalid Data: Coalescing NULLs, recalculating metrics.
    - Slowly Changing Dimensions (SCD): Calculating end dates for history tracking.
===============================================================================
*/

create or alter procedure silver.load_silver_data as
begin    
    declare @start_time datetime, @proc_start_time datetime = SYSDATETIME();
    
    begin try
        print '=============================================================';
        print 'Loading data into silver layer';
        print '=============================================================';

        print '-------------------------------------------------------------';
        print 'Loading CRM Tables';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.crm_cust_info';
        truncate table silver.crm_cust_info;
        print '>> Loading Table: silver.crm_cust_info';
        insert into silver.crm_cust_info(
            cst_id,
            cst_key,
            cst_first_name,
            cst_last_name,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        select 
            cst_id,
            cst_key,
            trim(cst_first_name) as cst_first_name,
            trim(cst_last_name) as cst_last_name,
            case
                when upper(trim(cst_marital_status)) = 'M' then 'Married'
                when upper(trim(cst_marital_status)) = 'S' then 'Single'
                else 'N/A'
            end as cst_marital_status,
            case
                when upper(trim(cst_gndr)) = 'M' then 'Male'
                when upper(trim(cst_gndr)) = 'F' then 'Female'
                else 'N/A'
            end as cst_gndr,
            cst_create_date
        from(
            select 
                *, 
                row_number() over (partition by cst_id order by cst_create_date desc) as flag_older
            from bronze.crm_cust_info
            where cst_id is not null
        ) as rknd_cust_info 
        where flag_older = 1;

        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.crm_prd_info';
        truncate table silver.crm_prd_info;
        print '>> Loading Table: silver.crm_prd_info';
        insert into silver.crm_prd_info(
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        select 
            prd_id,
            replace(substring(prd_key, 1, 5),'-','_' ) as cat_id,
            substring(prd_key, 7, len(prd_key)) as prd_key,
            prd_nm,
            isnull(prd_cost, 0) as prd_cost,
            case
                when prd_line = 'M' then 'Mountain'
                when prd_line = 'R' then 'Road'
                when prd_line = 'T' then 'Touring'
                when prd_line = 'S' then 'Other Sales'
                else 'N/A'
            end as prd_line,
            prd_start_dt,
            dateadd(day, -1, LEAD(prd_start_dt) over(partition by prd_key order by prd_start_dt asc)) as prd_end_dt
        from bronze.crm_prd_info;

        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.crm_sales_details';
        truncate table silver.crm_sales_details;
        print '>> Loading Table: silver.crm_sales_details';
        insert into silver.crm_sales_details(
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        select
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            case
                when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
                else cast(cast(sls_order_dt as varchar(8)) as date)
            end as sls_order_dt,
            case
                when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
                else cast(cast(sls_ship_dt as varchar(8)) as date)
            end as sls_ship_dt,
            case
                when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
                else cast(cast(sls_due_dt as varchar(8)) as date)
            end as sls_due_dt,
            case
                when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price) 
                    then sls_quantity * ABS(sls_price)
                else sls_sales
            end as sls_sales,
            sls_quantity,
            case
                when sls_price is null or sls_price <= 0 
                    then sls_sales / nullif(sls_quantity, 0)
                else sls_price
            end as sls_price
        from bronze.crm_sales_details;

        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';
        print 'Loading ERP Tables';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.erp_cust_az12';
        truncate table silver.erp_cust_az12;
        print '>> Loading Table: silver.erp_cust_az12';
        insert into silver.erp_cust_az12(
            cid,
            bdate,
            gen
        )
        select 
            case when cid like 'NAS%' then substring(cid,4, len(cid))
                else cid
            end as cid,
            case when bdate > getdate() then null
                else bdate
            end as bdate,
            case when upper(trim(REPLACE(gen, CHAR(13), ''))) in ('F', 'FEMALE') then 'Female'
                when upper(trim(REPLACE(gen, CHAR(13), ''))) in ('M', 'MALE') then 'Male'
                else 'N/A'
            end as gen
        from bronze.erp_cust_az12;

        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.erp_loc_a101';
        truncate table silver.erp_loc_a101;
        print '>> Loading Table: silver.erp_loc_a101';
        insert into silver.erp_loc_a101(
            cid,
            cntry
        )
        select 
            replace(cid,'-','') as cid,
            case when upper(trim(replace(cntry,char(13),''))) in ('USA','US') then 'United States'
                when upper(trim(replace(cntry,char(13),''))) = 'DE' then 'Germany'
                when trim(replace(cntry,char(13),'')) in ('',null) then 'N/A'
                else replace(cntry,char(13),'') 
            end as cntry
        from bronze.erp_loc_a101;
        
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: silver.erp_px_cat_g1v2';
        truncate table silver.erp_px_cat_g1v2;
        print '>> Loading Table: silver.erp_px_cat_g1v2';
        insert into silver.erp_px_cat_g1v2(
            id,
            cat,
            subcat,
            maintenance
        )
        select 
            id,
            cat,
            subcat,
            replace(maintenance, char(13), '') as maintenance
        from bronze.erp_px_cat_g1v2;

        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        print '=============================================================';
        print 'Data loading completed successfully';
        print 'Duration: ' + cast(DATEDIFF(MILLISECOND, @proc_start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '=============================================================';
    end try
    begin catch
        print '=============================================================';
        print 'Error occurred while loading data into silver layer';
        print 'Error Number: ' + cast(error_number() as varchar(10));
        print 'Error Severity: ' + cast(error_severity() as varchar(10));
        print 'Error State: ' + cast(error_state() as varchar(10));
        print 'Error Message: ' + error_message();
        print '=============================================================';
    end catch
end