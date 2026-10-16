SET NOCOUNT ON;

-- 1. All user tables with row counts, temporal/history linkage, and CDC/change-tracking flags
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name + '.' + ht.name AS history_table,
    t.is_tracked_by_cdc,
    CAST(ct.object_id AS int) AS change_tracking_object_id,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_retention_period_unit_desc IS NULL AND ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Character/LOB columns in every user table (candidates for holding name, email, phone)
SELECT
    s.name AS schema_name,
    o.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id AND o.type IN ('U')
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.max_length = -1
ORDER BY s.name, o.name, c.column_id;

-- 3. Non-table objects (views, procedures, functions, triggers) whose definitions mention customer data
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
ORDER BY s.name, o.name;

-- 4. Database-level CDC and change tracking settings
SELECT
    d.name AS database_name,
    d.is_cdc_enabled,
    ctd.database_id AS change_tracking_database_id,
    ctd.retention_period,
    ctd.retention_period_units_desc
FROM sys.databases d
LEFT JOIN sys.change_tracking_databases ctd ON ctd.database_id = d.database_id
WHERE d.name = DB_NAME();
