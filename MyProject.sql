/*CREATE TABLE AMAZON_ORDERS(
    OrderID     VARCHAR2(50),
    OrderDate   DATE,
    CustomerID  VARCHAR2(50),
    CustomerName VARCHAR2(100),
    ProductID   VARCHAR2(50),
    ProductName VARCHAR2(100),
    Category    VARCHAR2(100),
    Brand       VARCHAR2(50),
    Quantity     NUMBER,
    UnitPrice   NUMBER(10,2),
    Discount    NUMBER(10,2),
    Tax         NUMBER(10,2),
    ShippingCost NUMBER(10,2),
    TotalAmount NUMBER(12,2),
    PaymentMethod VARCHAR2(50),
    OrderStatus VARCHAR2(50),
    City    VARCHAR2(100),
    State   VARCHAR2(100),
    Country     VARCHAR2(100),
    SellerID    VARCHAR2(50)
);*/

SELECT COUNT(*) FROM AMAZON_ORDERS;

--Annual revenue--
SELECT EXTRACT(YEAR FROM OrderDate) as Order_Year,
SUM(TotalAmount) as total_revenue 
FROM AMAZON_ORDERS
WHERE OrderStatus IN ('Delivered','Shipped')
GROUP BY EXTRACT(YEAR FROM OrderDate)
ORDER BY Order_YEAR;

--Monthly Revenue Trend
SELECT 
TO_CHAR(Orderdate, 'YYYY-MM') AS Year_Month,
SUM(TotalAmount) as month_revenue
FROM AMAZON_ORDERS
WHERE OrderStatus IN ('Delivered','Shipped')
GROUP BY TO_CHAR(Orderdate, 'YYYY-MM')
ORDER BY Year_Month;



--Category performance
SELECT Category , SUM(Quantity) AS total_quantity, SUM(TotalAmount) as category_revenue
FROM AMAZON_ORDERS
GROUP BY CATEGORY
ORDER BY category_revenue DESC;

--Hot selling products
SELECT ProductName, SUM(Quantity) AS total_quantity, SUM(TotalAmount) AS total_revenue
FROM AMAZON_ORDERS
WHERE OrderStatus = 'Delivered' or OrderStatus = 'Shipped'
GROUP BY ProductName
ORDER BY total_quantity DESC
FETCH FIRST 10 ROWS ONLY;

--High-value customers
SELECT CustomerID, CustomerName, SUM(TotalAmount) AS customer_revenue
FROM AMAZON_ORDERS
WHERE OrderStatus IN ('Delivered','Shipped')
GROUP BY CustomerID, CustomerName
ORDER BY customer_revenue DESC
FETCH FIRST 10 ROWS ONLY;

--Regional Market Analysis
WITH top_area AS(
    SELECT
        City, State, Country,
        SUM(TotalAmount) AS total_revenue
    FROM AMAZON_ORDERS
    GROUP BY City, State, Country
    ORDER BY total_revenue DESC
    FETCH FIRST 10 ROWS ONLY
), 
area_product AS(
    SELECT 
        A.City, A.State, A.Country,T.total_revenue, A.ProductName,
        SUM(A.UnitPrice * A.Quantity) AS Revenue,
        RANK() OVER (
                PARTITION BY A.City, A.State, A.Country
                ORDER BY SUM(A.UnitPrice * A.Quantity) DESC
            ) AS rnk
    FROM AMAZON_ORDERS A
    JOIN top_area T 
        ON A.City = T.City
        AND A.State = T.State
        AND A.Country = T.Country
    GROUP BY A.ProductName, A.City, A.State, A.Country, T.total_revenue)
    
SELECT City, State, Country, total_revenue,
    ProductName AS Top_Product,
    Revenue AS Top_Product_Revenue
FROM area_product
WHERE rnk = 1
ORDER BY total_revenue DESC;

--Average Order Value
SELECT CustomerID , CustomerName,
COUNT(DISTINCT OrderID) AS total_order, (SUM(TotalAmount)/NULLIF(COUNT(DISTINCT OrderID),0)) AS avg_order_value
FROM Amazon_Orders
WHERE OrderStatus IN ('Delivered', 'Shipped')
GROUP BY CustomerID , CustomerName
ORDER BY avg_order_value DESC;

--Orders and Customers (Volume metrics)
SELECT TO_CHAR(Orderdate, 'YYYY-MM') AS Year_Month,
COUNT(DISTINCT OrderID) AS monthly_orders,
COUNT(DISTINCT CustomerID) AS active_customers
FROM Amazon_Orders
WHERE OrderStatus IN ('Delivered', 'Shipped')
GROUP BY TO_CHAR(Orderdate, 'YYYY-MM')
ORDER BY Year_Month;

--Return/Cancellation Rate
SELECT 
TO_CHAR(Orderdate, 'YYYY-MM') AS Year_Month,
COUNT(DISTINCT OrderID) AS Monthly_order,
SUM(
    CASE
        WHEN OrderStatus IN ('Cancelled')
        THEN 1
        ELSE 0
    END
) AS Cancelled_Orders,
ROUND(SUM(
    CASE
        WHEN OrderStatus IN ('Cancelled')
        THEN 1
        ELSE 0
    END
)/ NULLIF(COUNT(DISTINCT OrderID),0)*100,2) AS "Cancelled_Rate(%)",
SUM(
    CASE
        WHEN OrderStatus IN ('Returned')
        THEN 1
        ELSE 0
    END
) AS Returned_Orders,
ROUND(SUM(
    CASE
        WHEN OrderStatus IN ('Returned')
        THEN 1
        ELSE 0
    END
)/ NULLIF(COUNT(DISTINCT OrderID),0)*100,2)  AS "Returned_Rate(%)"
FROM Amazon_Orders
GROUP BY TO_CHAR(Orderdate, 'YYYY-MM')
ORDER BY Year_Month
