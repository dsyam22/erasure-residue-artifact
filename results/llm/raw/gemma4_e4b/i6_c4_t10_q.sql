-- Check the structure of the primary customer table to confirm the 'phone' column was dropped.
SELECT 
    c.name AS ColumnName, 
    t.name AS DataType, 
    c.max_length AS MaxLength
FROM 
    sys.columns c
JOIN 
    sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE 
    c.object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    c.column_id;

-- List all tables and views in the current schema to confirm no other potential data stores exist.
SELECT 
    s.name AS SchemaName, 
    t.name AS TableOrViewName, 
    CASE WHEN t.type_desc = 'USER_TABLE' THEN 'Table' ELSE 'View/Other' END AS ObjectType
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id

UNION ALL

SELECT 
    s.name, 
    v.name, 
    CASE WHEN v.type_desc = 'VIEW' THEN 'View' ELSE 'Unknown' END
FROM 
    sys.views v
JOIN 
    sys.schemas s ON v.schema_id = s.schema_id;

-- Check for any system-level columns or data remnants that might be visible on the customer table itself (e.g., deleted/unused metadata).
SELECT * FROM sys.objects WHERE name = 'customer' AND type IN ('U', 'V');
