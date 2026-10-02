/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

IF OBJECT_ID('bronze.customers', 'U') IS NOT NULL
    DROP TABLE bronze.customers;
GO

CREATE TABLE bronze.customers (
    customer_id nvarchar(100),
    customer_unique_id nvarchar(100),
    customer_zip_code_prefix nvarchar(20),
    customer_city nvarchar(200),
    customer_state nvarchar(20)
);
GO

IF OBJECT_ID('bronze.orders', 'U') IS NOT NULL
    DROP TABLE bronze.orders;
GO

CREATE TABLE bronze.orders (
    order_id nvarchar(100),
    customer_id nvarchar(100), 
    order_status nvarchar(50),
    order_purchase_timestamp nvarchar(50),
    order_approved_at nvarchar(50),
    order_delivered_carrier_date nvarchar(50),
    order_delivered_customer_date nvarchar(50),
    order_estimated_delivery_date nvarchar(max)
);

GO

IF OBJECT_ID('bronze.order_items', 'U') IS NOT NULL
    DROP TABLE bronze.order_items;
GO

CREATE TABLE bronze.order_items (
    order_id nvarchar(100),
    order_item_id nvarchar(20), 
    product_id nvarchar(100),
    seller_id nvarchar(100),
    shipping_limit_date nvarchar(50),
    price nvarchar(50),
    freight_value nvarchar(100)
);
GO

IF OBJECT_ID('bronze.order_payments', 'U') IS NOT NULL
    DROP TABLE bronze.order_payments;
GO

CREATE TABLE bronze.order_payments (
    order_id nvarchar(100), 
    payment_sequential nvarchar(20),
    payment_type nvarchar(50),
    payment_installments nvarchar(20),
    payment_value nvarchar(max)
);
GO

IF OBJECT_ID('bronze.order_reviews', 'U') IS NOT NULL
    DROP TABLE bronze.order_reviews;
GO

CREATE TABLE bronze.order_reviews (
    review_id nvarchar(100),
    order_id nvarchar(100),
    review_score nvarchar(20),
    review_comment_title nvarchar(500), 
    review_comment_message nvarchar(max),
    review_creation_date nvarchar(50),
    review_answer_timestamp nvarchar(50)
);

GO

IF OBJECT_ID('bronze.products', 'U') IS NOT NULL
    DROP TABLE bronze.products;
GO

CREATE TABLE bronze.products (
    product_id nvarchar(100),
    product_category_name nvarchar(200),
    product_name_length nvarchar(20),
    product_description_length nvarchar(20),
    product_photos_qty nvarchar(20),
    product_weight_g nvarchar(20),
    product_length_cm nvarchar(20),
    product_height_cm nvarchar(20),
    product_width_cm nvarchar(max)
);

GO

IF OBJECT_ID('bronze.sellers', 'U') IS NOT NULL
    DROP TABLE bronze.sellers;
GO

CREATE TABLE bronze.sellers (
    seller_id nvarchar(100),
    seller_zip_code_prefix nvarchar(20),
    seller_city nvarchar(200),
    seller_state nvarchar(20)
);

GO

IF OBJECT_ID('bronze.category_translation', 'U') IS NOT NULL
    DROP TABLE bronze.category_translation;
GO

CREATE TABLE bronze.category_translation (
    product_category_name nvarchar(200),
    product_category_name_english nvarchar(200)
);
GO
