WITH ObjectCheck AS (
    -- 1. Checking dbo.customer_CT (CDC Change Table)
    SELECT
        N'dbo.customer_CT' AS object_name,
        (
            SELECT COUNT(DISTINCT T.[customer_id])
            FROM cdc.fn_cdc_get_all_changes_dbo_customer(@start_lsn, @end_lsn) AS T
            WHERE 1=1
              AND ISNULL(T.full_name, '') LIKE '%' + 'Subject_0000042' + '%'
              AND ISNULL(T.email, '') = 'subject42@example.invalid'
              AND ISNULL(T.phone, '') = '+1-555-0000042'
        ) AS rows_found

    UNION ALL

    -- 2. Checking dbo.customer (Current Table State - Expected 0)
    SELECT
        N'dbo.customer' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = 42
              AND full_name LIKE '%Subject_0000042%'
              AND email = 'subject42@example.invalid'
              AND phone = '+1-555-0000042'
        ) AS rows_found

    UNION ALL

    -- 3. Checking dbo.member (Current Table State - Expected 0)
    SELECT
        N'dbo.member' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.member
            WHERE member_id = 42
              AND full_name LIKE '%Subject_0000042%'
              AND email = 'subject42@example.invalid'
              AND phone = '+1-555-0000042'
        ) AS rows_found

    UNION ALL

    -- 4. Checking dbo.member_history (Temporal History Table)
    SELECT
        N'dbo.member_history' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.member_history
            WHERE member_id = 42
              AND full_name LIKE '%Subject_0000042%'
              AND email = 'subject42@example.invalid'
              AND phone = '+1-555-0000042'
        ) AS rows_found
)

SELECT object_name, rows_found FROM ObjectCheck;
