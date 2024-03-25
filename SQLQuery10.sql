
-- Find customers who have placed more than one order
SELECT CONCAT(first_name, ' ', last_name) as "name", COUNT(so.order_id)
FROM sales.orders so
JOIN sales.customers sc
ON sc.customer_id = so.customer_id
GROUP BY CONCAT(first_name, ' ', last_name)
HAVING COUNT(order_id) > 1
ORDER BY COUNT(order_id) DESC

SELECT concat(first_name, ' ', last_name)
FROM sales.customers


-- Get items from each order as well as the number of items that were in each order
SELECT  so.order_id, item_id ,
COUNT(item_id) OVER(PARTITION BY so.order_id) as #_items
FROM sales.orders so
JOIN sales.order_items oi
ON oi.order_id = so.order_id
ORDER BY so.order_id


-- Find any items that have not been ordered
SELECT oi.item_id
FROM sales.order_items oi
WHERE NOT EXISTS (
	SELECT 1
	FROM sales.orders o
	WHERE o.order_id = oi.order_id)


-- Find the top 5 most popular item by times ordered
SELECT x.*
FROM (
	SELECT p.product_name, COUNT(1) as times_ordered, SUM(oi.quantity) as tot_quantity_ordered,
	RANK() OVER (ORDER BY COUNT(1) DESC) as rnk
	FROM sales.order_items oi
	JOIN sales.orders o 
	ON oi.order_id = oi.order_id
	JOIN production.products p 
	ON p.product_id = oi.product_id
	GROUP BY p.product_name
) x
WHERE x.rnk <= 5


-- Find the top 5 most popular brands
SELECT x.brand_name, x.times_ordered, x.tot_quantity_ordered
FROM (	
	SELECT b.brand_name, COUNT(1) as times_ordered, SUM(oi.quantity) as tot_quantity_ordered,
	RANK() OVER(ORDER BY COUNT(1) DESC) as rnk
	FROM sales.order_items oi
	JOIN sales.orders o 
	ON oi.order_id = oi.order_id
	JOIN production.products p 
	ON p.product_id = oi.product_id
	JOIN production.brands b
	ON b.brand_id = p.brand_id
	GROUP BY b.brand_name
) x
WHERE x.rnk <= 5



-- Find YoY Profits
SELECT x.*,
CASE 
	WHEN x.OrderAmt > LAG(x.OrderAmt) OVER(ORDER BY yr) THEN 'Increased'
	WHEN x.OrderAmt < LAG(x.OrderAmt) OVER(ORDER BY yr) THEN 'Decreased'
	ELSE 'Equal'
END as YoY_Profit_Trend
FROM (
SELECT YEAR(o.order_date) as yr, 
SUM(oi.quantity * oi.list_price) - (SUM(oi.quantity * oi.list_price) * AVG(oi.discount)) as OrderAmt
FROM sales.order_items oi
JOIN sales.orders o
ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_date)
) x


-- Let's now check MoM revenue grouped by Year. Let's also see what percentage of each year's revenue each month made up
SELECT x.*,
CASE 
	WHEN x.OrderAmt > LAG(x.OrderAmt) OVER(ORDER BY x.yr, x.mth) THEN 'Increased'
	WHEN x.OrderAmt < LAG(x.OrderAmt) OVER(ORDER BY x.yr, x.mth) THEN 'Decreased'
	ELSE 'Equal'
END as MoM_Profit_Trend,
(x.OrderAmt / (SUM(OrderAmt) OVER(PARTITION BY x.yr)) * 100) as MonthlyPercent,
SUM(OrderAmt) OVER(PARTITION BY x.yr) as Yearly_amt
FROM
(
	SELECT MONTH(o.order_date) as mth, YEAR(o.order_date) as yr,
	SUM(oi.quantity * oi.list_price) - (SUM(oi.quantity * oi.list_price) * AVG(oi.discount)) as OrderAmt
	FROM sales.order_items oi
	JOIN sales.orders o
	ON o.order_id = oi.order_id
	GROUP BY YEAR(o.order_date), MONTH(o.order_date)
) x



-- Display the hierarchy of employees and managers
SELECT CONCAT(s1.first_name, ' ', s1.last_name) as Employee,
CONCAT(s2.first_name, ' ', s2.last_name) as Manager,
s1.staff_id, s1.manager_id
FROM sales.staffs s1
JOIN sales.staffs s2
ON s1.manager_id = s2.staff_id


-- See what employees have 'sold' the most
SELECT SUM(oi.quantity) as items_sold, CONCAT(s.first_name,' ', s.last_name) as full_name
FROM sales.staffs s
JOIN sales.orders o
ON s.store_id = o.store_id
JOIN sales.order_items oi
ON oi.order_id = o.order_id
GROUP BY CONCAT(s.first_name,' ', s.last_name)
ORDER BY SUM(oi.quantity) DESC


-- Find how much of each product each store has
SELECT ss.store_name, ps.quantity, pp.product_name
FROM sales.stores ss
JOIN production.stocks ps
ON ps.store_id = ss.store_id
JOIN production.products pp
ON pp.product_id = ps.product_id


-- Find items running low in stock (less than 10 left)
SELECT SUM(ps.quantity) as stock_amt, pp.product_name, ss.store_name
FROM production.stocks ps
JOIN sales.stores ss
ON ps.store_id = ss.store_id
JOIN production.products pp
ON pp.product_id = ps.product_id
GROUP BY ss.store_name, pp.product_name
HAVING SUM(ps.quantity) < 10


-- Find the amount of products each brand has
SELECT b.brand_name, count(p.product_id) as product_count
FROM production.products p 
JOIN production.brands b
ON p.brand_id = b.brand_id
GROUP BY b.brand_name


-- Which cities have the most orders and what percent of total orders do those cities make up
SELECT s.city, COUNT(o.order_id) as order_cnt,
COUNT(o.order_id) * 100 / SUM(COUNT(o.order_id)) OVER () as pct_of_total
FROM sales.stores s
JOIN sales.orders o 
ON s.store_id = o.store_id
JOIN sales.order_items i
ON i.order_id = o.order_id
GROUP BY city


-- Find the average order amount
SELECT ROUND(((SUM(list_price) * (100 - AVG(discount)) / COUNT(order_id))), 2) as avg_order_amt
FROM sales.order_items


-- How many new customers have made purchases in the most recent month
	-- Find the most recent month and year
SELECT MONTH(order_date), YEAR(order_date)
FROM sales.orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date) DESC

	-- Let's now find anyone who has ordered in Dec. 2018
SELECT *
FROM (
SELECT DISTINCT CONCAT(sc.first_name, ' ', sc.last_name) as full_name, 
FIRST_VALUE(so.order_date) OVER (PARTITION BY sc.customer_id ORDER BY so.order_date DESC) as first_order_date
FROM sales.orders so
JOIN sales.customers sc
ON so.customer_id = sc.customer_id
) x
WHERE x.first_order_date >= '2018-12-01'

