-- QUERY
SELECT N'object' AS item_type, s.name AS schema_name, o.name AS object_name,
       o.type_desc AS details
FROM sys.objects AS o
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
UNION ALL
SELECT N'internal_table', s.name, it.name, it.internal_type_desc
FROM sys.internal_tables AS it
LEFT JOIN sys.schemas AS s ON s.schema_id = it.schema_id
UNION ALL
SELECT N'database', NULL, d.name,
       CONCAT(N'snapshot_isolation=', d.snapshot_isolation_state_desc,
              N'; read_committed_snapshot=', d.is_read_committed_snapshot_on,
              N'; recovery=', d.recovery_model_desc,
              N'; ADR=', d.is_accelerated_database_recovery_on)
FROM sys.databases AS d
WHERE d.database_id = DB_ID()
UNION ALL
SELECT N'change_tracking', OBJECT_SCHEMA_NAME(ct.object_id),
       OBJECT_NAME(ct.object_id), N'enabled'
FROM sys.change_tracking_tables AS ct
UNION ALL
SELECT N'fulltext', OBJECT_SCHEMA_NAME(fi.object_id),
       OBJECT_NAME(fi.object_id), N'enabled'
FROM sys.fulltext_indexes AS fi;
