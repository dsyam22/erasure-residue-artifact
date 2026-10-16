-- QUERY
SELECT TOP (10)
       [Operation], [Context], [AllocUnitName],
       [RowLog Contents 0], [RowLog Contents 1]
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'dbo.customer%'
  AND [Operation] IN (N'LOP_DELETE_ROWS', N'LOP_INSERT_ROWS', N'LOP_MODIFY_ROW')
ORDER BY [Current LSN] DESC;
