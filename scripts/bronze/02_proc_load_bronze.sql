/*
=============================================================
Create procedure to Load Data into Bronze Layer
=============================================================
Script Purpose:
    This script is designed to load data into the bronze layer of the DataWarehouse database.
    It performs the following operations:
    1. Truncates existing data in the bronze layer tables to ensure a clean slate.
    2. Loads data from CSV files into the corresponding bronze layer tables using the BULK  INSERT command.
*/

create or alter procedure bronze.load_bronze_data as
begin
    declare @start_time datetime, @proc_start_time datetime = SYSDATETIME();
    
    begin try
        print '=============================================================';
        print 'Loading data into bronze layer';
        print '=============================================================';

        print '-------------------------------------------------------------';
        print 'Loading CRM Tables';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.crm_cust_info';
        truncate table bronze.crm_cust_info;
        print '>> Loading Table: bronze.crm_cust_info';
        bulk insert bronze.crm_cust_info
        from '/datasets/source_crm/cust_info.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.crm_prd_info';
        truncate table bronze.crm_prd_info;
        print '>> Loading Table: bronze.crm_prd_info';
        bulk insert bronze.crm_prd_info
        from '/datasets/source_crm/prd_info.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.crm_sales_details';
        truncate table bronze.crm_sales_details;
        print '>> Loading Table: bronze.crm_sales_details';
        bulk insert bronze.crm_sales_details
        from '/datasets/source_crm/sales_details.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';

        print '-------------------------------------------------------------';
        print 'Loading ERP Tables';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.erp_cust_az12';
        truncate table bronze.erp_cust_az12;
        print '>> Loading Table: bronze.erp_cust_az12';
        bulk insert bronze.erp_cust_az12
        from '/datasets/source_erp/CUST_AZ12.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.erp_loc_a101';
        truncate table bronze.erp_loc_a101;
        print '>> Loading Table: bronze.erp_loc_a101';
        bulk insert bronze.erp_loc_a101
        from '/datasets/source_erp/LOC_A101.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        set @start_time = SYSDATETIME();
        print '>> Truncating Table: bronze.erp_px_cat_g1v2';
        truncate table bronze.erp_px_cat_g1v2;
        print '>> Loading Table: bronze.erp_px_cat_g1v2';
        bulk insert bronze.erp_px_cat_g1v2
        from '/datasets/source_erp/PX_CAT_G1V2.csv'
        with (
            format = 'csv',
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        print '>> Load duration: ' + cast(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '-------------------------------------------------------------';

        print '=============================================================';
        print 'Data loading completed successfully';
        print 'Duration: ' + cast(DATEDIFF(MILLISECOND, @proc_start_time, SYSDATETIME()) as varchar(20)) + ' ms';
        print '=============================================================';

    end try
    begin catch
        print '=============================================================';
        print 'Error occurred while loading data into bronze layer';
        print 'Error Number: ' + cast(error_number() as varchar(10));
        print 'Error Severity: ' + cast(error_severity() as varchar(10));
        print 'Error State: ' + cast(error_state() as varchar(10));
        print 'Error Message: ' + error_message();
        print '=============================================================';
    end catch
end;