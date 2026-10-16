-- Inspecting all user-defined tables and columns in the database
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes, -- Displaying length for nvarchar/char types
    c.is_nullable AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Only user tables
ORDER BY 
    TableName, ColumnName;

-- Inspecting Foreign Key relationships to see if other tables referenced the customer ID or other PII fields
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableWithFK,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnInTableWithFK,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECT_NAME(fk.referenced_object_id) LIKE 'customer' -- Focus on relationships involving the main customer table
ORDER BY 
    TableWithFK;

-- Inspecting Indexes to see if large amounts of data (like full name/email strings) are indexed, which might indicate redundant storage
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    c.name AS ColumnIndexed
FROM 
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN 
    sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE 
    t.is_ms_shipped = 0
    AND i.index_id > 0 -- Exclude heap indexes
ORDER BY 
    TableName, IndexName;
