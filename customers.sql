/* ============================================================
   Customers Cleanup Script
   - Inspect customers table
   - Snapshot raw customers
   - Check duplicate customer_ids
   - Normalize email casing and remove malformed characters
   - Clean user pattern emails (user###@...)
   - Convert datetime2 fields to date
   - Inspect related tables
   ============================================================ */

---------------------------------------------------------------
-- 1. Inspect customers table
---------------------------------------------------------------
SELECT *
FROM dbo.customers;


---------------------------------------------------------------
-- 2. Snapshot raw customers
---------------------------------------------------------------
SELECT *
INTO customers_raw
FROM dbo.customers;


---------------------------------------------------------------
-- 3. Check duplicate customer_ids
---------------------------------------------------------------
SELECT *
FROM dbo.customers
WHERE customer_id IN (
    SELECT customer_id
    FROM dbo.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);


---------------------------------------------------------------
-- 4. Normalize email casing and trim whitespace
---------------------------------------------------------------
UPDATE dbo.customers
SET email = LOWER(LTRIM(RTRIM(email)));


---------------------------------------------------------------
-- 5. Preview email cleanup for malformed "user###@..." emails
---------------------------------------------------------------
SELECT 
    email AS original_email,
    LOWER(
        CASE 
            WHEN email LIKE 'user%@%' 
            THEN
                'user' +
                -- Extract digits after 'user'
                CASE 
                    WHEN PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email) - 5)) > 0
                    THEN LEFT(
                            SUBSTRING(email, 5, CHARINDEX('@', email) - 5),
                            PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email) - 5)) - 1
                         )
                    ELSE SUBSTRING(email, 5, CHARINDEX('@', email) - 5) 
                END
                + SUBSTRING(email, CHARINDEX('@', email), LEN(email))
            ELSE email
        END
    ) AS cleaned_email
FROM customers;

EXEC sp_help 'dbo.customers';


---------------------------------------------------------------
-- 6. Apply cleaned email back into customers
---------------------------------------------------------------
UPDATE dbo.customers
SET email = LOWER(
        CASE 
            WHEN email LIKE 'user%@%' 
            THEN
                'user' +
                -- Extract numeric portion after 'user'
                CASE 
                    WHEN PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email) - 5)) > 0
                    THEN LEFT(
                            SUBSTRING(email, 5, CHARINDEX('@', email) - 5),
                            PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email) - 5)) - 1
                         )
                    ELSE SUBSTRING(email, 5, CHARINDEX('@', email) - 5) 
                END
                + SUBSTRING(email, CHARINDEX('@', email), LEN(email))
            ELSE email
        END
    );


---------------------------------------------------------------
-- 7. Convert datetime2 → date
---------------------------------------------------------------
ALTER TABLE dbo.customers
ALTER COLUMN created_at date;

ALTER TABLE dbo.customers
ALTER COLUMN first_order_date date;


---------------------------------------------------------------
-- 8. Inspect related tables (orders, utm mapping, sessions)
---------------------------------------------------------------
SELECT *
FROM dbo.orders;

SELECT *
FROM dbo.utm_mapping;

SELECT *
FROM dbo.web_sessions;
