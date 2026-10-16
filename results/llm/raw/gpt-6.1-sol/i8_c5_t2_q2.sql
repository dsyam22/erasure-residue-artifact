-- QUERY
SELECT
    [Current LSN],
    [Operation],
    [Context],
    [AllocUnitName],
    [Transaction ID],
    [RowLog Contents 0],
    [RowLog Contents 1]
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'dbo.customer%'
   OR [Operation] = N'LOP_DELETE_ROWS';
