SET NOCOUNT ON;

-- 1. All user tables with temporal/history/CDC/change-tracking status and row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2. Columns in any table/view that could hold personal data or the subject's key
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND (
        c.name LIKE '%email%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%tel%'
     OR c.name LIKE '%name%'
     OR c.name LIKE '%customer%'
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%user%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%contact%'
     OR c.name LIKE '%address%'
     OR c.name LIKE '%pii%'
  )
ORDER BY s.name, o.name, c.column_id;

-- 3. Foreign keys referencing dbo.customer (possible dependent copies of the subject's key)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Code objects (views, procedures, functions, triggers) that reference customer or personal-data terms
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
ORDER BY schema_name, object_name;

-- 5. Full-text indexes and columns (indexed text may retain old values)
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fic.column_id,
    COL_NAME(fi.object_id, fic.column_id) AS column_name
FROM sys.fulltext_indexes fi
JOIN sys.fulltext_index_columns fic ON fic.object_id = fi.object_id
ORDER BY schema_name, table_name;

-- 6. Temporal/history table column layout for dbo.customer, if present
SELECT
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.generated_always_type_desc
FROM sys.columns c
WHERE c.object_id IN (OBJECT_ID(N'dbo.customer'), OBJECT_ID(N'dbo.customer_history'))
ORDER BY table_name, c.column_id;
