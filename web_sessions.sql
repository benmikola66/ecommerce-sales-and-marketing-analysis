/* ============================================================
   Web Sessions Cleanup Script
   - Inspect web_sessions schema and data
   - Adjust data types
   - Snapshot raw data
   - Check for duplicates
   - Clean/standardize emails
   - Clean UTM source/medium fields
   - Clean device, landing_page, bounced
   ============================================================ */

---------------------------------------------------------------
-- 1. Inspect current web_sessions data and schema
---------------------------------------------------------------
SELECT *
FROM dbo.web_sessions;

EXEC sp_help 'dbo.web_sessions';


---------------------------------------------------------------
-- 2. Adjust session_id data type
---------------------------------------------------------------
ALTER TABLE dbo.web_sessions
ALTER COLUMN session_id nvarchar(50);


---------------------------------------------------------------
-- 3. Snapshot raw data
---------------------------------------------------------------
-- NOTE: This currently copies from dbo.orders into web_sessions_raw.
-- Keep as-is if intentional.
SELECT *
INTO web_sessions_raw
FROM dbo.orders;


---------------------------------------------------------------
-- 4. Inspect column names
---------------------------------------------------------------
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'web_sessions';


---------------------------------------------------------------
-- 5. Check duplicate session_ids
---------------------------------------------------------------
SELECT *
FROM dbo.web_sessions
WHERE session_id IN (
    SELECT session_id
    FROM dbo.web_sessions
    GROUP BY session_id
    HAVING COUNT(*) > 1
);


---------------------------------------------------------------
-- 6. Check duplicate customer_ids (in orders)
---------------------------------------------------------------
SELECT *
FROM dbo.orders
WHERE order_id IN (
    SELECT customer_id
    FROM dbo.orders
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);


---------------------------------------------------------------
-- 7. Clean emails (rename column + standardize pattern)
---------------------------------------------------------------
-- Rename customer_email → email
EXEC sp_rename 'dbo.web_sessions.customer_email', 'email', 'COLUMN';

-- Preview cleaned email logic
SELECT 
    email AS original_email,
    LOWER(
        CASE 
            WHEN email LIKE 'user%@%' 
            THEN
                'user' +
                -- Get the digits after 'user'
                CASE 
                    WHEN PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email)-5)) > 0
                    THEN LEFT(
                            SUBSTRING(email, 5, CHARINDEX('@', email)-5),
                            PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email)-5)) - 1
                         )
                    ELSE SUBSTRING(email, 5, CHARINDEX('@', email)-5) 
                END
                + SUBSTRING(email, CHARINDEX('@', email), LEN(email))
            ELSE email
        END
    ) AS cleaned_email
FROM dbo.web_sessions;

-- Apply cleaned email back into table
UPDATE dbo.web_sessions
SET email = LOWER(
        CASE 
            WHEN email LIKE 'user%@%' 
            THEN
                'user' +
                -- Get the digits after 'user'
                CASE 
                    WHEN PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email)-5)) > 0
                    THEN LEFT(
                            SUBSTRING(email, 5, CHARINDEX('@', email)-5),
                            PATINDEX('%[^0-9]%', SUBSTRING(email, 5, CHARINDEX('@', email)-5)) - 1
                         )
                    ELSE SUBSTRING(email, 5, CHARINDEX('@', email)-5) 
                END
                + SUBSTRING(email, CHARINDEX('@', email), LEN(email))
            ELSE email
        END
    );


---------------------------------------------------------------
-- 8. Change session_start from datetime2 to date type
---------------------------------------------------------------
ALTER TABLE dbo.web_sessions
ALTER COLUMN session_start date;


---------------------------------------------------------------
-- 9. Clean source and medium columns
---------------------------------------------------------------
-- Trim and lowercase utm_source_raw / utm_medium_raw
UPDATE web_sessions
SET utm_source_raw = LOWER(LTRIM(RTRIM(utm_source_raw))),
    utm_medium_raw = LOWER(LTRIM(RTRIM(utm_medium_raw)));

-- Inspect distinct sources
SELECT DISTINCT utm_source_raw
FROM dbo.web_sessions;

-- Preview mapping to clean source/medium using utm_mapping
SELECT
    COALESCE(m.clean_source, w.utm_source_raw) AS utm_source_clean,
    COALESCE(m.clean_medium, w.utm_medium_raw) AS utm_medium_clean,
    w.utm_source_raw,
    w.utm_medium_raw
FROM web_sessions w
LEFT JOIN utm_mapping m
  ON w.utm_source_raw = m.pattern_source;

-- Apply mapped values back to raw fields
UPDATE w
SET 
  w.utm_source_raw = COALESCE(m.clean_source, w.utm_source_raw),
  w.utm_medium_raw = COALESCE(m.clean_medium, w.utm_medium_raw)
FROM web_sessions w
LEFT JOIN utm_mapping m
  ON w.utm_source_raw = m.pattern_source;

-- Check what didn’t map
SELECT DISTINCT utm_source_raw, utm_medium_raw
FROM dbo.web_sessions;

-- Fix specific paid social naming and fb source
SELECT REPLACE(utm_medium_raw, 'social_paid', 'paid_social'),
       REPLACE(utm_source_raw,'fb','facebook')
FROM dbo.web_sessions
WHERE utm_medium_raw = 'social_paid';

UPDATE dbo.web_sessions
SET utm_medium_raw = REPLACE(utm_medium_raw, 'social_paid', 'paid_social');

SELECT DISTINCT utm_medium_raw
FROM dbo.web_sessions;

-- Normalize fb → facebook
UPDATE dbo.web_sessions
SET utm_source_raw = LOWER(LTRIM(RTRIM(REPLACE(utm_source_raw, 'fb', 'facebook'))));

SELECT DISTINCT utm_source_raw
FROM dbo.web_sessions; -- pulled two different facebooks --

-- Check length differences for facebook variants
SELECT utm_source_raw, LEN(utm_source_raw) AS raw_len
FROM dbo.web_sessions
WHERE utm_source_raw LIKE '%facebook%'; -- two had ten characters instead of 8 --

-- Force all facebook variants → 'facebook'
UPDATE dbo.web_sessions
SET utm_source_raw = 'facebook'
WHERE utm_source_raw LIKE '%facebook%';

SELECT DISTINCT utm_source_raw
FROM dbo.web_sessions;


---------------------------------------------------------------
-- 10. Clean landing_page
---------------------------------------------------------------
SELECT DISTINCT landing_page
FROM dbo.web_sessions;

UPDATE dbo.web_sessions
SET landing_page = 'home'
WHERE landing_page = 'home';


---------------------------------------------------------------
-- 11. Clean device field
---------------------------------------------------------------
UPDATE dbo.web_sessions
SET device = LOWER(LTRIM(RTRIM(device)));

SELECT DISTINCT device
FROM dbo.web_sessions; -- returns two 'mobile's --

-- Fix misspelling "moblie" → "mobile"
UPDATE dbo.web_sessions
SET device = 'mobile'
WHERE device = 'moblie';

SELECT DISTINCT device
FROM dbo.web_sessions;


---------------------------------------------------------------
-- 12. Clean bounced flag
---------------------------------------------------------------
SELECT DISTINCT bounced
FROM dbo.web_sessions;

-- Count how many NULLs
SELECT COUNT(*)
FROM dbo.web_sessions
WHERE bounced IS NULL;

-- Set NULLs to 0 (practice data only)
UPDATE dbo.web_sessions -- removign for practice data only --
SET bounced = 0
WHERE bounced IS NULL;
