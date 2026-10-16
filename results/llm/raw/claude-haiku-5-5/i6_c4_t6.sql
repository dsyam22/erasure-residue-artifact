SELECT
    CAST('dbo.customer' AS nvarchar(256)) AS object_name,
    (
        SELECT COUNT(*)
        FROM dbo.customer AS c
        WHERE REPLACE(REPLACE(c.full_name, '-', ''), '+', '') LIKE N'%15550000042%'
           OR REPLACE(REPLACE(c.email, '-', ''), '+', '') LIKE N'%15550000042%'
    ) AS rows_found

UNION ALL

SELECT
    CAST('cdc.dbo_customer_CT' AS nvarchar(256)) AS object_name,
    (
        SELECT COUNT(*)
        FROM cdc.dbo_customer_CT AS ct
        WHERE REPLACE(REPLACE(ct.phone, '-', ''), '+', '') LIKE N'%15550000042%'
    ) AS rows_found;
