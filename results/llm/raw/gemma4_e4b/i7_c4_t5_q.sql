SELECT 
    t.name AS table_name,
    c.column_name,
    c.data_type,
    c.max_length,
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS is_nullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
WHERE 
    t.name IN ('customer', 'customer_replica') 
    AND SCHEMA_NAME(t.schema_id) IN ('dbo', 'reporting');

SELECT * FROM sys.schemas WHERE name IN ('dbo', 'reporting');
