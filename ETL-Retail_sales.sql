CREATE DATABASE RetailETL;
GO

USE RetailETL;
GO
SELECT TOP 10 * FROM retail_sales_dataset;
SELECT COUNT(*) FROM retail_sales_dataset;
/*check for null value */
SELECT *
FROM retail_sales_dataset
WHERE transaction_id IS NULL
   OR Date IS NULL
   OR customer_id IS NULL;
/*checks for duplicates*/
SELECT transaction_id, COUNT(*) AS duplicate_count
FROM retail_sales_dataset
GROUP BY transaction_id
HAVING COUNT(*) > 1

/*Create Data Warehouse Structure to give us a star schema 
We will build:The smaller tables called dimension table that surround the fact table(main table from the dataset) 
dim_customer
dim_product
dim_date
fact_sales*/

/*I designed a star schema in SQL Server, created dimension tables for customers, products, 
and dates, and loaded a fact table using surrogate keys and foreign key relationships.*/
CREATE TABLE dim_customer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id NVARCHAR(50),
    gender NVARCHAR(50),
    age INT
);

INSERT INTO dim_customer (customer_id, gender, age)
SELECT DISTINCT
    Customer_ID,
    Gender,
    Age
FROM retail_sales_dataset;

CREATE TABLE dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_category NVARCHAR(100)
);
INSERT INTO dim_product (product_category)
SELECT DISTINCT Product_Category
FROM retail_sales_dataset;


CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    day INT
);
INSERT INTO dim_date (date_key, full_date, year, month, day)
SELECT DISTINCT
    CONVERT(INT, FORMAT(Date, 'yyyyMMdd')) AS date_key,
    Date,
    YEAR(Date),
    MONTH(Date),
    DAY(Date)
FROM retail_sales_dataset;

CREATE TABLE fact_sales (
    sales_key INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id SMALLINT,
    customer_key INT,
    product_key INT,
    date_key INT,
    quantity INT,
    price_per_unit SMALLINT,
    total_amount SMALLINT,
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
INSERT INTO fact_sales (
    transaction_id,
    customer_key,
    product_key,
    date_key,
    quantity,
    price_per_unit,
    total_amount
)
SELECT
    r.Transaction_ID,
    c.customer_key,
    p.product_key,
    CONVERT(INT, FORMAT(r.Date, 'yyyyMMdd')) AS date_key,
    r.Quantity,
    r.Price_Per_Unit,
    r.Total_Amount
FROM retail_sales_dataset r
JOIN dim_customer c
    ON r.Customer_ID = c.customer_id
JOIN dim_product p
    ON r.Product_Category = p.product_category;

-- Top selling products
SELECT p.product_category, SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_category
ORDER BY revenue DESC;

-- Monthly revenue
SELECT d.year, d.month, SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

--monthly sales trend --
SELECT d.year, d.month, SUM(f.total_amount) AS monthly_revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

--average sale per transaction --
SELECT AVG(total_amount) AS avg_transaction_value
FROM fact_sales;
---sales by gender--
SELECT c.gender, SUM(f.total_amount) AS total_revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.gender;
--Quantity Sold by Product Category--
SELECT p.product_category, SUM(f.quantity) AS total_quantity
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_category
ORDER BY total_quantity DESC;



