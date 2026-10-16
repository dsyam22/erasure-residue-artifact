DECLARE @RowsFound INT;

SELECT 
    @RowsFound = COUNT(CASE WHEN T1.customer_id = 42 OR T1.full_name LIKE N'%Subject_0000042%' OR T1.email = N'subject42@example.invalid' OR T1.phone = N'+1-555-0000042' THEN 1 END)
FROM dbo.customer AS T1;

SELECT 
    N'dbo.customer' AS object_name, 
    ISNULL(@RowsFound, 0) AS rows_found;
