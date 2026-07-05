# **SQL Data Warehouse: Medallion Architecture**

Welcome to the **SQL Data Warehouse Project**. This repository demonstrates a production-ready Data Engineering pipeline, building a complete Data Warehouse from scratch using **SQL Server**, **Docker**, and **Python**.

## **Project Overview**

The primary objective of this project is to integrate raw, disjointed data from two distinct source systems (CRM and ERP) into a centralized, analytics-ready **Star Schema**. It strictly follows the **Medallion Architecture** to guarantee data quality, traceability, and business-value generation.

## **Tech Stack**

* **Database Engine:** Microsoft SQL Server 2022 (Dockerized)  
* **Orchestration:** Python (pyodbc, python-dotenv, logging)  
* **Architecture:** Medallion (Bronze ➔ Silver ➔ Gold)  
* **Data Modeling:** Star Schema (Kimball Methodology)  
* **Infrastructure:** Docker & Docker Compose

## **Pipeline Architecture & Layers**

The ETL pipeline is executed through a Python orchestrator (pipeline.py) that triggers robust SQL Stored Procedures and DDLs separated by logical layers:

### **Bronze Layer (Raw Data)**

* **Goal:** Extract and Load (EL).  
* **Process:** Connects directly to the Docker volume and ingests raw .csv files using high-performance BULK INSERT.  
* **State:** Immutable. Data is kept exactly as it arrived from the source for auditing purposes.

### **Silver Layer (Cleansing & Standardization)**

* **Goal:** Data Quality and Transformations.  
* **Process:**  
  * **Deduplication:** Uses Window Functions (ROW\_NUMBER()) to keep the latest records.  
  * **SCD Type 2:** Calculates timeline boundaries (start\_date, end\_date) using LEAD().  
  * **Cleansing:** Trims whitespaces, resolves hidden carriage returns, and maps coded values (e.g., 'M' ➔ 'Male').  
  * **Error Handling:** Coalesces NULLs and dynamically recalculates invalid monetary metrics.

### **Gold Layer (Analytics & Business Value)**

* **Goal:** Business-ready Data Modeling.  
* **Process:** Creates a **Star Schema** with one Fact table (fact\_sales) and two Dimensions (dim\_customers, dim\_products).  
* **State:** Highly optimized Views relying on generated **Surrogate Keys** instead of source business keys to ensure referential integrity.

## **Data Quality & Testing**

Data reliability is treated as a first-class citizen. The tests/ directory contains SQL scripts acting as quality gates, actively checking for:

* **Left-Join Fan-outs:** Ensuring Cartesian products didn't multiply rows.  
* **Failed Lookups:** Validating 100% referential integrity between Facts and Dimensions.  
* **Surrogate Key Uniqueness:** Proving that analytical keys are absolute and not duplicated.

## **Repository Structure**

* **datasets/** ➔ Raw .csv files acting as CRM and ERP source systems.  
* **docs/** ➔ Architecture diagrams and logical data models.  
* **scripts/** ➔ SQL Scripts divided logically by deployment and ETL operations.  
* **tests/** ➔ QA scripts validating data integrity.  
* **docker-compose.yml** ➔ Local infrastructure setup.  
* **pipeline.py** ➔ Python orchestrator.

## **How to Run Locally**

**1\. Clone the repository**

```Bash  
git clone https://github.com/KevenGustavo/data-warehouse-project.git  
cd data-warehouse-project
```

**2\. Spin up the infrastructure**  
Starts the SQL Server instance and maps the local datasets/ folder to the container.

```Bash  
docker-compose up \-d
```

**3\. Set up credentials**  
Rename **.env.example** to **.env** and fill in the database password defined in your docker-compose file.

**4\. Initialize the Database (One-time Setup)**  
Execute the scripts in **scripts/** to create the database, schemas, tables, and views. You can use Azure Data Studio, VS Code, or DBeaver.  

**5\. Install System Prerequisites**  
The Python orchestrator uses pyodbc to connect to the database. You must install the **ODBC Driver 17 for SQL Server** on your local operating system before running the pipeline.

**6\. Run the ETL Pipeline**  
Install the Python driver and execute the orchestrator to process the data from Bronze to Silver.

```Bash  
pip install \-r requirements.txt  
python pipeline.py
```

## **👨‍💻 Author**

### **Keven Gomes**

[Connect with me on LinkedIn](https://www.linkedin.com/in/keven-gomes/)
