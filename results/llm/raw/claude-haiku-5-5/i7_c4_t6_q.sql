SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    (SELECT COUNT(*) FROM sys.triggers tr WHERE tr.parent_id = t.object_id) AS trigger_count,
    (SELECT COUNT(*) FROM sys.change_tracking_tables ct WHERE ct.object_id = t.object_id) AS change_tracking_enabled
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c
    ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

-- Views, procedures, functions, and triggers whose definitions reference customer data
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc,
    CASE
        WHEN m.definition LIKE '%customer%' THEN 'mentions customer'
        ELSE 'other'
    END AS note
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
ORDER BY schema_name, object_name;

-- Foreign keys that reference or are referenced by customer tables
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys AS fk
ORDER BY child_schema, child_table;

-- Row counts in customer-related tables for the erased customer_id
IF OBJECT_ID(N'dbo.customer') IS NOT NULL
    EXEC sp_executesql
        N'SELECT ''dbo.customer'' AS src, COUNT(*) AS rows_for_42 FROM dbo.customer WHERE customer_id = 42;';
IF OBJECT_ID(N'reporting.customer_replica') IS NOT NULL
    EXEC sp_executesql
        N'SELECT ''reporting.customer_replica'' AS src, COUNT(*) AS rows_for_42 FROM reporting.customer_replica WHERE customer_id = 42;';
