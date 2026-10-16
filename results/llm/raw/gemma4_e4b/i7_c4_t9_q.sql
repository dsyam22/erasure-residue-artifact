SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
WHERE 
    t.name IN ('customer', 'customer_replica')
    AND SCHEMA_NAME(t.schema_id) IN ('dbo', 'reporting')
ORDER BY 
    SCHEMA_NAME(t.schema_id), t.table_name, c.column_name;
