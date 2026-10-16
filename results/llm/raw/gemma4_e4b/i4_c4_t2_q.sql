SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;

-- Additionally, check the data types and constraints on the known PII columns for Subject 42's IDs
SELECT 
    c.name AS Column, 
    DATA_TYPE_NAME(c.system_type_id) AS DataType,
    ISNULL(c.is_nullable, 0) = 1 AS IsNullable
FROM 
    dbo.customer c
UNION ALL
SELECT 
    c.name, 
    DATA_TYPE_NAME(c.system_type_id), 
    ISNULL(c.is_nullable, 0) = 1
FROM 
    dbo.member c;
