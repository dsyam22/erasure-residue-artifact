-- QUERY
SELECT TOP (5)
       [Operation], [Context], [AllocUnitName],
       [RowLog Contents 0], [RowLog Contents 1], [RowLog Contents 2]
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'dbo.customer%';
