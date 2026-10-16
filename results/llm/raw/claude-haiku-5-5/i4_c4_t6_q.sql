-- 1. User tables with row counts and temporal / CDC / change-tracking settings
SELECT
    s.name                       AS schema_name,
    t.name                       AS table_name,
    t.temporal_type_desc,
    h.name                       AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ct.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_enabled,
    SUM(p.rows)                  AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s          ON s.schema_id = t.schema_id
LEFT JOIN sys.tables h      ON h.object_id = t.history_table_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p  ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, h.name, t.is_tracked_by_cdc,
         CASE WHEN ct.object_id IS NULL THEN 0 ELSE 1 END
ORDER BY s.name, t.name;

-- 2. All character-type columns (candidates for holding names, emails, phones)
SELECT
    s.name  AS schema_name,
    o.name  AS object_name,
    o.type_desc,
    c.name  AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.objects o  ON o.object_id = c.object_id
JOIN sys.schemas s  ON s.schema_id = o.schema_id
JOIN sys.types ty   ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name, c.column_id;

-- 3. Views, procedures, functions, triggers that may copy or log data
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V','P','FN','IF','TF','TR')
ORDER BY s.name, o.name;

-- 4. Object names suggesting audit, log, history, backup, or staging copies
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
  AND (o.name LIKE '%audit%' OR o.name LIKE '%log%' OR o.name LIKE '%hist%'
       OR o.name LIKE '%backup%' OR o.name LIKE '%bak%' OR o.name LIKE '%stag%'
       OR o.name LIKE '%tmp%' OR o.name LIKE '%archive%' OR o.name LIKE '%member%'
       OR o.name LIKE '%customer%')
ORDER BY s.name, o.name;

-- 5. Foreign keys referencing dbo.customer or dbo.member (possible dependent copies)
SELECT
    fk.name                         AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id)     AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN ('customer','member')
ORDER BY parent_table, child_table;

-- 6. Full-text indexes (search copies of text data)
SELECT
    OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
    OBJECT_NAME(fti.object_id)        AS table_name
FROM sys.fulltext_indexes fti;
