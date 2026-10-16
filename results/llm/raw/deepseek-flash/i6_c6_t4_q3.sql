-- QUERY
SELECT o.name AS object_name, o.type_desc
FROM sys.objects o
WHERE o.type IN ('P','FN','IF','TF','TR','V')
  AND OBJECT_DEFINITION(o.object_id) LIKE N'%+1-555-0000042%';
