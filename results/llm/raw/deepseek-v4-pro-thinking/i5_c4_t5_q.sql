SELECT 'ALL_USER_OBJECTS' AS info_type,
       o.object_id,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name,
       o.type,
       o.type_desc,
       o.create_date,
       o.modify_date
FROM sys.objects o
WHERE o.is_ms_shipped = 0
ORDER BY o.type, OBJECT_SCHEMA_NAME(o.object_id), o.name;

SELECT 'TABLES_AND_VIEWS' AS info_type,
       o.object_id,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name,
       o.type_desc,
       t.temporal_type,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_table_schema,
       OBJECT_NAME(t.history_table_id) AS history_table_name,
       t.history_retention_period,
       t.history_retention_period_unit,
       t.history_retention_period_unit_desc,
       t.is_retention_enabled,
       t.is_memory_optimized,
       t.is_external,
       t.is_filetable,
       t.is_tracked_by_cdc,
       t.is_replicated,
       t.is_ledger,
       t.ledger_type_desc,
       t.ledger_view_id,
       OBJECT_NAME(t.ledger_view_id) AS ledger_view_name
FROM sys.objects o
LEFT JOIN sys.tables t ON t.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY o.type, OBJECT_SCHEMA_NAME(o.object_id), o.name;

SELECT 'COLUMNS' AS info_type,
       OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
       OBJECT_NAME(c.object_id) AS object_name,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.precision,
       c.scale,
       c.collation_name,
       c.is_nullable,
       c.is_identity,
       c.is_computed,
       c.generated_always_type,
       c.generated_always_type_desc,
       c.is_hidden,
       c.is_masked,
       c.masking_function,
       c.encryption_type,
       c.encryption_type_desc,
       c.encryption_algorithm_name,
       c.column_encryption_key_id,
       c.is_dropped_ledger_column,
       c.ledger_view_column_type
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY OBJECT_SCHEMA_NAME(c.object_id), OBJECT_NAME(c.object_id), c.column_id;

SELECT 'PERIODS' AS info_type,
       OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
       OBJECT_NAME(p.object_id) AS object_name,
       p.name AS period_name,
       p.period_type,
       p.period_type_desc,
       p.start_column_id,
       p.end_column_id
FROM sys.periods p
JOIN sys.objects o ON p.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(p.object_id), OBJECT_NAME(p.object_id), p.name;

SELECT 'COMPUTED_COLUMNS' AS info_type,
       OBJECT_SCHEMA_NAME(cc.object_id) AS schema_name,
       OBJECT_NAME(cc.object_id) AS object_name,
       cc.column_id,
       cc.name AS column_name,
       cc.definition,
       cc.is_persisted
FROM sys.computed_columns cc
JOIN sys.objects o ON cc.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(cc.object_id), OBJECT_NAME(cc.object_id), cc.column_id;

SELECT 'VIEW_DEFINITIONS' AS info_type,
       OBJECT_SCHEMA_NAME(v.object_id) AS schema_name,
       v.name AS view_name,
       OBJECT_DEFINITION(v.object_id) AS definition
FROM sys.views v
WHERE v.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(v.object_id), v.name;

SELECT 'TRIGGERS' AS info_type,
       OBJECT_SCHEMA_NAME(t.object_id) AS trigger_schema,
       t.name AS trigger_name,
       OBJECT_SCHEMA_NAME(t.parent_id) AS parent_schema,
       OBJECT_NAME(t.parent_id) AS parent_name,
       t.is_disabled,
       OBJECT_DEFINITION(t.object_id) AS definition
FROM sys.triggers t
WHERE t.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(t.object_id), t.name;

SELECT 'MODULES' AS info_type,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name,
       o.type_desc,
       m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P','FN','IF','TF','PC','AF','FS','FT','R')
ORDER BY o.type, OBJECT_SCHEMA_NAME(o.object_id), o.name;

SELECT 'SYNONYMS' AS info_type,
       OBJECT_SCHEMA_NAME(s.object_id) AS schema_name,
       s.name AS synonym_name,
       s.base_object_name
FROM sys.synonyms s
WHERE s.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(s.object_id), s.name;

SELECT 'FOREIGN_KEYS' AS info_type,
       fk.name AS foreign_key_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
       OBJECT_NAME(fk.parent_object_id) AS parent_table,
       c1.name AS parent_column,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
       OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
       c2.name AS referenced_column,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE fk.is_ms_shipped = 0
ORDER BY fk.name, fkc.constraint_column_id;

SELECT 'CHECK_CONSTRAINTS' AS info_type,
       OBJECT_SCHEMA_NAME(cc.object_id) AS schema_name,
       OBJECT_NAME(cc.object_id) AS table_name,
       cc.name AS constraint_name,
       cc.definition,
       cc.is_disabled
FROM sys.check_constraints cc
WHERE cc.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(cc.object_id), OBJECT_NAME(cc.object_id), cc.name;

SELECT 'DEFAULT_CONSTRAINTS' AS info_type,
       OBJECT_SCHEMA_NAME(dc.object_id) AS schema_name,
       OBJECT_NAME(dc.object_id) AS table_name,
       dc.name AS constraint_name,
       dc.definition
FROM sys.default_constraints dc
WHERE dc.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(dc.object_id), OBJECT_NAME(dc.object_id), dc.name;

SELECT 'INDEXES' AS info_type,
       OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS object_name,
       i.index_id,
       i.name AS index_name,
       i.type_desc,
       i.is_unique,
       i.is_primary_key,
       i.is_unique_constraint,
       i.has_filter,
       i.filter_definition,
       i.is_disabled
FROM sys.indexes i
JOIN sys.objects o ON i.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(i.object_id), OBJECT_NAME(i.object_id), i.index_id;

SELECT 'CHANGE_TRACKING_TABLES' AS info_type,
       OBJECT_SCHEMA_NAME(ctt.object_id) AS schema_name,
       OBJECT_NAME(ctt.object_id) AS table_name,
       ctt.is_track_columns_updated_on,
       ctt.min_valid_version,
       ctt.begin_version,
       ctt.cleanup_version
FROM sys.change_tracking_tables ctt
ORDER BY OBJECT_SCHEMA_NAME(ctt.object_id), OBJECT_NAME(ctt.object_id);

SELECT 'EXTERNAL_TABLES' AS info_type,
       OBJECT_SCHEMA_NAME(et.object_id) AS schema_name,
       OBJECT_NAME(et.object_id) AS object_name,
       et.data_source_id,
       eds.name AS data_source_name,
       et.location
FROM sys.external_tables et
JOIN sys.external_data_sources eds ON et.data_source_id = eds.data_source_id
JOIN sys.objects o ON et.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(et.object_id), OBJECT_NAME(et.object_id);

SELECT 'COLUMN_ENCRYPTION_KEYS' AS info_type,
       cek.name,
       cek.column_encryption_key_id,
       cek.create_date,
       cek.modify_date
FROM sys.column_encryption_keys cek;

SELECT 'SENSITIVITY_CLASSIFICATIONS' AS info_type,
       OBJECT_SCHEMA_NAME(sc.major_id) AS schema_name,
       OBJECT_NAME(sc.major_id) AS object_name,
       c.name AS column_name,
       sc.label,
       sc.label_id,
       sc.information_type,
       sc.information_type_id,
       sc.rank,
       sc.rank_desc
FROM sys.sensitivity_classifications sc
LEFT JOIN sys.columns c ON sc.major_id = c.object_id AND sc.minor_id = c.column_id
ORDER BY OBJECT_SCHEMA_NAME(sc.major_id), OBJECT_NAME(sc.major_id), c.column_id;
