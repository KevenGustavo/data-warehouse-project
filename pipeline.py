"""
===============================================================================
Data Warehouse Orchestration Pipeline
===============================================================================
Script Purpose:
    This Python script acts as the minimal orchestrator for the Data Warehouse.
    It triggers the ETL stored procedures in the correct sequential order.
    
    Best Practices Applied:
    - Secrets Management via .env variables.
    - Standardized logging using Python's built-in 'logging' module.
===============================================================================
"""

import os
import sys
import time
import logging
import pyodbc
from dotenv import load_dotenv

# ---------------------------------------------------------
# 1. Setup Logging Configuration
# ---------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# ---------------------------------------------------------
# 2. Load Environment Variables
# ---------------------------------------------------------
load_dotenv()

DB_SERVER = os.getenv("DB_SERVER", "localhost,1433")
DB_NAME = os.getenv("DB_NAME", "DataWarehouse")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("MSSQL_SA_PASSWORD")

if not DB_PASSWORD:
    logging.error("CRITICAL: Database password not found. Please check your .env file.")
    sys.exit(1)

CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={DB_SERVER};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USER};"
    f"PWD={DB_PASSWORD};"
)

# ---------------------------------------------------------
# 3. Orchestration Functions
# ---------------------------------------------------------

def execute_procedure(cursor, proc_name):
    """Executes a stored procedure and logs its internal SQL print messages."""
    logging.info(f"Starting execution: {proc_name}...")
    start_time = time.time()
    
    try:
        # Execute the procedure
        cursor.execute(f"EXEC {proc_name}")
        
        # Capture and format internal SQL Server PRINT statements
        while True:
            if hasattr(cursor, 'messages') and cursor.messages:
                for msg in cursor.messages:
                    # The message is usually a tuple; the actual text is the second element
                    sql_print = msg[1] if len(msg) > 1 else msg[0]
                    # Log the SQL output with a specific tag for easy reading
                    logging.info(f"[SQL] {sql_print}")
                cursor.messages.clear() # Clear buffer after reading
            
            if not cursor.nextset():
                break
                
        elapsed_time = time.time() - start_time
        logging.info(f"SUCCESS: {proc_name} completed in {elapsed_time:.2f} seconds.")
        
    except pyodbc.Error as e:
        logging.error(f"FAILED: Procedure {proc_name} encountered an error.")
        logging.error(f"Error Details: {e}")
        sys.exit(1)

def run_pipeline():
    logging.info("==========================================================")
    logging.info("Starting Data Warehouse ETL Pipeline")
    logging.info("==========================================================")
    
    try:
        # Establish database connection
        logging.info("Connecting to the database...")
        conn = pyodbc.connect(CONN_STR, autocommit=True)
        cursor = conn.cursor()
        logging.info("Connection established.")
        
        # STEP 1: Load Bronze Layer
        execute_procedure(cursor, "bronze.load_bronze_data")
        
        # STEP 2: Load Silver Layer
        execute_procedure(cursor, "silver.load_silver_data")
        
        logging.info("==========================================================")
        logging.info("Pipeline executed successfully! Data is ready.")
        logging.info("==========================================================")
        
    except Exception as ex:
        logging.error(f"CRITICAL: Pipeline failed to start: {ex}")
    finally:
        # Ensure connection is cleanly closed
        if 'conn' in locals() and conn:
            conn.close()
            logging.info("Database connection closed.")

if __name__ == "__main__":
    run_pipeline()