/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Purpose:
    Defines the silver tables with proper data types. Bronze stores everything
    as text; silver converts to dates, integers and decimals.
    Run this script to re-create the silver structure.
===============================================================================
*/

IF OBJECT_ID('silver.customers', 'U') IS NOT NULL DROP TABLE silver.customers;
GO
CREATE TABLE silver.customers (
    customer_id              nvarchar(100) NOT NULL,
    customer_unique_id       nvarchar(100) NOT NULL,
    customer_zip_code_prefix nvarchar(20),
    customer_city            nvarchar(200),
    customer_state           nvarchar(2),
    dwh_create_date          datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.orders', 'U') IS NOT NULL DROP TABLE silver.orders;
GO
CREATE TABLE silver.orders (
    order_id                      nvarchar(100) NOT NULL,
    customer_id                   nvarchar(100) NOT NULL,
    order_status                  nvarchar(50),
    order_purchase_timestamp      datetime2,
    order_approved_at             datetime2,
    order_delivered_carrier_date  datetime2,
    order_delivered_customer_date datetime2,
    order_estimated_delivery_date datetime2,
    delivery_days                 int,   -- purchase to delivery, NULL if not delivered
    days_vs_estimate              int,   -- positive = delivered late
    is_late                       bit,
    dwh_create_date               datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.order_items', 'U') IS NOT NULL DROP TABLE silver.order_items;
GO
CREATE TABLE silver.order_items (
    order_id            nvarchar(100) NOT NULL,
    order_item_id       int NOT NULL,
    product_id          nvarchar(100),
    seller_id           nvarchar(100),
    shipping_limit_date datetime2,
    price               decimal(10,2),
    freight_value       decimal(10,2),
    dwh_create_date     datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.order_payments', 'U') IS NOT NULL DROP TABLE silver.order_payments;
GO
CREATE TABLE silver.order_payments (
    order_id             nvarchar(100) NOT NULL,
    payment_sequential   int,
    payment_type         nvarchar(50),
    payment_installments int,
    payment_value        decimal(10,2),
    dwh_create_date      datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.order_reviews', 'U') IS NOT NULL DROP TABLE silver.order_reviews;
GO
CREATE TABLE silver.order_reviews (
    review_id               nvarchar(100),
    order_id                nvarchar(100) NOT NULL,
    review_score            tinyint,
    review_comment_title    nvarchar(500),
    review_comment_message  nvarchar(max),
    review_creation_date    datetime2,
    review_answer_timestamp datetime2,
    dwh_create_date         datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.products', 'U') IS NOT NULL DROP TABLE silver.products;
GO
CREATE TABLE silver.products (
    product_id                 nvarchar(100) NOT NULL,
    product_category_name      nvarchar(200),
    product_name_length        int,
    product_description_length int,
    product_photos_qty         int,
    product_weight_g           int,
    product_length_cm          int,
    product_height_cm          int,
    product_width_cm           int,
    dwh_create_date            datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.sellers', 'U') IS NOT NULL DROP TABLE silver.sellers;
GO
CREATE TABLE silver.sellers (
    seller_id              nvarchar(100) NOT NULL,
    seller_zip_code_prefix nvarchar(20),
    seller_city            nvarchar(200),
    seller_state           nvarchar(2),
    dwh_create_date        datetime2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.category_translation', 'U') IS NOT NULL DROP TABLE silver.category_translation;
GO
CREATE TABLE silver.category_translation (
    product_category_name         nvarchar(200),
    product_category_name_english nvarchar(200),
    dwh_create_date               datetime2 DEFAULT GETDATE()
);
GO
