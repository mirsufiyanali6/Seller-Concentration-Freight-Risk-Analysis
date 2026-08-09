CREATE DATABASE market;

USE market


--1. Which sellers generate the highest revenue and order volume?

SELECT oi.seller_id,s.seller_city,s.seller_state,
COUNT(DISTINCT oi.order_id) AS order_count,
ROUND(SUM(oi.price),2) AS revenue
FROM order_items oi
JOIN sellers s ON oi.seller_id=s.seller_id
GROUP BY oi.seller_id,s.seller_city,s.seller_state
ORDER BY revenue DESC;

--2. What percentage of total marketplace revenue does each seller contribute?

SELECT seller_id,
ROUND(SUM(price),2) AS revenue,
SUM(price)*100.0/SUM(SUM(price)) OVER() AS revenue_share
FROM order_items
GROUP BY seller_id
ORDER BY revenue DESC;

--3. How concentrated is marketplace revenue across seller deciles, particularly the top 10%?

WITH sellers AS (
SELECT seller_id,SUM(price) AS revenue,NTILE(10) OVER(ORDER BY SUM(price) DESC) AS decile
FROM order_items
GROUP BY seller_id
)
SELECT decile,COUNT(*) AS sellers,
SUM(revenue) AS revenue,
SUM(revenue)*100.0/SUM(SUM(revenue)) OVER() AS revenue_share
FROM sellers
GROUP BY decile
ORDER BY decile;

--4. Which sellers have the highest revenue dependency risk based on their share of marketplace revenue?

SELECT seller_id,
SUM(price) AS revenue,
SUM(price)*100.0/SUM(SUM(price)) OVER() AS revenue_share
FROM order_items
GROUP BY seller_id
ORDER BY revenue_share DESC;

--5. Which seller categories or regions have the weakest seller coverage and potential single-seller dependency?

SELECT p.product_category_name,
COUNT(DISTINCT oi.seller_id) AS seller_count,
SUM(oi.price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
GROUP BY p.product_category_name
ORDER BY seller_count;

--6. What percentage of orders are shipped across state boundaries?

SELECT COUNT(DISTINCT CASE WHEN s.seller_state<>c.customer_state THEN o.order_id END)*100.0/COUNT(DISTINCT o.order_id) 
AS cross_state_percentage
FROM orders o
JOIN customers c 
ON o.customer_id=c.customer_id
JOIN order_items oi 
ON o.order_id=oi.order_id
JOIN sellers s 
ON oi.seller_id=s.seller_id;

--7. How does freight cost compare between cross-state and same-state orders?

SELECT 
CASE
WHEN s.seller_state=c.customer_state THEN 'Same State' 
ELSE 'Cross State'
END AS shipping_type,
COUNT(DISTINCT oi.order_id) AS orders,
AVG(oi.freight_value) AS avg_freight,
SUM(oi.freight_value) AS total_freight
FROM order_items oi
JOIN orders o 
ON oi.order_id=o.order_id
JOIN customers c 
ON o.customer_id=c.customer_id
JOIN sellers s 
ON oi.seller_id=s.seller_id
GROUP BY 
CASE
WHEN s.seller_state=c.customer_state THEN 'Same State' 
ELSE 'Cross State'
END;

--8. What percentage of orders have freight costs exceeding 50% of the item price?

SELECT COUNT(CASE WHEN freight_value>price*0.50 THEN 1 END)*100.0/COUNT(*) AS high_freight_percentage
FROM order_items; 

--9. Which sellers, routes, or regions have the highest freight-to-price ratios?

SELECT oi.seller_id,s.seller_state,
SUM(oi.price) AS item_value,SUM(oi.freight_value) AS freight_cost,
SUM(oi.freight_value)*100.0/SUM(oi.price) AS freight_to_price_ratio
FROM order_items oi
JOIN sellers s ON oi.seller_id=s.seller_id
GROUP BY oi.seller_id,s.seller_state
HAVING COUNT(*)>=20
ORDER BY freight_to_price_ratio DESC;

--10. Which orders have freight costs greater than the item value?
 
SELECT order_id,product_id,seller_id,price,freight_value,
freight_value*100.0/NULLIF(price,0) AS freight_to_price_ratio
FROM order_items
WHERE freight_value>price
ORDER BY freight_to_price_ratio DESC;

--11. How does freight cost vary with seller-to-customer distance?

SELECT s.seller_state,c.customer_state,
COUNT(DISTINCT oi.order_id) AS orders,
AVG(oi.freight_value) AS avg_freight,
SUM(oi.freight_value) AS total_freight
FROM order_items oi
JOIN orders o ON oi.order_id=o.order_id
JOIN customers c ON o.customer_id=c.customer_id
JOIN sellers s ON oi.seller_id=s.seller_id
GROUP BY s.seller_state,c.customer_state
ORDER BY avg_freight DESC;

--12. How are orders distributed across different installment counts?

SELECT payment_installments,
COUNT(DISTINCT order_id) AS orders,
SUM(payment_value) AS payment_value
FROM order_payments
GROUP BY payment_installments
ORDER BY payment_installments;

--13. How does order value vary with the number of payment installments?

SELECT payment_installments,
AVG(payment_value) AS avg_payment,
SUM(payment_value) AS total_payment
FROM order_payments
GROUP BY payment_installments
ORDER BY payment_installments;

--14. Which categories and regions have the highest use of installment payments?

SELECT p.product_category_name,
AVG(op.payment_installments*1.0) AS avg_installments,
COUNT(DISTINCT oi.order_id) AS orders
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
JOIN order_payments op ON oi.order_id=op.order_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY avg_installments DESC;

--15. How much total payment value is associated with high installment counts?

SELECT 
CASE WHEN payment_installments<=3 THEN '1-3' 
	 WHEN payment_installments<=6 THEN '4-6' 
	 WHEN payment_installments<=12 THEN '7-12' 
	 ELSE '13+' 
	 END AS installment_group,
COUNT(DISTINCT order_id) AS orders,
ROUND(SUM(payment_value),2) AS payment_value
FROM order_payments
GROUP BY 
CASE 
WHEN payment_installments<=3 THEN '1-3' 
WHEN payment_installments<=6 THEN '4-6' 
WHEN payment_installments<=12 THEN '7-12' 
ELSE '13+' 
END
ORDER BY MIN(payment_installments);

--16. How many product categories are included in each order?

SELECT oi.order_id,
COUNT(DISTINCT p.product_category_name) AS category_count
FROM order_items oi
JOIN products p 
ON oi.product_id=p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY oi.order_id
ORDER BY category_count DESC;

--17. What percentage of orders contain products from multiple categories?

SELECT COUNT(CASE WHEN category_count>1 THEN 1 END)*100.0/COUNT(*) AS multi_category_percentage
FROM (
SELECT oi.order_id,COUNT(DISTINCT p.product_category_name) AS category_count
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY oi.order_id
) x;

--18. How many different categories does each customer purchase across their lifetime?

SELECT c.customer_unique_id,
COUNT(DISTINCT p.product_category_name) AS category_count
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY c.customer_unique_id
ORDER BY category_count DESC;

--19. Which customers purchase across multiple categories but rarely combine categories within the same order?

SELECT c.customer_unique_id,
COUNT(DISTINCT p.product_category_name) AS lifetime_categories,
COUNT(DISTINCT o.order_id) AS orders
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT p.product_category_name)>=3
ORDER BY lifetime_categories DESC;

--20. Which product category combinations have the strongest potential for cross-selling?

SELECT p1.product_category_name AS category_1,p2.product_category_name AS category_2,
COUNT(DISTINCT oi1.order_id) AS orders
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id=oi2.order_id AND oi1.product_id<oi2.product_id
JOIN products p1 ON oi1.product_id=p1.product_id
JOIN products p2 ON oi2.product_id=p2.product_id
WHERE p1.product_category_name IS NOT NULL 
AND p2.product_category_name IS NOT NULL 
AND p1.product_category_name<>p2.product_category_name
GROUP BY p1.product_category_name,p2.product_category_name
ORDER BY orders DESC;