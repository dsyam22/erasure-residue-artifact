SET NOCOUNT ON;

-- 1. All user tables: temporal/history linkage, CDC/change tracking flags, approximate row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name + N'.' + ht.name AS history_table,
    t.is_tracked_by_cdc,
    OBJECTPROPERTY(t.object_id, 'TableHasChangeTracking') AS has_change_tracking,
    t.is_memory_optimized,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name,
         t.is_tracked_by_cdc, t.object_id, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2. Character columns in every table (all tables, not just the two named ones)
SELECT
    s.name AS schema_name,
    o.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id AND o.type = 'U'
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext', 'xml', 'sql_variant')
ORDER BY s.name, o.name, c.column_id;

-- 3. Columns whose names suggest personal data (any table, any type)
SELECT
    s.name AS schema_name,
    o.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id AND o.type = 'U'
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE N'%name%' OR c.name LIKE N'%mail%' OR c.name LIKE N'%phone%'
   OR c.name LIKE N'%tel%' OR c.name LIKE N'%addr%' OR c.name LIKE N'%ssn%'
   OR c.name LIKE N'%birth%' OR c.name LIKE N'%customer%' OR c.name LIKE N'%member%'
   OR c.name LIKE N'%subject%' OR c.name LIKE N'%ident%' OR c.name LIKE N'%contact%'
ORDER BY s.name, o.name, c.column_id;

-- 4. Foreign keys (to find dependent or copied references to customer/member)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + N'.' + OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
ORDER BY referencing_table;

-- 5. Views, triggers, procedures, functions whose definitions mention the affected tables or key fields
SELECT
    o.type_desc,
    OBJECT_SCHEMA_NAME(o.object_id) + N'.' + o.name AS object_name,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE m.definition LIKE N'%customer%'
   OR m.definition LIKE N'%member%'
   OR m.definition LIKE N'%email%'
   OR m.definition LIKE N'%phone%'
ORDER BY object_name;

-- 6. Triggers defined on tables (could copy personal data into audit/log tables)
SELECT
    OBJECT_SCHEMA_NAME(tr.parent_id) + N'.' + OBJECT_NAME(tr.parent_id) AS parent_table,
    tr.name AS trigger_name,
    tr.is_disabled,
    tr.is_instead_of_trigger
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;

-- 7. Columns on the temporal history tables, if any (for member history retention)
SELECT
    OBJECT_SCHEMA_NAME(t.object_id) + N'.' + t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.generated_always_type_desc
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.temporal_type = 1
ORDER BY table_name, c.column_id;
