-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cdc.is_cdc_enabled
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN sys.databases cdc ON 1=0
WHERE (s.name = 'dbo' AND t.name = 'customer')
   OR (s.name = 'cdc' AND t.name = 'dbo_customer_CT')
ORDER BY s.name, t.name, c.name;
