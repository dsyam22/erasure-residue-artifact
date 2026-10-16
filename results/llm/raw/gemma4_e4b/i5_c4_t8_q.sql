SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes
FROM
    sys.tables t
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN
    sys.columns c ON t.object_id = c.object_id
INNER JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Exclude system schemas for cleaner output
ORDER BY
    SchemaName, TableName, ColumnName;
