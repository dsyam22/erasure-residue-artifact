SET NOCOUNT ON;

-- 1. All user tables: row counts, temporal/CDC/change-tracking status
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    ct.object_id AS change_tracking_enabled_object,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (names, email, phone, IDs, free text)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%user%'
     OR c.name LIKE '%contact%'
     OR c.name LIKE '%note%'
     OR c.name LIKE '%comment%'
     OR c.name LIKE '%json%'
     OR c.name LIKE '%text%'
     OR TYPE_NAME(c.user_type_id) IN ('text','ntext','xml')
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Triggers, views, procedures, functions that reference customer data
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc,
    CASE WHEN m.definition LIKE '%customer%' THEN 1 ELSE 0 END AS mentions_customer,
    CASE WHEN m.definition LIKE '%email%' OR m.definition LIKE '%phone%' THEN 1 ELSE 0 END AS mentions_contact_fields
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
ORDER BY schema_name, object_name;

-- 5. Tables in the reporting schema specifically (replica and any others)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE s.name = N'reporting'
GROUP BY s.name, t.name
ORDER BY t.name;
