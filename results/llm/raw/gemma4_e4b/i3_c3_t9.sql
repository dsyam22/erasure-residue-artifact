DECLARE @subject_name NVARCHAR(256) = 'Subject_0000042';
DECLARE @subject_email NVARCHAR(128) = 'subject42@example.invalid';
DECLARE @subject_phone NVARCHAR(50) = '+1-555-0000042';

-- Check 1: dbo.customer (The source table where the data was deleted)
SELECT
    'dbo.customer' AS object_name,
    COUNT(1) AS rows_found
FROM
    dbo.customer
WHERE
    full_name = @subject_name
    AND email = @subject_email
    AND phone = @subject_phone

UNION ALL

-- Check 2: cdc.dbo_customer_CT (The CDC change table for the customer)
SELECT
    'cdc.dbo_customer_CT' AS object_name,
    COUNT(1) AS rows_found
FROM
    cdc.dbo_customer_CT
WHERE
    full_name = @subject_name
    AND email = @subject_email
    AND phone = @subject_phone

UNION ALL

-- Check 3: dbo.member (The source table where the data was deleted)
SELECT
    'dbo.member' AS object_name,
    COUNT(1) AS rows_found
FROM
    dbo.member
WHERE
    full_name = @subject_name
    AND email = @subject_email
    AND phone = @subject_phone

UNION ALL

-- Check 4: dbo.member_history (The temporal history table for the member)
SELECT
    'dbo.member_history' AS object_name,
    COUNT(1) AS rows_found
FROM
    dbo.member_history
WHERE
    full_name = @subject_name
    AND email = @subject_email
    AND phone = @subject_phone;
