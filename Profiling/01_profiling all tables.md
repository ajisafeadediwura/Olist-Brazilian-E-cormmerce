/*
===============================================================================
Script:   sql/profiling/01_profile_all_tables.sql
Purpose:  Profile every bronze table before cleaning. Findings feed the silver
          cleaning rules.
Database: OlistAnalytics (SQL Server)
Note:     Read-only. Bronze columns are text, so numeric and date checks use
          TRY_CAST. Blank values are tested as NULL or empty string.
===============================================================================
*/

USE OlistAnalytics;
GO

/*
===============================================================================
1. bronze.customers
===============================================================================
*/

-- 1.1 Grain: customer_id vs customer_unique_id
SELECT COUNT(*)                           AS total_rows,
       COUNT(DISTINCT customer_id)        AS distinct_customer_id,
       COUNT(DISTINCT customer_unique_id) AS distinct_unique_ids
FROM bronze.customers;
-- Result: total_rows = 99441, distinct_customer_id = 99441, distinct_unique_ids = 96096
-- Finding:  customer_id is generated per order; customer_unique_id identifies the person.
-- Decision: Use customer_unique_id for all customer-level metrics.

-- 1.2 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.customers
WHERE customer_state LIKE '%' + CHAR(13) + '%';
-- Result:   0

-- 1.3 State codes
SELECT customer_state, LEN(customer_state) AS length, COUNT(*) AS customers
FROM bronze.customers
GROUP BY customer_state
ORDER BY customers DESC;
-- Result:   27 distinct values, all 2 characters

-- 1.4 City consistency
SELECT COUNT(DISTINCT customer_city)              AS raw_cities,
       COUNT(DISTINCT LOWER(TRIM(customer_city))) AS cleaned_cities
FROM bronze.customers;
-- Result:   counts equal; no spacing or case variants


/*
===============================================================================
2. bronze.sellers
===============================================================================
*/

-- 2.1 Grain
SELECT COUNT(*) AS total_rows, 
COUNT(DISTINCT seller_id) AS distinct_sellers
FROM bronze.sellers;
-- Result: <total_rows> rows | <distinct_sellers> seller_id (equals)

-- 2.2 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.sellers
WHERE seller_state LIKE '%' + CHAR(13) + '%';
-- Result: 0

-- 2.3 State codes
SELECT seller_state, LEN(seller_state) AS length, COUNT(*) AS sellers
FROM bronze.sellers
GROUP BY seller_state
ORDER BY sellers DESC;
-- Result: (lengthy, run the code to see)

-- 2.4 City consistency
SELECT COUNT(DISTINCT seller_city)              AS raw_cities,
       COUNT(DISTINCT LOWER(TRIM(seller_city))) AS cleaned_cities
FROM bronze.sellers;
-- Result: <raw_cities> Distinct seller_city | <Cleaned_cities> seller_city (equal)

-- 2.5 Zip prefix lengths
SELECT LEN(seller_zip_code_prefix) AS length, 
COUNT(*) AS sellers
FROM bronze.sellers
GROUP BY LEN(seller_zip_code_prefix)
ORDER BY length;
-- Result: length = 5, sellers = 3095


/*
===============================================================================
3. bronze.orders
===============================================================================
*/

-- 3.1 Grain: one row per order_id
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT order_id) AS distinct_orders
FROM bronze.orders;
-- Result:  <total_rows> rows | <distinct_orders> distinct order_id (equal) 
-- Finding:  order_id is unique. The table has one row per order, with no duplicates.
-- Decision: Use order_id as the primary key of silver.orders. No deduplication needed.

-- 3.2 Order status distribution
SELECT order_status, COUNT(*) AS orders
FROM bronze.orders
GROUP BY order_status
ORDER BY orders DESC;
-- Result: (lengthy, run the code to see)
-- Decision:Keep every order in silver and standardise order_status (trim,
--           lower case). Revenue, delivery, and review analysis use delivered
--           orders only, applied as an explicit filter in the analysis layer.

-- 3.3 Date conversion failures (non-blank text that does not convert to a date)
SELECT
    SUM(CASE WHEN TRIM(order_purchase_timestamp) <> ''
              AND TRY_CAST(order_purchase_timestamp AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_purchase,
    SUM(CASE WHEN TRIM(order_approved_at) <> ''
              AND TRY_CAST(order_approved_at AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_approved,
    SUM(CASE WHEN TRIM(order_delivered_carrier_date) <> ''
              AND TRY_CAST(order_delivered_carrier_date AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_carrier,
    SUM(CASE WHEN TRIM(order_delivered_customer_date) <> ''
              AND TRY_CAST(order_delivered_customer_date AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_delivered,
    SUM(CASE WHEN TRIM(REPLACE(order_estimated_delivery_date, CHAR(13), '')) <> ''
              AND TRY_CAST(REPLACE(order_estimated_delivery_date, CHAR(13), '') AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_estimated
FROM bronze.orders;
-- Result: 0

-- 3.4 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.orders
WHERE order_estimated_delivery_date LIKE '%' + CHAR(13) + '%';
-- Result: 0

-- 3.5 Date range and monthly volume (thin edge months)
SELECT FORMAT(TRY_CAST(order_purchase_timestamp AS datetime2), 'yyyy-MM') AS purchase_month,
       COUNT(*) AS orders
FROM bronze.orders
GROUP BY FORMAT(TRY_CAST(order_purchase_timestamp AS datetime2), 'yyyy-MM')
ORDER BY purchase_month;
-- Result: (lengthy, run the code to see)
-- Decision:  (analysis scope: first and last month with reliable volume)

-- 3.6 Missing delivery date by status
SELECT order_status,
       COUNT(*) AS total_order,
       SUM(CASE WHEN order_delivered_customer_date IS NULL
                  OR TRIM(order_delivered_customer_date) = '' THEN 1 ELSE 0 END) AS missing_delivery_date
FROM bronze.orders
GROUP BY order_status
ORDER BY total_order DESC;
-- Result:   delivered: 0 missing delivery dates. Missing dates occur only in
--           non-delivered statuses (<list the statuses and counts>).
-- Decision: Keep the NULLs in silver. delivery_days and is_late are NULL when
--           the delivery date is missing. No rows removed.

-- 3.7 Illogical date order (delivered before purchase)
SELECT COUNT(*) AS delivered_before_purchase
FROM bronze.orders
WHERE TRY_CAST(order_delivered_customer_date AS datetime2) < TRY_CAST(order_purchase_timestamp AS datetime2);
-- Result:   0 orders delivered before purchase.
-- Finding:  Delivery timestamps are never earlier than purchase timestamps.
-- Decision: No correction needed. delivery_days will not be negative.

-- 3.8 Orders without a matching customer
SELECT COUNT(*) AS orders_without_customer
FROM bronze.orders o
WHERE NOT EXISTS (SELECT 1 FROM bronze.customers c WHERE c.customer_id = o.customer_id);
-- Result:   0 orders without a matching customer.
-- Finding:  Every order links to a customer record.
-- Decision: No orphan handling needed. silver.orders.customer_id can safely
--           join to silver.customers.

-- 3.9 Orders without any items
SELECT COUNT(*) AS orders_without_items
FROM bronze.orders o
WHERE NOT EXISTS (SELECT 1 FROM bronze.order_items i WHERE i.order_id = o.order_id);
-- Result:
-- Decision:


/*
===============================================================================
4. bronze.order_items
===============================================================================
*/

-- 4.1 Grain: one row per order_id + order_item_id
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS distinct_keys
FROM bronze.order_items;
-- Result:

-- 4.2 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.order_items
WHERE freight_value LIKE '%' + CHAR(13) + '%';
-- Result:

-- 4.3 Numeric conversion failures
SELECT
    SUM(CASE WHEN TRIM(price) <> '' AND TRY_CAST(price AS decimal(10,2)) IS NULL THEN 1 ELSE 0 END) AS bad_price,
    SUM(CASE WHEN TRIM(REPLACE(freight_value, CHAR(13), '')) <> ''
              AND TRY_CAST(REPLACE(freight_value, CHAR(13), '') AS decimal(10,2)) IS NULL THEN 1 ELSE 0 END) AS bad_freight,
    SUM(CASE WHEN TRY_CAST(order_item_id AS int) IS NULL THEN 1 ELSE 0 END) AS bad_item_id
FROM bronze.order_items;
-- Result:

-- 4.4 Price and freight ranges
SELECT MIN(TRY_CAST(price AS decimal(10,2)))  AS min_price,
       MAX(TRY_CAST(price AS decimal(10,2)))  AS max_price,
       AVG(TRY_CAST(price AS decimal(10,2)))  AS avg_price,
       SUM(CASE WHEN TRY_CAST(price AS decimal(10,2)) <= 0 THEN 1 ELSE 0 END) AS non_positive_price,
       SUM(CASE WHEN TRY_CAST(REPLACE(freight_value, CHAR(13), '') AS decimal(10,2)) < 0 THEN 1 ELSE 0 END) AS negative_freight
FROM bronze.order_items;
-- Result:
-- Decision:

-- 4.5 Orphan keys
SELECT
    (SELECT COUNT(*) FROM bronze.order_items i
     WHERE NOT EXISTS (SELECT 1 FROM bronze.orders o   WHERE o.order_id = i.order_id))     AS items_without_order,
    (SELECT COUNT(*) FROM bronze.order_items i
     WHERE NOT EXISTS (SELECT 1 FROM bronze.products p WHERE p.product_id = i.product_id)) AS items_without_product,
    (SELECT COUNT(*) FROM bronze.order_items i
     WHERE NOT EXISTS (SELECT 1 FROM bronze.sellers s  WHERE s.seller_id = i.seller_id))   AS items_without_seller;
-- Result:
-- Decision:

-- 4.6 Items per order
SELECT MAX(item_count) AS max_items_in_one_order, AVG(item_count * 1.0) AS avg_items_per_order
FROM (SELECT order_id, COUNT(*) AS item_count FROM bronze.order_items GROUP BY order_id) t;
-- Result:


/*
===============================================================================
5. bronze.order_payments
===============================================================================
*/

-- 5.1 Grain: one row per order_id + payment_sequential
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CONCAT(order_id, '|', payment_sequential)) AS distinct_keys,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM bronze.order_payments;
-- Result:
-- Finding:  (orders can have several payment rows)

-- 5.2 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.order_payments
WHERE payment_value LIKE '%' + CHAR(13) + '%';
-- Result:

-- 5.3 Payment types
SELECT payment_type, COUNT(*) AS payments
FROM bronze.order_payments
GROUP BY payment_type
ORDER BY payments DESC;
-- Result:
-- Decision:

-- 5.4 Value and installment ranges
SELECT MIN(TRY_CAST(REPLACE(payment_value, CHAR(13), '') AS decimal(10,2))) AS min_value,
       MAX(TRY_CAST(REPLACE(payment_value, CHAR(13), '') AS decimal(10,2))) AS max_value,
       SUM(CASE WHEN TRY_CAST(REPLACE(payment_value, CHAR(13), '') AS decimal(10,2)) = 0 THEN 1 ELSE 0 END) AS zero_value_payments,
       SUM(CASE WHEN TRY_CAST(payment_installments AS int) = 0 THEN 1 ELSE 0 END) AS zero_installments,
       MAX(TRY_CAST(payment_installments AS int)) AS max_installments
FROM bronze.order_payments;
-- Result:
-- Decision:

-- 5.5 Orders with more than one payment record
SELECT COUNT(*) AS orders_with_multiple_payments
FROM (SELECT order_id FROM bronze.order_payments GROUP BY order_id HAVING COUNT(*) > 1) t;
-- Result:

-- 5.6 Payments without a matching order
SELECT COUNT(*) AS payments_without_order
FROM bronze.order_payments p
WHERE NOT EXISTS (SELECT 1 FROM bronze.orders o WHERE o.order_id = p.order_id);
-- Result:


/*
===============================================================================
6. bronze.order_reviews
===============================================================================
*/

-- 6.1 Grain
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT review_id) AS distinct_reviews,
       COUNT(DISTINCT order_id)  AS distinct_orders
FROM bronze.order_reviews;
-- Result:

-- 6.2 Orders with more than one review
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (SELECT order_id FROM bronze.order_reviews GROUP BY order_id HAVING COUNT(*) > 1) t;
-- Result:
-- Decision:  (rule for keeping one review per order)

-- 6.3 Review score values
SELECT review_score, COUNT(*) AS reviews
FROM bronze.order_reviews
GROUP BY review_score
ORDER BY review_score;
-- Result:
-- Decision:

-- 6.4 Date conversion failures
SELECT
    SUM(CASE WHEN TRIM(review_creation_date) <> ''
              AND TRY_CAST(review_creation_date AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_creation,
    SUM(CASE WHEN TRIM(REPLACE(review_answer_timestamp, CHAR(13), '')) <> ''
              AND TRY_CAST(REPLACE(review_answer_timestamp, CHAR(13), '') AS datetime2) IS NULL THEN 1 ELSE 0 END) AS bad_answer
FROM bronze.order_reviews;
-- Result:

-- 6.5 Reviews without a matching order
SELECT COUNT(*) AS reviews_without_order
FROM bronze.order_reviews r
WHERE NOT EXISTS (SELECT 1 FROM bronze.orders o WHERE o.order_id = r.order_id);
-- Result:


/*
===============================================================================
7. bronze.products
===============================================================================
*/

-- 7.1 Grain
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_id) AS distinct_products
FROM bronze.products;
-- Result:

-- 7.2 Missing category
SELECT COUNT(*) AS products_without_category
FROM bronze.products
WHERE product_category_name IS NULL OR TRIM(product_category_name) = '';
-- Result:
-- Decision:

-- 7.3 Categories with no English translation
SELECT COUNT(DISTINCT p.product_category_name) AS categories_without_translation
FROM bronze.products p
WHERE TRIM(p.product_category_name) <> ''
  AND NOT EXISTS (SELECT 1 FROM bronze.category_translation t
                  WHERE t.product_category_name = p.product_category_name);
-- Result:
-- Decision:

-- 7.4 Missing or zero physical attributes
SELECT
    SUM(CASE WHEN product_weight_g IS NULL OR TRIM(product_weight_g) = '' THEN 1 ELSE 0 END) AS missing_weight,
    SUM(CASE WHEN TRY_CAST(product_weight_g AS int) = 0 THEN 1 ELSE 0 END)                   AS zero_weight,
    SUM(CASE WHEN product_length_cm IS NULL OR TRIM(product_length_cm) = '' THEN 1 ELSE 0 END) AS missing_length,
    SUM(CASE WHEN product_photos_qty IS NULL OR TRIM(product_photos_qty) = '' THEN 1 ELSE 0 END) AS missing_photos
FROM bronze.products;
-- Result:
-- Decision:

-- 7.5 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.products
WHERE product_width_cm LIKE '%' + CHAR(13) + '%';
-- Result:


/*
===============================================================================
8. bronze.category_translation
===============================================================================
*/

-- 8.1 Grain and duplicates
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT product_category_name) AS distinct_categories
FROM bronze.category_translation;
-- Result:

-- 8.2 Hidden carriage return in last column
SELECT COUNT(*) AS rows_with_hidden_cr
FROM bronze.category_translation
WHERE product_category_name_english LIKE '%' + CHAR(13) + '%';
-- Result:
