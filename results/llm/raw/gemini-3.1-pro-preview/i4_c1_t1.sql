SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name nvarchar(128),
    rows_found int
);

INSERT INTO @Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

DECLARE @MemberSQL nvarchar(max);
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('dbo.member') AND temporal_type = 2)
BEGIN
    SET @MemberSQL = '
        SELECT ''dbo.member'', COUNT(*) 
        FROM dbo.member FOR SYSTEM_TIME ALL 
        WHERE full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
END
ELSE
BEGIN
    SET @MemberSQL = '
        SELECT ''dbo.member'', COUNT(*) 
        FROM dbo.member 
        WHERE full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
END

INSERT INTO @Results (object_name, rows_found)
EXEC sp_executesql @MemberSQL;

SELECT object_name, rows_found 
FROM @Results;
