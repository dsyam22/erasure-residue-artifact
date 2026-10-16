SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes, -- For nvarchar/nvarchar comparison
    ISNULL(c.is_nullable, CAST('Yes' AS varchar)) AS IsNullable,
    i.is_primary_key AS IsPrimaryKey,
    CASE WHEN fk.name IS NOT NULL THEN 'FOREIGN KEY (References Table: ' + OBJECT_NAME(fk.referenced_object_id) + ', Column: ' + COLUMN_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + ')' ELSE 'N/A' END AS ForeignKeyReference
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.foreign_keys fk ON t.object_id = fk.parent_object_id AND c.column_id = anyordinal(fkc)
INNER JOIN 
    sys.foreign_key_columns fkc ON fkc.parent_object_id = t.object_id AND fkc.column_id = c.column_id
LEFT JOIN 
    sys.indexes i ON t.object_id = i.object_id AND c.column_id = i.key_ordinal
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, 
    c.column_id;

SELECT * FROM sys.objects WHERE type IN ('V', 'P') ORDER BY name;
