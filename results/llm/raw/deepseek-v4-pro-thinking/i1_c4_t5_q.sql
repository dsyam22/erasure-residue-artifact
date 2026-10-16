SELECT DB_NAME() AS current_database;

SELECT name,
       compatibility_level,
       user_access_desc,
       state_desc,
       recovery_model_desc
FROM sys.databases
WHERE name = DB_NAME();

SELECT schema_id,
       name
FROM sys.schemas
ORDER BY schema_id;

SELECT o.object_id,
       s.name AS schema_name,
       o.name AS object_name,
       o.type,
       o.type_desc,
       o.create_date,
       o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type NOT IN ('D', 'C', 'F', 'PK', 'UQ')
ORDER BY s.name, o.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.precision,
       c.scale,
       c.is_nullable,
       c.is_identity,
       c.is_computed,
       c.is_rowguidcol
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

SELECT fk.name AS foreign_key_name,
       OBJECT_SCHEMA_NAME(fkc.parent_object_id) AS referencing_schema,
       OBJECT_NAME(fkc.parent_object_id) AS referencing_table,
       cpc.name AS referencing_column,
       OBJECT_SCHEMA_NAME(fkc.referenced_object_id) AS referenced_schema,
       OBJECT_NAME(fkc.referenced_object_id) AS referenced_table,
       crc.name AS referenced_column,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc,
       fk.is_disabled
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns cpc
    ON fkc.parent_object_id = cpc.object_id
   AND fkc.parent_column_id = cpc.column_id
JOIN sys.columns crc
    ON fkc.referenced_object_id = crc.object_id
   AND fkc.referenced_column_id = crc.column_id
ORDER BY fk.name, fkc.constraint_column_id;

SELECT c.name AS constraint_name,
       s.name AS schema_name,
       t.name AS table_name,
       c.type_desc,
       c.is_disabled,
       c.definition
FROM sys.check_constraints c
JOIN sys.tables t ON c.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, c.name;

SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS total_rows
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
