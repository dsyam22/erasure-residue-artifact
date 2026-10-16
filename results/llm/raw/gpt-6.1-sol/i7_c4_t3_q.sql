SELECT
    DB_NAME() AS database_name,
    d.is_cdc_enabled
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_remote_data_archive_enabled
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_computed,
    c.encryption_type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    tr.name AS trigger_name,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema_name,
    OBJECT_NAME(tr.parent_id) AS parent_object_name,
    tr.is_disabled,
    sm.definition
FROM sys.triggers AS tr
LEFT JOIN sys.objects AS o ON o.object_id = tr.object_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS sm ON sm.object_id = tr.object_id
WHERE tr.parent_class = 1;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    ct.object_id,
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct;

SELECT
    N'dbo.customer' AS source_table,
    customer_id, full_name, email, phone
FROM dbo.customer
WHERE customer_id = 42
   OR full_name LIKE N'%Subject_0000042%'
   OR email LIKE N'%subject42@example.invalid%'
   OR phone LIKE N'%+1-555-0000042%';

SELECT
    N'reporting.customer_replica' AS source_table,
    customer_id, full_name, email, phone
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name LIKE N'%Subject_0000042%'
   OR email LIKE N'%subject42@example.invalid%'
   OR phone LIKE N'%+1-555-0000042%';
