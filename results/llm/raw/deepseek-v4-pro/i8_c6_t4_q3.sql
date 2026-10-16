-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS object_name,
    COUNT(*) AS rows_found
FROM sys.dm_sql_referencing_entities('dbo.customer', 'OBJECT')
WHERE referencing_class = 1
UNION ALL
SELECT 'dbo.customer', 0
WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer');
