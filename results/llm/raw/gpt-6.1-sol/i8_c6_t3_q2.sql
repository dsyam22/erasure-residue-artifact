-- QUERY
SELECT name, recovery_model_desc, is_cdc_enabled,
       is_read_committed_snapshot_on
FROM sys.databases
WHERE database_id = DB_ID();

SELECT TOP (20)
       [Operation], [Context], [AllocUnitName],
       [Transaction ID], [RowLog Contents 0], [RowLog Contents 1]
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'%customer%'
ORDER BY [Current LSN] DESC;
