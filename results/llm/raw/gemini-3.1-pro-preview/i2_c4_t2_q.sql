SELECT t.name AS TableName, h.name AS HistoryTableName
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.name = 'customer' AND t.schema_id = SCHEMA_ID('dbo');
