SELECT 
    t.name AS TableName, 
    s.name AS SchemaName, 
    c.name AS ColumnName, 
    ty.name AS DataType
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    s.name IN ('dbo', 'reporting')
UNION ALL
SELECT
    v.name AS ViewName,
    s.name AS SchemaName,
    'N/A' AS ColumnName,
    'VIEW' AS DataType
FROM
    sys.views v
INNER JOIN
    sys.schemas s ON v.schema_id = s.schema_id;
