-- checking unique values
SELECT DISTINCT status FROM sales_data_sample; -- there are 6 various status type
SELECT DISTINCT productline FROM sales_data_sample;-- there are 7 productlines
SELECT DISTINCT country FROM sales_data_sample;-- orders are from 19 countries
SELECT DISTINCT  dealsize FROM sales_data_sample;-- there are 3 types of deals
SELECT DISTINCT month_id FROM sales_data_sample WHERE year_id = 2005;-- Revenue was made in 2005 only in 5 months but revenue was made in every month in 2003 and 2004  
-- Analysis
SELECT productline, round(SUM(sales) ,1) AS total_revenue
FROM sales_data_sample
GROUP BY productline
ORDER BY total_revenue DESC
LIMIT 3; -- we see that classic cars, vintage cars and motorcycles have the highst top 3 revenue

SELECT year_id,round(SUM(sales),1) as total_revenue
FROM sales_data_sample
GROUP BY year_id
ORDER BY total_revenue DESC;-- we can see the the highst revenue was in 2004 then in 2003 and the less in 2005

SELECT dealsize,round(SUM(sales),1) as total_revenue
FROM sales_data_sample
GROUP BY dealsize
ORDER BY total_revenue DESC;-- the highst revenue came from medium deals, followed by small and high

SELECT month_id,
       FORMAT(SUM(sales),0) AS monthly_revenue,
       COUNT(ordernumber) AS number_of_orders
FROM sales_data_sample
WHERE year_id = 2003 -- we can change the year and see monthly sales in 2004 or 2005
GROUP BY month_id
ORDER BY number_of_orders DESC;-- the highst revenue was made in 2003 and 2004 in october

SELECT productline,SUM(sales) AS productline_revenue,COUNT(ordernumber) as number_of_orders
FROM sales_data_sample
WHERE month_id = 11 AND year_id = 2004
GROUP BY productline
ORDER BY 1 DESC;-- classic cars and vintage cars were sold most in october 2003 and 2004

SELECT year_id,format(SUM(sales),0) as total_revenue, CASE
WHEN year_id = 2003 THEN format(SUM(sales)/12,0)
WHEN year_id = 2004 THEN format(SUM(sales)/12,0)
WHEN year_id = 2005 THEN format(SUM(sales)/5,0)
END as monthly_average_revenue
FROM sales_data_sample
GROUP BY year_id
ORDER BY 3 DESC;-- total_revenue was in 2003 was higher than 2005 but the monthly_average revenue in 2005 was higher than 2003. We can say that the monthly sales efficency was better in 2005 than 2003

-- orderdate was recorded as text, here we change it to DATE that we can use DATEDIFF
UPDATE sales_data_sample
SET orderdate = DATE_FORMAT(STR_TO_DATE(orderdate, '%m/%d/%Y %H:%i'), '%Y-%m-%d');

-- let's category the customers

CREATE VIEW  rfm_customer_analysis AS
WITH rfm AS(
SELECT customername, 
       FORMAT(SUM(sales),0) AS monetary_value,
       FORMAT(AVG(sales),0) AS average_monetary_value,
       COUNT(ordernumber) AS frequency,
       MAX(orderdate) AS last_orderdate_customer,
       
       DATEDIFF((SELECT MAX(orderdate)FROM sales_data_sample WHERE year_id=2005),MAX(orderdate)) as Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS
(
	SELECT r.*,
	NTILE(4) OVER(ORDER BY Recency) rfm_recency,
	NTILE(4) OVER(ORDER BY frequency) rfm_frequency,
	NTILE(4) OVER(ORDER BY average_monetary_value ) rfm_average_monetary_value
FROM rfm r -- the bigger of the sum of rfm values, the better is the customer
),
rfm_category AS
(
SELECT  c.* ,
      CONCAT(CAST(rfm_recency AS CHAR), CAST(rfm_frequency AS CHAR), CAST(rfm_average_monetary_value AS CHAR)) AS rfm_num
FROM rfm_calc c
)
SELECT customername,      CASE
      WHEN rfm_num IN(111,112,121,122,123,132,211,212,114,141) THEN 'lost_customers'
      WHEN rfm_num IN(134,133,143,244,334,343,344) THEN 'slipping_away, cannot lose'-- big orders but not active lately
      WHEN rfm_num IN(311,411,331) THEN 'new_customers'
      WHEN rfm_num IN(222,223,233,322) THEN 'potential_churners'
      WHEN rfm_num IN(323,333,321,422,332,432) THEN 'active_customers'-- active but orders are low
      WHEN rfm_num IN(433,434,443,444) THEN 'loyal_customers'
      END AS rfm_segment
FROM rfm_category y; -- so we put the customers in segments


-- which 2 products sold mostly
SELECT product1, product2, COUNT(*) AS num_sold_together
FROM (
    SELECT t1.productcode AS product1, t2.productcode AS product2
    FROM sales_data_sample t1
    JOIN sales_data_sample t2 ON t1.ordernumber = t2.ordernumber
    WHERE t1.productcode < t2.productcode
) AS sold_together
GROUP BY product1, product2
ORDER BY num_sold_together DESC
LIMIT 1;



























