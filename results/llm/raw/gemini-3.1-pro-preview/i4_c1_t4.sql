SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

-- Check dbo.member (accounting for potential system-versioned temporal history)
DECLARE @IsTemporal BIT = 0;
SELECT @IsTemporal = 1 
FROM sys.tables 
WHERE object_id = OBJECT_ID('dbo.member') AND temporal_type = 2;

IF @IsTemporal = 1
BEGIN
    EXEC sp_executesql N'
    INSERT INTO #Results (object_name, rows_found)
    SELECT ''dbo.member'', COUNT(*)
    FROM dbo.member FOR SYSTEM_TIME ALL
    WHERE full_name = ''Subject_0000042''
       OR email = ''subject42@example.invalid''
       OR phone = ''+1-555-0000042'';'
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'dbo.member', COUNT(*)
    FROM dbo.member
    WHERE full_name = 'Subject_0000042'
       OR email = 'subject42@example.invalid'
       OR phone = '+1-555-0000042';
END

SELECT object_name, rows_found
FROM #Results;

DROP TABLE #Results;
