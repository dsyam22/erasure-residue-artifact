SET NOCOUNT ON;

DECLARE @phone nvarchar(60) = N'+1-555-0000042';
DECLARE @digits nvarchar(60) = N'%555-0000042%';

SELECT v.object_name, v.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer c
            WHERE c.full_name LIKE @digits OR c.email LIKE @digits) AS rows_found
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT ct
            WHERE ct.phone = @phone OR ct.phone LIKE @digits)
    UNION ALL
    SELECT N'cdc.ddl_history',
           (SELECT COUNT(*) FROM cdc.ddl_history dh
            WHERE dh.ddl_command LIKE @digits)
    UNION ALL
    SELECT N'dbo.systranschemas',
           (SELECT COUNT(*) FROM dbo.systranschemas st
            WHERE CAST(st.tabid AS nvarchar(20)) LIKE @digits)
) AS v
ORDER BY v.object_name;
