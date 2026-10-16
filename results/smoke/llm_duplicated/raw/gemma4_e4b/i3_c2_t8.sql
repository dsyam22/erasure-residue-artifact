SET NOCOUNT ON;

-- Variables to hold counts for each object check
DECLARE @customer_count INT = 0;
DECLARE @cdc_customer_ct_count INT = 0;
DECLARE @member_count INT = 0;
DECLARE @member_history_count INT = 0;

-- --- 1. Check dbo.customer (Original Table) ---
SELECT @customer_count = COUNT(T.*)
FROM dbo.customer AS T
WHERE T.customer_id = 42
  AND T.full_name = 'Subject_0000042'
  AND T.email = 'subject42@example.invalid'
  AND T.phone = '+1-555-0000042';

-- --- 2. Check cdc.dbo_customer_CT (CDC Change Table) ---
SELECT @cdc_customer_ct_count = COUNT(T.*)
FROM cdc.dbo_customer_CT AS T
WHERE T.customer_id = 42; -- Checking the change metadata for the ID

-- --- 3. Check dbo.member (Original Temporal Table) ---
SELECT @member_count = COUNT(T.*)
FROM dbo.member AS T
WHERE T.member_id = 42
  AND T.full_name = 'Subject_0000042'
  AND T.email = 'subject42@example.invalid'
  AND T.phone = '+1-555-0000042';

-- --- 4. Check dbo.member_history (Temporal History Table) ---
SELECT @member_history_count = COUNT(T.*)
FROM dbo.member_history AS T
WHERE T.member_id = 42
  AND T.full_name = 'Subject_0000042'
  AND T.email = 'subject42@example.invalid'
  AND T.phone = '+1-555-0000042';

-- --- Final Result Set Construction ---
SELECT 
    'dbo.customer' AS object_name, 
    @customer_count AS rows_found
UNION ALL
SELECT 
    'cdc.dbo_customer_CT' AS object_name, 
    @cdc_customer_ct_count AS rows_found
UNION ALL
SELECT 
    'dbo.member' AS object_name, 
    @member_count AS rows_found
UNION ALL
SELECT 
    'dbo.member_history' AS object_name, 
    @member_history_count AS rows_found;
