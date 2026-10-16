SELECT DB_NAME() AS current_database;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type,
    t.temporal_type_desc,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_filetable,
    t.is_memory_optimized,
    t.ledger_type,
    t.ledger_type_desc,
    SUM(p.rows) AS row_count
FROM llm_i4.sys.tables AS t
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN llm_i4.sys.tables AS ht ON t.history_table_id = ht.object_id
LEFT JOIN llm_i4.sys.partitions AS p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
GROUP BY
    s.name,
    t.name,
    t.temporal_type,
    t.temporal_type_desc,
    ht.name,
    t.is_tracked_by_cdc,
    t.is_filetable,
    t.is_memory_optimized,
    t.ledger_type,
    t.ledger_type_desc
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.generated_always_type,
    c.generated_always_type_desc
FROM llm_i4.sys.tables AS t
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
JOIN llm_i4.sys.columns AS c ON t.object_id = c.object_id
JOIN llm_i4.sys.types AS ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.period_type_desc,
    c.name AS column_name
FROM llm_i4.sys.periods AS p
JOIN llm_i4.sys.tables AS t ON p.object_id = t.object_id
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
JOIN llm_i4.sys.columns AS c ON c.object_id = t.object_id AND c.column_id = p.column_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    ct.is_enabled
FROM llm_i4.sys.change_tracking_tables AS ct
JOIN llm_i4.sys.tables AS t ON ct.object_id = t.object_id
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

SELECT
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM llm_i4.sys.sql_modules AS m
JOIN llm_i4.sys.objects AS o ON m.object_id = o.object_id
WHERE m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%subject42@example.invalid%'
   OR m.definition LIKE '%+1-555-0000042%';

SELECT 'dbo.customer' AS source_table, customer_id, full_name, email, phone
FROM llm_i4.dbo.customer
WHERE customer_id = 42;

SELECT 'dbo.member' AS source_table, member_id, full_name, email, phone, valid_from, valid_to
FROM llm_i4.dbo.member
WHERE member_id = 42;

SELECT 'dbo.customer' AS source_table, customer_id, full_name, email, phone
FROM llm_i4.dbo.customer
WHERE full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

SELECT 'dbo.member' AS source_table, member_id, full_name, email, phone, valid_from, valid_to
FROM llm_i4.dbo.member
WHERE full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';
