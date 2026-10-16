DECLARE @customer_table_count INT;
DECLARE @cdc_table_count INT;
DECLARE @member_history_count INT;
DECLARE @member_table_count INT;

-- 1. Check dbo.customer (Current state)
SELECT @customer_table_count = COUNT(*)
FROM dbo.customer
WHERE customer_id = 42;

-- 2. Check cdc.dbo_customer_CT (CDC History Table for Customer)
SELECT @cdc_table_count = COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = 42;

-- 3. Check dbo.member_history (Temporal History Table for Member)
-- We check against all known unique identifiers in the history table
SELECT @member_history_count = COUNT(*)
FROM dbo.member_history
WHERE member_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid';

-- 4. Check dbo.member (Current state)
SELECT @member_table_count = COUNT(*)
FROM dbo.member
WHERE member_id = 42;

-- Return the required single result set
SELECT
    'dbo.customer' AS object_name,
    @customer_table_count AS rows_found
UNION ALL
SELECT
    'cdc.dbo_customer_CT' AS object_name,
    @cdc_table_count AS rows_found
UNION ALL
SELECT
    'dbo.member_history' AS object_name,
    @member_history_count AS rows_found
UNION ALL
SELECT
    'dbo.member' AS object_name,
    @member_table_count AS rows_found;
