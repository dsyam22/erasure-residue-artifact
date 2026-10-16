WITH Checks AS (
    -- Check 1: dbo.customer (The primary table)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found

    UNION ALL

    -- Check 2: dbo_customer_CT (Change tracking/replica table)
    SELECT
        'dbo_customer_CT' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found

    UNION ALL

    -- Check 3: captured_columns (Metadata table check, searching for partial PII overlap in column names or types - low probability but included for completeness)
    SELECT
        'captured_columns' AS object_name,
        COUNT(CASE WHEN column_name LIKE '%subject%' OR column_type LIKE '%email%' THEN 1 END) AS rows_found

    UNION ALL

    -- Check 4: change_tables (Metadata table check)
    SELECT
        'change_tables' AS object_name,
        0 AS rows_found -- Assuming this table holds metadata, not raw PII records for the subject.
)
SELECT
    object_name,
    ISNULL(rows_found, 0) AS rows_found
FROM
    Checks;
