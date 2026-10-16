SET NOCOUNT ON;

-- 1. Database context and all user tables with row counts and temporal/CDC/change-tracking status
SELECT
    DB_NAME() AS database_name,
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    h.name AS history_table_name,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS h ON h.object_id = t.history_table_id
LEFT JOIN sys.change_tracking_tables AS ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, h.name, t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns across the database that could hold personal data or identifiers
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%member%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%addr%'
   OR c.name LIKE '%user%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%note%'
   OR c.name LIKE '%comment%'
   OR c.name LIKE '%json%'
   OR c.name LIKE '%payload%'
   OR c.name LIKE '%log%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Free-form / LOB / binary columns that could contain copies of personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('text', 'ntext', 'xml', 'varbinary', 'image', 'sql_variant')
   OR (ty.name IN ('varchar', 'nvarchar') AND c.max_length = -1)
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys that reference or are referenced by customer / member
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

-- 5. Views, procedures, functions, triggers whose definitions mention customer/member/subject/42
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc,
    CASE WHEN m.definition LIKE '%customer%' THEN 1 ELSE 0 END AS mentions_customer,
    CASE WHEN m.definition LIKE '%member%' THEN 1 ELSE 0 END AS mentions_member,
    CASE WHEN m.definition LIKE '%subject%' THEN 1 ELSE 0 END AS mentions_subject,
    CASE WHEN m.definition LIKE '%@example.invalid%' THEN 1 ELSE 0 END AS mentions_erased_domain
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
   OR m.definition LIKE '%subject%'
   OR m.definition LIKE '%@example.invalid%'
ORDER BY schema_name, object_name;

-- 6. Triggers on customer / member (may write copies to audit tables)
SELECT
    OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
    OBJECT_NAME(tr.parent_id) AS parent_table,
    tr.name AS trigger_name,
    tr.is_disabled
FROM sys.triggers AS tr
WHERE tr.parent_class = 1;

-- 7. Full-text indexes and columns (may keep stale index entries)
SELECT
    OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
    OBJECT_NAME(fti.object_id) AS table_name,
    fticol.column_id,
    COL_NAME(fti.object_id, fticol.column_id) AS column_name
FROM sys.fulltext_indexes AS fti
JOIN sys.fulltext_index_columns AS fticol ON fticol.object_id = fti.object_id;

-- 8. Query Store / plan cache presence (cached statements can echo erased values)
SELECT
    DB_NAME(qs.database_id) AS database_name,
    qs.is_query_store_on
FROM sys.database_query_store_options AS qs
WHERE qs.database_id = DB_ID();
