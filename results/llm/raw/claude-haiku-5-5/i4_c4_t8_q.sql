-- Read-only inventory for locating residual personal data (SELECT only)

-- 1. All user tables with temporal, CDC, and change-tracking status, plus approximate row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht
    ON ht.object_id = t.history_retention_period_unit_desc -- placeholder join avoided below
LEFT JOIN sys.schemas AS hs
    ON 1 = 0
LEFT JOIN sys.change_tracking_tables AS ctt
    ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions AS p
    ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name, t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (character/text types or name-like columns)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t
    ON t.object_id = c.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (
        ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml', 'sysname')
     OR c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%customer%'
     OR c.name LIKE '%member%'
     OR c.name LIKE '%note%'
     OR c.name LIKE '%json%'
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys (to find dependent copies of customer_id / member_id)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys AS fk
ORDER BY child_table, parent_table;

-- 4. Modules (views, procedures, functions, triggers) whose definitions mention personal-data columns or tables
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
WHERE m.definition LIKE '%full_name%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
ORDER BY schema_name, object_name;

-- 5. Full-text indexes and whether any tables have them
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fi.is_enabled
FROM sys.fulltext_indexes AS fi;
