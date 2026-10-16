-- QUERY
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc
FROM sys.objects AS o
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT d.name, d.recovery_model_desc, d.is_cdc_enabled,
       d.is_broker_enabled
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT it.name, it.internal_type_desc, OBJECT_SCHEMA_NAME(it.parent_id) AS parent_schema,
       OBJECT_NAME(it.parent_id) AS parent_object
FROM sys.internal_tables AS it;

SELECT i.name, i.type_desc, i.is_disabled
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'dbo.customer');

SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS fulltext_installed,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
       HAS_PERMS_BY_NAME(NULL, 'SERVER', 'VIEW SERVER STATE') AS can_view_server_state;
