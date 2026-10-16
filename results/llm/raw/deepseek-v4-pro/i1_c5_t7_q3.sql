-- QUERY
SELECT name, type_desc, is_ms_shipped
FROM sys.objects
WHERE type IN ('U','V','SN','SO','TF','IF','FN')
ORDER BY type_desc, name;
