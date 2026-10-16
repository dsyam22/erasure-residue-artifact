DECLARE @ObjectName sysname = 'dbo.customer';
-- Since the phone column was dropped from dbo.customer, checking for the specific value 
-- ('+1-555-0000042') in that field will fail at schema level. Therefore, no rows containing 
-- this data can exist under the current schema definition.
DECLARE @RowCount int = 0;

SELECT 
    @ObjectName AS object_name, 
    CAST(@RowCount AS INT) AS rows_found;
