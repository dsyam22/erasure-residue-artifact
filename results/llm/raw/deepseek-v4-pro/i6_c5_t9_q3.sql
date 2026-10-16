-- QUERY
SELECT name, type_desc
FROM sys.objects
WHERE type IN ('P', 'V', 'FN', 'IF', 'TF', 'TR')
  AND is_ms_shipped = 0;
