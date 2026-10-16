WITH SubjectData AS (
    SELECT 
        42 AS customer_id,
        '+1-555-0000042' AS phone
),
ObjectsToCheck AS (
    SELECT 'dbo.customer' AS object_name
    UNION ALL
    SELECT 'cdc.dbo_customer_CT'
),
Checks AS (
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer c
    CROSS JOIN SubjectData s
    WHERE c.customer_id = s.customer_id
      AND EXISTS (
          SELECT 1
          FROM sys.columns col
          WHERE col.object_id = OBJECT_ID('dbo.customer')
            AND col.name = 'phone'
      )
      AND CAST(c.phone AS nvarchar(50)) = s.phone

    UNION ALL

    SELECT 
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT ct
    CROSS JOIN SubjectData s
    WHERE ct.customer_id = s.customer_id
      AND EXISTS (
          SELECT 1
          FROM sys.columns col
          WHERE col.object_id = OBJECT_ID('cdc.dbo_customer_CT')
            AND col.name = 'phone'
      )
      AND CAST(ct.phone AS nvarchar(50)) = s.phone
)
SELECT 
    o.object_name,
    ISNULL(c.rows_found, 0) AS rows_found
FROM ObjectsToCheck o
LEFT JOIN Checks c ON o.object_name = c.object_name;
