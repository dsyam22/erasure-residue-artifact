SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthInBytes
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;

-- Additionally, check for any triggers that might handle data changes (e.g., logging or replication)
SELECT 
    OBJECT_NAME(trigger_id) AS TriggerName,
    s.name AS SchemaName,
    t.name AS TableName,
    OBJECT_DEFINITION(trigger_id) AS TriggerDefinition
FROM 
    sys.triggers tr
INNER JOIN 
    sys.objects o ON tr.object_id = o.object_id
INNER JOIN 
    sys.schemas s ON o.schema_id = s.schema_id
WHERE 
    o.type = 'U' -- User objects only
ORDER BY 
    SchemaName, TableName;
