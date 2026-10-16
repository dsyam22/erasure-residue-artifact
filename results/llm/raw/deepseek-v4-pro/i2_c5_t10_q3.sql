-- QUERY
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('datetime','datetime2','date','smalldatetime','time')
   OR COLUMN_NAME IN ('valid_from','valid_to','created_at','updated_at','modified_at')
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
