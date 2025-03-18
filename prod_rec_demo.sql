-- categories with the most number of transactions
SELECT p.category, COUNT(t.transaction_id) as num_transactions
FROM transactions t
LEFT JOIN products p ON p.product_id = t.product_id
GROUP BY p.category
ORDER BY COUNT(t.transaction_id) DESC;

SELECT SPLIT_PART(category, '|', 1) as general_category, COUNT(t.transaction_id) as num_transactions
FROM transactions t
LEFT JOIN products p ON p.product_id = t.product_id
GROUP BY SPLIT_PART(category, '|', 1)
ORDER BY COUNT(t.transaction_id) DESC;

-- categories with the highest total amount of sales $
SELECT p.category, SUM(p.price) as total_sales
FROM transactions t
LEFT JOIN products p ON p.product_id = t.product_id
GROUP BY p.category
ORDER BY SUM(p.price) DESC LIMIT 10;

SELECT SPLIT_PART(category, '|', 1) as general_category, SUM(p.price) as total_sales
FROM transactions t
LEFT JOIN products p ON p.product_id = t.product_id
GROUP BY SPLIT_PART(category, '|', 1)
ORDER BY SUM(p.price)  DESC;

-- Most popular products (purchase counts)
SELECT p.product_name, COUNT(*) as num_purchases
FROM transactions t
LEFT JOIN products p ON p.product_id = t.product_id
GROUP BY p.product_id, p.product_name;

-- Upselling (same category but higher price)
SELECT
    p1.product_id as original__id,
    p1.product_name as orginal_product,
    p1.price as original_price,
    p2.product_id as new_id,
    p2.product_name as recommended_prod,
    p2.category,
    p2.price as new_price
FROM products p1
JOIN products p2
    ON p1.category = p2.category
    AND p2.price > p1.price  -- More expensive product
WHERE p1.product_id = 'B002SZEOLG'
ORDER BY p2.price ASC
LIMIT 1;


-- Trends in product release or ratings using release date
SELECT
    TO_CHAR(release_date, 'YYYY-MM') AS month_year,
    SUM(rating_count) AS num_ratings,
    COUNT(*) AS num_products
FROM products
GROUP BY month_year
ORDER BY month_year;

-- Brands with highest ratings
SELECT p.brand, ROUND(AVG(p.rating), 2) as average_rating, COUNT(*) as num_products, SUM(p.rating_count) as total_ratings
FROM products p
GROUP BY p.brand
ORDER BY AVG(p.rating) DESC, COUNT(*) DESC;

-- products with the highest rating
SELECT p.product_name, p.rating, p.rating_count
FROM products p
ORDER BY p.rating DESC, p.rating_count DESC;

-- discounted items
SELECT product_id, product_name, category, price
FROM products
WHERE price < (SELECT AVG(price) FROM products WHERE category = products.category)
ORDER BY category, price ASC;


-- top-rated items
SELECT product_id, product_name, category, rating, rating_count
FROM products
WHERE rating >= 4.5 AND rating_count > 50
ORDER BY rating DESC, rating_count DESC
LIMIT 10;

