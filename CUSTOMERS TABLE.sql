create database saubhagya12;
use saubhagya12;

create table customers(
CustomerID int primary key,
customerName text,
Email text,
Gender text,
Age int,
GeographyID int
);
SELECT * FROM CUSTOMERS;
create table products (
ProductID int ,
ProductName text,
Category text,
Price int
);

create table engagement_data2 (
EngagementID int Primary key,
ContentID int,
ContentType text,
Likes int,
EngagementDate datetime, 
CampaignID int,
ProductID int,
Views int,
Clicks int
);

create table geography (
GeographyID int primary key,
Country text,
City text
);

create table customer_reviews (
ReviewID int primary key,
CustomerID int,
ProductID int,
ReviewDate datetime,
Rating int,
ReviewText text
);

create table customer_journey (
JourneyID int primary key,
CustomerID int,
ProductID int,
VisitDate datetime,
Stage text,
Action text,
Duration float
);

CREATE TABLE sentiment_analysis (
    ReviewID INT PRIMARY KEY,
    CustomerID INT,
    ProductID INT,
    ReviewDate DATETIME,
    Rating INT,
    ReviewText TEXT,
    Sentiment_Label TEXT
);
select * from sentiment_analysis;
/* 1. Customer Purchase & Engagement Analysis*/
SELECT c.CustomerID, c.customerName, e.Views, e.Clicks, COUNT(r.ReviewID) AS total_reviews, 
       AVG(r.Rating) AS avg_rating
FROM customers c
LEFT JOIN engagement_data2 e ON c.CustomerID = e.ProductID
LEFT JOIN customer_reviews r ON c.CustomerID = r.CustomerID
GROUP BY c.CustomerID, c.customerName, e.Views, e.Clicks
ORDER BY e.Views DESC, e.Clicks DESC;

/*2. Best-Selling & Most Reviewed Products */
SELECT p.ProductID, p.ProductName, COUNT(r.ReviewID) AS total_reviews, 
       AVG(r.Rating) AS avg_rating
FROM products p
LEFT JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY total_reviews DESC, avg_rating DESC;

/*3. Customer Engagement Trends by Region*/
SELECT g.Country, g.City, AVG(e.Views) AS avg_views, AVG(e.Clicks) AS avg_clicks
FROM geography g
JOIN customers c ON g.GeographyID = c.GeographyID
JOIN engagement_data2 e ON c.CustomerID = e.ProductID
GROUP BY g.Country, g.City
ORDER BY avg_views DESC, avg_clicks DESC;

/*4. Customer Retention & Repeat Buyers*/
WITH CustomerPurchases AS (
    SELECT c.CustomerID, c.customerName, COUNT(r.ReviewID) AS total_purchases
    FROM customers c
    JOIN customer_reviews r ON c.CustomerID = r.CustomerID
    GROUP BY c.CustomerID, c.customerName
)
SELECT CustomerID, customerName, total_purchases,
       CASE 
           WHEN total_purchases > 5 THEN 'Loyal Customer'
           WHEN total_purchases BETWEEN 2 AND 5 THEN 'Returning Customer'
           ELSE 'First-time Buyer'
       END AS customer_type
FROM CustomerPurchases;

/*5. Identify Drop-off Points in Customer Journey*/
SELECT Stage, COUNT(CustomerID) AS customers_at_stage
FROM customer_journey
GROUP BY Stage
ORDER BY customers_at_stage DESC;

/*6. Monthly Engagement Trends*/
SELECT DATE_FORMAT(EngagementDate, '%Y-%m-%d') AS month, 
       AVG(Views) AS avg_views, AVG(Clicks) AS avg_clicks
FROM engagement_data2
GROUP BY month
ORDER BY month;

/*7. Top-Performing Products by Region*/
SELECT g.Country, g.City, p.ProductName, COUNT(r.ReviewID) AS total_reviews, 
       AVG(r.Rating) AS avg_rating
FROM geography g
JOIN customers c ON g.GeographyID = c.GeographyID
JOIN customer_reviews r ON c.CustomerID = r.CustomerID
JOIN products p ON r.ProductID = p.ProductID
GROUP BY g.Country, g.City, p.ProductName
ORDER BY g.Country, total_reviews DESC;

/*8. Identify High-Value Customers ( CUSTOMERS WITH MAX PURCHASE)*/
SELECT c.CustomerID, c.customerName, SUM(p.Price) AS total_spent, COUNT(r.ReviewID) AS total_purchases
FROM customers c
JOIN customer_reviews r ON c.CustomerID = r.CustomerID
JOIN products p ON r.ProductID = p.ProductID
GROUP BY c.CustomerID, c.customerName
ORDER BY total_spent DESC
LIMIT 10;

/*9. Most Popular Product Categories*/
SELECT p.Category, COUNT(r.ReviewID) AS total_purchases
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.Category
ORDER BY total_purchases DESC;

/*10. Customer Purchases Over Time*/
SELECT 
    DATE_FORMAT(r.ReviewDate, '%Y-%m') AS Purchase_Month,
    COUNT(r.ReviewID) AS Total_Purchases,
    SUM(p.Price) AS Total_Revenue
FROM customer_reviews r
JOIN products p ON r.ProductID = p.ProductID
GROUP BY Purchase_Month
ORDER BY Purchase_Month;

/*Customer Journey & Engagement Analysis:*/
/*Customers leaving the journey*/
SELECT Stage, COUNT(CustomerID) AS DropOff_Count
FROM customer_journey
GROUP BY Stage
ORDER BY DropOff_Count DESC;

/*Customers Who Drop Off Before Purchase*/
SELECT DISTINCT c.CustomerID, c.customerName
FROM customers c
LEFT JOIN customer_journey cj ON c.CustomerID = cj.CustomerID
WHERE cj.CustomerID NOT IN (
    SELECT CustomerID FROM customer_journey WHERE Stage = 'Purchase Completed'
);

/*average duration per stage*/
SELECT Stage, 
       COUNT(CustomerID) AS Total_Customers,
       AVG(Duration) AS Avg_Duration
FROM customer_journey
GROUP BY Stage
ORDER BY Avg_Duration DESC;

/*Highest-Rated & Lowest-Rated Products*/
-- Highest-rated products
SELECT p.ProductID, p.ProductName, AVG(r.Rating) AS AvgRating
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgRating DESC
LIMIT 5;

-- Lowest-rated products
SELECT p.ProductID, p.ProductName, AVG(r.Rating) AS AvgRating
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgRating ASC
LIMIT 5;

/*Correlate Sentiment & Ratings with Product Engagement*/
SELECT p.ProductID, p.ProductName, 
       AVG(r.Rating) AS AvgRating, 
       COUNT(CASE WHEN s.Sentiment_Label = 'Positive' THEN 1 END) AS PositiveReviews,
       COUNT(CASE WHEN s.Sentiment_Label = 'Negative' THEN 1 END) AS NegativeReviews,
       SUM(e.Views) AS TotalViews, 
       SUM(e.Clicks) AS TotalClicks,
       SUM(e.Likes) AS TotalLikes
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
JOIN engagement_data2 e ON p.ProductID = e.ProductID
JOIN customer_reviews_with_sentiment s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgRating DESC;

/*Calculation of Customer Retention Rate*/
WITH first_purchase AS (
    SELECT CustomerID, MIN(VisitDate) AS FirstPurchaseDate
    FROM customer_journey
    GROUP BY CustomerID
),
repeat_purchase AS (
    SELECT DISTINCT cj.CustomerID
    FROM customer_journey cj
    JOIN first_purchase fp ON cj.CustomerID = fp.CustomerID
    WHERE cj.VisitDate > fp.FirstPurchaseDate
)
SELECT 
    (COUNT(DISTINCT repeat_purchase.CustomerID) * 100.0 / COUNT(DISTINCT first_purchase.CustomerID)) AS RetentionRate
FROM first_purchase
LEFT JOIN repeat_purchase ON first_purchase.CustomerID = repeat_purchase.CustomerID;

/*Repeating purchase vs. First-Time purchase*/
SELECT 
    CASE 
        WHEN visit_count > 1 THEN 'Repeat Buyer'
        ELSE 'First-Time Buyer'
    END AS BuyerType,
    COUNT(DISTINCT CustomerID) AS CustomerCount
FROM (
    SELECT CustomerID, COUNT(*) AS visit_count
    FROM customer_journey
    GROUP BY CustomerID
) AS visits
GROUP BY BuyerType;

/*Best-Performing Products per Region*/
SELECT 
    g.Country, g.City, 
    p.ProductID, p.ProductName,
    COUNT(cj.JourneyID) AS TotalPurchases,
    AVG(cr.Rating) AS AvgRating
FROM customer_journey cj
JOIN customers c ON cj.CustomerID = c.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
JOIN products p ON cj.ProductID = p.ProductID
LEFT JOIN customer_reviews cr ON cj.ProductID = cr.ProductID
GROUP BY g.Country, g.City, p.ProductID, p.ProductName
ORDER BY g.Country, g.City, TotalPurchases DESC;


