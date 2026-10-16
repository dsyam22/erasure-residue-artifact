-- QUERY
SELECT
    [Operation],
    [Context],
    [AllocUnitName],
    COUNT_BIG(*) AS record_count
FROM sys.fn_dblog(NULL, NULL)
WHERE [AllocUnitName] LIKE N'%customer%'
GROUP BY [Operation], [Context], [AllocUnitName]
ORDER BY [AllocUnitName], [Operation], [Context];
