SELECT 'Current database properties' AS info,
       DB_NAME() AS database_name,
       d.compatibility_level,
       d.collation_name,
       d.is_cdc_enabled,
       d.is_change_tracking_enabled,
       d.is_temporal_history_retention_enabled,
       d.recovery_model_desc
FROM sys.databases d
WHERE d.database_id = DB_ID();

SELECT 'Schemas' AS info,
       s.name AS schema_name,
       s.schema_id
FROM sys.schemas s
ORDER BY s.name;

SELECT 'User tables and views' AS info,
       s.name AS schema_name,
       o.name AS object_name,
       o.object_id,
       o.type AS object_type,
       o.type_desc,
       t.temporal_type,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema_name,
       OBJECT_NAME(t.history_table_id) AS history_table_name,
       o.create_date,
       o.modify_date
FROM sys.objects o
LEFT JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.tables t ON o.object_id = t.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY s.name, o.name;

SELECT 'Columns of user tables and views' AS info,
       s.name AS schema_name,
       o.name AS object_name,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS user_type_name,
       TYPE_NAME(c.system_type_id) AS system_type_name,
       c.max_length,
       c.precision,
       c.scale,
       c.collation_name,
       c.is_nullable,
       c.is_identity,
       c.is_computed,
       c.is_sparse,
       c.is_column_set,
       c.is_hidden,
       c.generated_always_type,
       c.generated_always_type_desc
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY s.name, o.name, c.column_id;

SELECT 'Indexes' AS info,
       s.name AS schema_name,
       o.name AS object_name,
       i.name AS index_name,
       i.index_id,
       i.type_desc,
       i.is_unique,
       i.is_primary_key,
       i.is_unique_constraint,
       i.has_filter,
       i.filter_definition
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.indexes i ON o.object_id = i.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
  AND i.name IS NOT NULL
ORDER BY s.name, o.name, i.index_id;

SELECT 'Foreign keys' AS info,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema_name,
       OBJECT_NAME(fk.parent_object_id) AS parent_object_name,
       fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema_name,
       OBJECT_NAME(fk.referenced_object_id) AS referenced_object_name,
       fk.is_disabled,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.objects po ON fk.parent_object_id = po.object_id
JOIN sys.objects ro ON fk.referenced_object_id = ro.object_id
WHERE po.is_ms_shipped = 0
  AND ro.is_ms_shipped = 0
ORDER BY parent_schema_name, parent_object_name, fk.name;

SELECT 'Synonyms' AS info,
       s.name AS schema_name,
       syn.name AS synonym_name,
       syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
JOIN sys.objects o ON syn.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, syn.name;
