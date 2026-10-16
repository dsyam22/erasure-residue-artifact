-- QUERY
SELECT
    [Operation],
    [Context],
    [AllocUnitName],
    [Transaction ID],
    [RowLog Contents 0],
    [RowLog Contents 1],
    [RowLog Contents 2],
    [Log Record]
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'%customer%'
   OR [Operation] = N'LOP_DELETE_ROWS';
