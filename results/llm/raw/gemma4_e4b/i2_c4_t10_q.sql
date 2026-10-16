SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    CASE WHEN c.is_nullable = 1 THEN 'Nullable' ELSE 'NOT Nullable' END AS Nullability,
    OBJECT_DEFINITION(o.object_id) AS ObjectDefinitionSnippet -- Check if object is a view or stored proc/trigger (if applicable)
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.objects o ON t.object_id = o.object_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;

SELECT 
    s.name AS SchemaName, 
    o.name AS ObjectName, 
    o.type_desc AS ObjectType
FROM 
    sys.objects o
INNER JOIN 
    sys.schemas s ON o.schema_id = s.schema_id
WHERE 
    o.is_ms_shipped = 0 -- Exclude system objects
ORDER BY 
    SchemaName, ObjectType;

-- Additionally check for any potential audit or logging tables (common locations for shadow PII)
SELECT 
    t.name AS TableName,
    c.name AS PotentialPIIColumn
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
WHERE 
    -- Look for common naming conventions associated with logging or auxiliary data
    t.name LIKE '%log%' OR t.name LIKE '%audit%' OR t.name LIKE '%history%';
