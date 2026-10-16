-- Read-only reconnaissance: find all user tables and character/temporal columns
-- that could hold residual personal data, plus temporal table and CDC/audit indicators.
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_memory_optimized,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

-- Other objects that may retain copies of data (history, audit, staging, logs)
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'TF', 'IF', 'P')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name;

-- Row counts per table (cheap estimate from partition stats)
SELECT s.name AS schema_name, t.name AS table_name, SUM(p.rows) AS approx_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- Check for Query Store / audit specifications / database-level change tracking
SELECT name, is_query_store_on FROM sys.databases WHERE name = DB_NAME();
SELECT name, is_enabled FROM sys.database_audit_specifications;
SELECT name, is_state_enabled FROM sys.server_audits;
