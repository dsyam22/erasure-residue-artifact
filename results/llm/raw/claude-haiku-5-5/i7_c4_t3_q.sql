SET NOCOUNT ON;

-- 1) All user tables: row counts, temporal/CDC/history flags
SELECT  s.name AS schema_name,
        t.name AS table_name,
        t.temporal_type_desc,
        t.history_table_id,
        t.is_tracked_by_cdc,
        t.is_memory_optimized,
        SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2) Columns that could hold personal data (by name or by character/LOB type)
SELECT  s.name AS schema_name,
        t.name AS table_name,
        c.name AS column_name,
        ty.name AS data_type,
        c.max_length,
        c.is_nullable
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (   c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
       OR c.name LIKE '%contact%' OR c.name LIKE '%note%' OR c.name LIKE '%json%'
       OR c.name LIKE '%payload%' OR c.name LIKE '%log%' OR c.name LIKE '%audit%'
       OR ty.name IN ('xml','text','ntext','sql_variant')
       OR (ty.name IN ('nvarchar','varchar','nchar','char') AND c.max_length = -1))
ORDER BY s.name, t.name, c.column_id;

-- 3) Foreign keys that reference or are referenced by customer tables
SELECT  OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
        fk.name AS fk_name,
        OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
        fk.delete_referential_action_desc,
        fk.update_referential_action_desc
FROM sys.foreign_keys fk
ORDER BY parent_table, child_table;

-- 4) Modules (views, procs, functions, triggers) whose text mentions customer data
SELECT  OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
        OBJECT_NAME(m.object_id) AS object_name,
        o.type_desc,
        LEN(m.definition) AS definition_length
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY schema_name, object_name;

-- 5) Views and synonyms that point at customer tables
SELECT  s.name AS schema_name, o.name AS object_name, o.type_desc, sy.base_object_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
LEFT JOIN sys.synonyms sy ON sy.object_id = o.object_id
WHERE o.type IN ('V','SN')
ORDER BY s.name, o.name;

-- 6) Triggers on user tables
SELECT  OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
        OBJECT_NAME(tr.parent_id) AS table_name,
        tr.name AS trigger_name,
        tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;
