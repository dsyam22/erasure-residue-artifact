SELECT DB_NAME() AS database_name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.type_desc,
    t.create_date,
    t.modify_date,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.type_desc, t.create_date, t.modify_date
ORDER BY s.name, t.name;

SELECT 
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS table_name,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
ORDER BY schema_name, table_name, c.column_id;

SELECT 
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
    OBJECT_NAME(fk.parent_object_id) AS parent_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fkc.constraint_column_id,
    pc.name AS parent_column,
    rc.name AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name, fkc.constraint_column_id;

SELECT 'dbo.customer' AS table_name, *
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

SELECT 'reporting.customer_replica' AS table_name, *
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
