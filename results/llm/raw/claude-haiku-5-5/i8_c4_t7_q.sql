-- Inventory: all user tables and their character/identifier columns that could hold personal data,
-- plus row counts, and any LOB/temporal/change-tracking features that may retain deleted values.
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_memory_optimized,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    OBJECTPROPERTY(t.object_id, 'TableHasIdentity') AS has_identity,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
ORDER BY s.name, t.name, c.column_id;

-- Row counts per table (from partition stats, no table scans)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- Database-level features that may retain copies of deleted data
SELECT
    name AS database_name,
    is_cdc_enabled,
    is_change_tracking_on = CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases ctd WHERE ctd.database_id = DB_ID()) THEN 1 ELSE 0 END,
    is_temporal_history_retention_enabled,
    recovery_model_desc
FROM sys.databases
WHERE database_id = DB_ID();

-- Modules (procedures, functions, triggers, views) whose definitions reference customer data
SELECT
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%full_name%'
ORDER BY s.name, o.name;
