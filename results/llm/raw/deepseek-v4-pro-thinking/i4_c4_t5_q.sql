SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    t.temporal_type_desc,
    ht.name AS history_table_name,
    ISNULL(p.row_count, 0) AS row_count
FROM llm_i4.sys.tables AS t
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN llm_i4.sys.tables AS ht ON t.history_table_id = ht.object_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM llm_i4.sys.partitions
    WHERE index_id IN (0, 1)
    GROUP BY object_id
) AS p ON p.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS system_data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc,
    c.collation_name
FROM llm_i4.sys.tables AS t
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
JOIN llm_i4.sys.columns AS c ON c.object_id = t.object_id
JOIN llm_i4.sys.types AS ty
    ON c.system_type_id = ty.system_type_id
   AND ty.user_type_id = ty.system_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    c.name AS column_name,
    ic.key_ordinal
FROM llm_i4.sys.indexes AS i
JOIN llm_i4.sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN llm_i4.sys.tables AS t ON i.object_id = t.object_id
JOIN llm_i4.sys.schemas AS s ON t.schema_id = s.schema_id
JOIN llm_i4.sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_primary_key = 1 OR i.is_unique_constraint = 1
ORDER BY s.name, t.name, i.name, ic.key_ordinal;

SELECT
    fk.name AS foreign_key_name,
    s1.name AS referencing_schema,
    t1.name AS referencing_table,
    c1.name AS referencing_column,
    s2.name AS referenced_schema,
    t2.name AS referenced_table,
    c2.name AS referenced_column
FROM llm_i4.sys.foreign_keys AS fk
JOIN llm_i4.sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN llm_i4.sys.tables AS t1 ON fk.parent_object_id = t1.object_id
JOIN llm_i4.sys.schemas AS s1 ON t1.schema_id = s1.schema_id
JOIN llm_i4.sys.columns AS c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN llm_i4.sys.tables AS t2 ON fk.referenced_object_id = t2.object_id
JOIN llm_i4.sys.schemas AS s2 ON t2.schema_id = s2.schema_id
JOIN llm_i4.sys.columns AS c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
ORDER BY fk.name, fkc.constraint_column_id;
