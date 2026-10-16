SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id   int = 42;
DECLARE @full_name   nvarchar(200) = N'Subject_0000042';
DECLARE @email       nvarchar(400) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(60)  = N'+1-555-0000042';

;WITH checks AS
(
    SELECT
        N'dbo.customer' AS object_name,
        (SELECT COUNT(*)
         FROM dbo.customer
         WHERE customer_id = @customer_id
           AND (full_name = @full_name OR email = @email OR phone = @phone)) AS rows_found

    UNION ALL

    SELECT
        N'dbo.member',
        (SELECT COUNT(*)
         FROM dbo.member
         WHERE member_id = @member_id
           AND (full_name = @full_name OR email = @email OR phone = @phone))

    UNION ALL

    SELECT
        N'dbo.member_history',
        (SELECT COUNT(*)
         FROM dbo.member_history
         WHERE member_id = @member_id
           AND (full_name = @full_name OR email = @email OR phone = @phone))

    UNION ALL

    SELECT
        N'cdc.dbo_customer_CT',
        (SELECT COUNT(*)
         FROM cdc.dbo_customer_CT
         WHERE customer_id = @customer_id
           AND (full_name = @full_name OR email = @email OR phone = @phone))

    UNION ALL

    SELECT
        N'cdc.change_tables',
        (SELECT COUNT(*)
         FROM cdc.change_tables
         WHERE source_object_id = OBJECT_ID(N'dbo.customer')
           AND (capture_instance = @full_name OR capture_instance = @email OR capture_instance = @phone))

    UNION ALL

    SELECT
        N'cdc.captured_columns',
        (SELECT COUNT(*)
         FROM cdc.captured_columns
         WHERE column_name = @full_name OR column_name = @email OR column_name = @phone)

    UNION ALL

    SELECT
        N'cdc.ddl_history',
        (SELECT COUNT(*)
         FROM cdc.ddl_history
         WHERE ddl_command = @full_name OR ddl_command = @email OR ddl_command = @phone)

    UNION ALL

    SELECT
        N'cdc.index_columns',
        (SELECT COUNT(*)
         FROM cdc.index_columns
         WHERE column_name = @full_name OR column_name = @email OR column_name = @phone)

    UNION ALL

    SELECT
        N'cdc.lsn_time_mapping',
        (SELECT COUNT(*)
         FROM cdc.lsn_time_mapping
         WHERE tran_begin_time = TRY_CONVERT(datetime2, @full_name)
            OR tran_end_time   = TRY_CONVERT(datetime2, @email))

    UNION ALL

    SELECT
        N'sys.sql_modules',
        (SELECT COUNT(*)
         FROM sys.sql_modules
         WHERE definition LIKE N'%' + @full_name + N'%'
            OR definition LIKE N'%' + @email + N'%'
            OR definition LIKE N'%' + @phone + N'%')

    UNION ALL

    SELECT
        N'sys.columns',
        (SELECT COUNT(*)
         FROM sys.columns
         WHERE name = @full_name OR name = @email OR name = @phone)

    UNION ALL

    SELECT
        N'sys.tables',
        (SELECT COUNT(*)
         FROM sys.tables
         WHERE name = @full_name OR name = @email OR name = @phone)

    UNION ALL

    SELECT
        N'sys.objects',
        (SELECT COUNT(*)
         FROM sys.objects
         WHERE name = @full_name OR name = @email OR name = @phone)
)
SELECT object_name, rows_found
FROM checks
ORDER BY object_name;
