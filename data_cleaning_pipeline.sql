/* ============================================================================
   E-COMMERCE SALES DATA — DATA CLEANING PIPELINE
   Author: Chandrachud Sahi
   Environment: SQLite Online
   Dataset: E-Commerce Sales Data (synthetic, generated with ChatGPT)

   Table: ecommerce_sales (720 rows, 12 columns)
   Columns: order_id, order_date, customer_id, customer_name, city, state,
            category, product, quantity, unit_price, payment_method,
            order_status

   This script follows the standard six-stage data cleaning methodology:
   1. Data Profiling / Baseline Assessment
   2. Handling Missing Data
   3. Data Standardization
   4. Data Validation
   5. Outlier Detection & Treatment
   6. Deduplication

   Decision rule applied throughout: values are set to NULL rather than
   fabricated or estimated, unless a deterministic relationship elsewhere
   in the same row supports rule-based imputation (e.g. city -> state).
   ============================================================================ */


/* ============================================================================
   STAGE 0 — DATA PROFILING / BASELINE ASSESSMENT
   ============================================================================ */

-- Establishes the row-count control total for the entire engagement.
-- Every later stage that removes or nullifies records is measured against
-- this baseline for auditability.
SELECT COUNT(*)
FROM ecommerce_sales;


/* ============================================================================
   STAGE 1 — HANDLING MISSING VALUES
   ============================================================================ */

-- 1.1 order_id: verify primary key integrity (no missing identifiers)
SELECT COUNT(*) - COUNT(order_id) AS missing_order_id
FROM ecommerce_sales;

-- 1.2 order_date: check for NULL and empty-string entries
SELECT COUNT(*) AS missing_dates
FROM ecommerce_sales
WHERE order_date IS NULL OR TRIM(order_date) = '';

-- 1.3 customer_id: check referential completeness
SELECT COUNT(*) AS missing_customer_id
FROM ecommerce_sales
WHERE customer_id IS NULL OR TRIM(customer_id) = '';

-- 1.4 customer_name: check completeness of customer attribution field
SELECT COUNT(*) AS missing_customer_name
FROM ecommerce_sales
WHERE customer_name IS NULL OR TRIM(customer_name) = '';

-- 1.5 city: check geographic completeness
SELECT COUNT(*) AS missing_city
FROM ecommerce_sales
WHERE city IS NULL OR TRIM(city) = '';

-- 1.6 state: check completeness of geographic hierarchy
SELECT COUNT(*) AS missing_state
FROM ecommerce_sales
WHERE state IS NULL OR TRIM(state) = '';

-- 1.7 Inspect affected state rows to check for a deterministic
-- relationship with city (used later to support rule-based imputation)
SELECT *
FROM ecommerce_sales
WHERE state IS NULL OR TRIM(state) = '';

-- 1.8 Normalize blank state entries to true NULL
UPDATE ecommerce_sales
SET state = NULL
WHERE state IS NOT NULL AND TRIM(state) = '';

-- 1.9 category: check for missing values
SELECT COUNT(*) AS missing_category
FROM ecommerce_sales
WHERE category IS NULL OR TRIM(category) = '';

-- 1.10 product: check for missing values
SELECT COUNT(*) AS missing_product
FROM ecommerce_sales
WHERE product IS NULL OR TRIM(product) = '';

-- 1.11 Normalize blank product entries to true NULL
UPDATE ecommerce_sales
SET product = NULL
WHERE product IS NOT NULL AND TRIM(product) = '';

-- 1.12 quantity: numeric column, use count-difference method
SELECT COUNT(*) - COUNT(quantity) AS missing_quantity
FROM ecommerce_sales;

-- 1.13 unit_price: numeric column, use count-difference method
SELECT COUNT(*) - COUNT(unit_price) AS missing_unit_price
FROM ecommerce_sales;

-- 1.14 payment_method: check for missing values
-- (surfaces the largest data quality gap in the dataset: 143 rows)
SELECT COUNT(*) AS missing_payment_method
FROM ecommerce_sales
WHERE payment_method IS NULL OR TRIM(payment_method) = '';

-- 1.15 Normalize blank payment_method entries to true NULL
UPDATE ecommerce_sales
SET payment_method = NULL
WHERE payment_method IS NOT NULL AND TRIM(payment_method) = '';

-- 1.16 order_status: check for missing values (completes missing-value audit)
SELECT COUNT(*) AS missing_order_status
FROM ecommerce_sales
WHERE order_status IS NULL OR TRIM(order_status) = '';


/* ============================================================================
   STAGE 2 — FIXING TEXT INCONSISTENCIES (DATA STANDARDIZATION)
   ============================================================================ */

-- 2.1 customer_name: enumerate unique values for manual inspection
SELECT DISTINCT customer_name
FROM ecommerce_sales
ORDER BY customer_name;

-- 2.2 customer_name: remove leading/trailing whitespace
UPDATE ecommerce_sales
SET customer_name = TRIM(customer_name)
WHERE customer_name IS NOT NULL;

-- 2.3 city: enumerate unique values to identify casing/whitespace/spelling issues
SELECT DISTINCT city
FROM ecommerce_sales;

-- 2.4 city: normalize-then-map standardization
-- Phase 1: normalize baseline (lowercase, trimmed)
UPDATE ecommerce_sales SET city = LOWER(TRIM(city)) WHERE city IS NOT NULL;
-- Phase 2: map known variants to a single canonical, correctly-cased value
UPDATE ecommerce_sales SET city = 'New Delhi'
WHERE city = 'new delhi' OR city = 'delhi';
UPDATE ecommerce_sales SET city = 'Bengaluru'
WHERE city = 'bangalore' OR city = 'bengaluru';
UPDATE ecommerce_sales SET city = 'Mumbai'
WHERE city = 'mumbai' OR city = 'bombay';
UPDATE ecommerce_sales SET city = 'Pune'
WHERE city = 'pune' OR city = 'poona';
UPDATE ecommerce_sales SET city = 'Lucknow'
WHERE city = 'lucknow';

-- 2.5 state: enumerate unique values
SELECT DISTINCT state
FROM ecommerce_sales
WHERE state IS NOT NULL;

-- 2.6 state: normalize-then-map standardization
UPDATE ecommerce_sales SET state = LOWER(TRIM(state)) WHERE state IS NOT NULL;
UPDATE ecommerce_sales SET state = 'Delhi'
WHERE state = 'nct delhi' OR state = 'delhi';
UPDATE ecommerce_sales SET state = 'Karnataka'
WHERE state = 'karnatak' OR state = 'karnataka';
UPDATE ecommerce_sales SET state = 'Maharashtra'
WHERE state = 'maharashtra' OR state = 'maharastra';
UPDATE ecommerce_sales SET state = 'Uttar Pradesh'
WHERE state = 'uttarpradesh' OR state = 'up' OR state = 'uttar pradesh';

-- 2.7 category: enumerate unique values
SELECT DISTINCT category
FROM ecommerce_sales
WHERE category IS NOT NULL;

-- 2.8 category: normalize-then-map standardization
UPDATE ecommerce_sales SET category = LOWER(TRIM(category)) WHERE category IS NOT NULL;
UPDATE ecommerce_sales SET category = 'Fashion'
WHERE category = 'fashion' OR category = 'fashon';
UPDATE ecommerce_sales SET category = 'Home'
WHERE category = 'home' OR category = 'hme';
UPDATE ecommerce_sales SET category = 'Electronics'
WHERE category = 'electronics' OR category = 'electronic' OR category = 'electornics';

-- 2.9 product: enumerate unique values (whitespace irregularities only, no spelling variants)
SELECT DISTINCT product
FROM ecommerce_sales
WHERE product IS NOT NULL;

-- 2.10 product: remove whitespace
UPDATE ecommerce_sales
SET product = TRIM(product)
WHERE product IS NOT NULL;

-- 2.11 payment_method: enumerate unique values
SELECT DISTINCT payment_method
FROM ecommerce_sales
WHERE payment_method IS NOT NULL;

-- 2.12 payment_method: remove whitespace
UPDATE ecommerce_sales
SET payment_method = TRIM(payment_method)
WHERE payment_method IS NOT NULL;

-- 2.13 order_status: enumerate unique values
SELECT DISTINCT order_status
FROM ecommerce_sales
WHERE order_status IS NOT NULL;

-- 2.14 order_status: remove whitespace (completes text standardization pass)
UPDATE ecommerce_sales
SET order_status = TRIM(order_status)
WHERE order_status IS NOT NULL;

-- 2.15 order_date: enumerate unique values to assess format consistency
-- KNOWN LIMITATION: SQLite has no equivalent to MySQL's STR_TO_DATE() for
-- parsing textual month formats, so the three mixed order_date formats
-- could not be consolidated into a single DATE column in this environment.
-- See the MySQL migration snippet at the end of this file.
SELECT DISTINCT order_date
FROM ecommerce_sales
ORDER BY order_date;


/* ============================================================================
   STAGE 3 — CLEANING INVALID VALUES (DATA VALIDATION)
   ============================================================================ */

-- 3.1 quantity: identify logically invalid entries (zero or negative)
SELECT *
FROM ecommerce_sales
WHERE quantity <= 0;

-- 3.2 quantity: set invalid values to NULL
UPDATE ecommerce_sales
SET quantity = NULL
WHERE quantity <= 0;

-- 3.3 unit_price: identify logically invalid entries (zero or negative)
SELECT *
FROM ecommerce_sales
WHERE unit_price <= 0;

-- 3.4 unit_price: set invalid values to NULL
UPDATE ecommerce_sales
SET unit_price = NULL
WHERE unit_price <= 0;

-- 3.5 payment_method: domain-validity check
SELECT DISTINCT payment_method
FROM ecommerce_sales
ORDER BY payment_method;

-- 3.6 order_status: domain-validity check
SELECT DISTINCT order_status
FROM ecommerce_sales
ORDER BY order_status;

-- 3.7 category: domain-validity check (post-standardization)
SELECT DISTINCT category
FROM ecommerce_sales
ORDER BY category;

-- 3.8 city: domain-validity check
SELECT DISTINCT city
FROM ecommerce_sales
ORDER BY city;

-- 3.9 state: review remaining NULLs and their corresponding city values
-- to confirm the deterministic city -> state relationship before imputing
SELECT DISTINCT state
FROM ecommerce_sales
ORDER BY state;

SELECT city, state
FROM ecommerce_sales
WHERE state IS NULL;

-- 3.10 state: rule-based imputation from standardized city
-- (not statistical estimation — a fixed, verifiable geographic lookup)
UPDATE ecommerce_sales SET state = 'Delhi'
WHERE city = 'New Delhi' AND state IS NULL;
UPDATE ecommerce_sales SET state = 'Maharashtra'
WHERE (city = 'Mumbai' OR city = 'Pune') AND state IS NULL;
UPDATE ecommerce_sales SET state = 'Karnataka'
WHERE city = 'Bengaluru' AND state IS NULL;
UPDATE ecommerce_sales SET state = 'Uttar Pradesh'
WHERE city = 'Lucknow' AND state IS NULL;

-- 3.11 product: final domain-validity check for this stage
SELECT DISTINCT product
FROM ecommerce_sales
ORDER BY product;


/* ============================================================================
   STAGE 4 — REMOVING OUTLIERS (OUTLIER DETECTION & TREATMENT)
   ============================================================================ */

-- 4.1 quantity: establish observed range
SELECT MIN(quantity), MAX(quantity)
FROM ecommerce_sales;

-- 4.2 quantity: inspect top values for sentinel/error patterns
SELECT order_id, product, quantity
FROM ecommerce_sales
ORDER BY quantity DESC
LIMIT 10;

-- 4.3 quantity: set sentinel value (999) to NULL
-- Treated as a data-entry sentinel rather than a statistical outlier,
-- since 999 recurred identically across three unrelated products.
UPDATE ecommerce_sales
SET quantity = NULL
WHERE quantity = 999;

-- 4.4 unit_price: establish observed range
SELECT MIN(unit_price), MAX(unit_price)
FROM ecommerce_sales;

-- 4.5 unit_price: inspect top values for sentinel/error patterns
SELECT order_id, product, unit_price
FROM ecommerce_sales
ORDER BY unit_price DESC
LIMIT 10;

-- 4.6 unit_price: set sentinel value (999,999) to NULL
-- Recurred identically across four unrelated products, consistent with a
-- placeholder value rather than a genuine premium price.
UPDATE ecommerce_sales
SET unit_price = NULL
WHERE unit_price = 999999;


/* ============================================================================
   STAGE 5 — REMOVING DUPLICATE RECORDS (DEDUPLICATION)
   ============================================================================ */

-- 5.1 Identify exact full-row duplicates (all 12 columns match)
SELECT *, COUNT(*) AS duplicate_count
FROM ecommerce_sales
GROUP BY order_id, order_date, customer_id, customer_name,
         city, state, category, product, quantity,
         unit_price, payment_method, order_status
HAVING COUNT(*) > 1;

-- 5.2 Remove redundant copies, retaining the lowest rowid per duplicate group
DELETE FROM ecommerce_sales
WHERE rowid NOT IN (
    SELECT MIN(rowid)
    FROM ecommerce_sales
    GROUP BY order_id, order_date, customer_id, customer_name,
             city, state, category, product, quantity,
             unit_price, payment_method, order_status
);

-- 5.3 Final row count — compare against the 720-row baseline
SELECT COUNT(*)
FROM ecommerce_sales;


/* ============================================================================
   RECOMMENDED NEXT STEP — order_date NORMALIZATION (MySQL)
   Not executable in SQLite; documented here for migration to an engine
   that supports STR_TO_DATE() with explicit format masks.
   ============================================================================ */

-- UPDATE ecommerce_sales
-- SET parsed_date = CASE
--     WHEN order_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
--         THEN STR_TO_DATE(order_date, '%Y-%m-%d')
--     WHEN order_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
--         THEN STR_TO_DATE(order_date, '%m/%d/%Y')
--     WHEN order_date REGEXP '^[0-9]{2}-[A-Za-z]+-[0-9]{4}$'
--         THEN STR_TO_DATE(order_date, '%d-%M-%Y')
--     ELSE NULL
-- END;
-- Routes each row to the correct format mask based on a regex match against
-- its shape, writing the result into a new native DATE column (parsed_date).
-- Rows matching none of the three known patterns are left NULL for manual
-- review rather than being misparsed silently.
