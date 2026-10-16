-- QUERY
SELECT name, type_desc
FROM sys.objects
WHERE type IN ('U','V')
ORDER BY name;
