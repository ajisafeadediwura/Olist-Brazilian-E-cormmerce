# Project Brief

## Business context
Olist is an e-commerce marketplace in Brazil connecting small merchants to
larger online marketplaces. The data covers about 100k orders (2016 to 2018).
I am acting as the analyst briefing operations and commercial leadership.

## Business questions
1. Growth: How are orders and revenue trending month by month?
2. Products: Which categories drive revenue, and how concentrated is it?
3. Operations: How long does delivery take, and how often is it late?
4. Customers: Do customers return? Who are the most valuable customers?
5. Sellers: Is revenue concentrated in a few sellers?
6. Experience: How much does late delivery hurt review scores?

## Metric definitions
- Revenue: sum of item price, excluding freight
- Orders: count of distinct order_id
- Delivery days: days from purchase to delivery to the customer
- Late delivery rate: share of orders delivered after the estimated date
- Repeat customer rate: share of customer_unique_id with more than one order

## Scope and assumptions
- Delivered orders only, January 2017 to August 2018 (to be confirmed in profiling)
- Currency: Brazilian real
- Customer = customer_unique_id, not customer_id
