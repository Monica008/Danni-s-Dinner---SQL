--- CASE STUDY DANNIS'S DINNER

CREATE TABLE Sales (
  Customer_ID VARCHAR(15),
  Order_Date DATE,
  Product_ID NUMBER(15)
);

INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('A', TO_DATE('2021-01-01','YYYY-MM-DD'), 1);
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('A',TO_DATE('2021-01-01','YYYY-MM-DD'), '2');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('A',TO_DATE('2021-01-07','YYYY-MM-DD'), '2');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('A',TO_DATE('2021-01-10','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('A', TO_DATE('2021-01-11','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('A',TO_DATE( '2021-01-11','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('B',TO_DATE( '2021-01-01','YYYY-MM-DD'), '2');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('B',TO_DATE( '2021-01-02','YYYY-MM-DD'), '2');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('B',TO_DATE( '2021-01-04','YYYY-MM-DD'), '1');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('B', TO_DATE('2021-01-11','YYYY-MM-DD'), '1');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('B',TO_DATE( '2021-01-16','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('B',TO_DATE( '2021-02-01','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES ('C', TO_DATE('2021-01-01','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('C',TO_DATE( '2021-01-01','YYYY-MM-DD'), '3');
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID) VALUES  ('C', TO_DATE('2021-01-07','YYYY-MM-DD'), '3');
 
SELECT * FROM SALES;

CREATE TABLE Menu (
  Product_ID NUMBER(15),
  Product_Name VARCHAR(5),
  Price NUMBER(15)
);

INSERT INTO Menu(Product_ID, Product_Name, Price) VALUES (1, 'sushi', 10);
INSERT INTO Menu(Product_ID, Product_Name, Price) VALUES (2, 'curry', 15);
INSERT INTO Menu(Product_ID, Product_Name, Price) VALUES (3, 'ramen', 12);

SELECT * FROM MENU;

CREATE TABLE Members (
  Customer_ID VARCHAR(15),
  Join_Date DATE
);

INSERT INTO Members (Customer_ID, Join_Date) VALUES ('A', TO_DATE('2021-01-07','YYYY-MM-DD'));
INSERT INTO Members (Customer_ID, Join_Date) VALUES ('B', TO_DATE('2021-01-09','YYYY-MM-DD'));

SELECT * FROM MEMBERS;

--- What is the total amount each customer spent at the restaurant?

SELECT S.CUSTOMER_ID,SUM(M.PRICE) AS TOTAL_AMOUNT 
FROM SALES S INNER JOIN MENU M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID;

--- How many days has each customer visited the restaurant?

SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS CUSTOMER_VISITED
FROM SALES
GROUP BY CUSTOMER_ID;

--- What was the first item from the menu purchased by each customer?

WITH FIRST_ITEM AS
(
SELECT S.CUSTOMER_ID,M.PRODUCT_NAME,
DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS RANK
FROM SALES S INNER JOIN MENU M
ON S.PRODUCT_ID = M.PRODUCT_ID
)

SELECT CUSTOMER_ID,PRODUCT_NAME FROM FIRST_ITEM
WHERE RANK =1
GROUP BY CUSTOMER_ID,PRODUCT_NAME
ORDER BY CUSTOMER_ID;

--- What is the most purchased item on the menu and how many times 
--- was it purchased by all customers?

WITH PURCHASED AS(
SELECT M.PRODUCT_NAME,
COUNT(M.PRODUCT_NAME) AS MOST_PURCHASED
FROM SALES S INNER JOIN MENU M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY MOST_PURCHASED DESC
)
SELECT * FROM PURCHASED
WHERE ROWNUM =1;

--- Which item was the most popular for each customer?

WITH PURCHASED AS(
SELECT S.CUSTOMER_ID, M.PRODUCT_NAME,
COUNT(M.PRODUCT_ID) AS MOST_POPULAR,
DENSE_RANK() OVER(PARTITION BY S.customer_id ORDER BY COUNT(S.customer_id) DESC) AS rank
FROM SALES S INNER JOIN MENU M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID,M.PRODUCT_NAME
)
SELECT CUSTOMER_ID,PRODUCT_NAME,MOST_POPULAR FROM PURCHASED
WHERE RANK =1;

--- Which item was purchased first by the customer after they became a member?

WITH rank_purchase_item AS(
			     SELECT s.customer_id, 
				         m.product_name, 
				         s.order_date, 
				        mem. join_date,
				         DENSE_RANK() OVER(Partition by s.customer_id ORDER BY s.order_date) AS RANK 
			     FROM sales s
			     INNER JOIN menu m
			     ON s.product_id = m.product_id
			     INNER JOIN members mem
			     ON s.customer_id = mem.customer_id
			     WHERE s.order_date >= mem.join_date
                )
SELECT *
FROM rank_purchase_item
WHERE RANK =1;

--- Which item was purchased just before the customer became a member?

WITH purchased_prior_member AS (
  SELECT 
    mem.customer_id, 
    s.product_id,
    ROW_NUMBER() OVER(
       PARTITION BY mem.customer_id
       ORDER BY s.order_date DESC) AS rank
  FROM members MEM
  JOIN sales s
    ON mem.customer_id = s.customer_id
    AND s.order_date < mem.join_date
)

SELECT 
  p.customer_id, 
  m.product_name 
FROM purchased_prior_member p 
JOIN menu m
  ON p.product_id = m.product_id
WHERE rank = 1
ORDER BY p.customer_id ASC;

--- What is the total items and amount spent for each member before they became a member?

with memberdata as (
select s.customer_id,s.order_date,mem.join_date,m.price,m.product_name
 from sales s
 left join members mem
 on s.customer_id=mem.customer_id
 join menu m
 on s.product_id=m.product_id
 where s.order_date < mem.join_date)
 
 select customer_id,sum(price),count(distinct product_name)
 from memberdata
 group by customer_id;
 
--- If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--- how many points would each customer have?

with points as (
select s.customer_id,s.order_date,m.product_name,m.price,
case when m.product_name='sushi' then 2*m.price
else m.price end as newprice
 from sales s
 join menu m
 on s.product_id=m.product_id
)
select customer_id,sum(newprice)*10 from points
group by customer_id;

--- . In the first week after a customer joins the program (including their join date) 
--- they earn 2x points on all items, not just sushi
--- how many points do customer A and B have at the end of January?

WITH dates_cte AS (
  SELECT 
    customer_id, 
    join_date, 
    join_date + INTERVAL '6' DAY AS valid_date, 
    LAST_DAY(ADD_MONTHS(DATE '2021-01-31', 1) - INTERVAL '1' MONTH) AS last_date
  FROM members
)
SELECT 
  s.customer_id, 
  SUM(CASE
    WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
    WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
    ELSE 10 * m.price 
  END) AS points
FROM  sales s
JOIN dates_cte d
  ON s.customer_id = d.customer_id
  AND s.order_date <= d.last_date
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id;
 
















 