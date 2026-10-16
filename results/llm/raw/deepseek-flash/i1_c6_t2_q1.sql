-- QUERY
SELECT TOP (100) name, type_desc
FROM sys.objects
WHERE type IN ('U','V','P','FN','IF','TF','TR')
ORDER BY name;
