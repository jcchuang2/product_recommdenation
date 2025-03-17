-- products
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY ,
    product_name TEXT,
    category TEXT,
    price INTEGER,
    brand VARCHAR(255),
    release_date TIMESTAMP,
    rating NUMERIC(3,1),
    rating_count INTEGER,
    description TEXT
);

CREATE TABLE products_staging (
    product_id VARCHAR(20),
    product_name TEXT,
    category TEXT,
    price TEXT,
    brand VARCHAR(255),
    release_date TIMESTAMP,
    rating TEXT,
    rating_count TEXT,
    description TEXT
);

INSERT INTO products (product_id, product_name, category, price, brand, release_date, rating, rating_count, description)
SELECT DISTINCT ON (product_id) -- keep one of each duplicate row
    product_id,
    product_name,
    category,
    NULLIF(regexp_replace(price, '[^0-9]', '', 'g'), '')::INTEGER,
    brand,
    release_date,
    NULLIF(regexp_replace(rating, '[^0-9.]', '', 'g'), '')::NUMERIC(3,1),
    NULLIF(regexp_replace(rating_count, '[^0-9]', '', 'g'), '')::INTEGER,
    description
FROM products_staging
WHERE rating ~ '^[0-9.]+$' OR rating IS NULL
ORDER BY product_id, rating_count DESC NULLS LAST;

-- users relation
CREATE TABLE users (
    user_id varchar(45) PRIMARY KEY
);

-- transactions
CREATE TABLE transactions (
    transaction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id varchar(20) REFERENCES products(product_id),
    user_id varchar(45) REFERENCES users(user_id)
);