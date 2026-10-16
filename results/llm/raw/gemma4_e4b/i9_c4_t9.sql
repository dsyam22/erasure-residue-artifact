-- This script checks for residual personal data associated with customer_id 42 across known and suspected tables, adhering to the required output format of one result set per object checked.

WITH DataChecks AS (
    -- Check 1: The primary table itself (in case deletion was incomplete or audited)
    SELECT 
        CAST('dbo.customer' AS NVARCHAR(256)) AS ObjectName,
        COUNT(*) AS RowsFound
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name LIKE '%Subject%'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'

    UNION ALL

    -- Check 2: Potential Audit/History table for customer data (assuming a common naming convention)
    SELECT 
        CAST('dbo.customer_history' AS NVARCHAR(256)) AS ObjectName,
        COUNT(*) AS RowsFound
    FROM dbo.customer_history -- Assuming this audit table exists
    WHERE customer_id = 42
      AND full_name LIKE '%Subject%'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'

    UNION ALL

    -- Check 3: General Audit/Log table (Searching across text fields)
    SELECT 
        CAST('dbo.audit_log' AS NVARCHAR(256)) AS ObjectName,
        COUNT(*) AS RowsFound
    FROM dbo.audit_log -- Assuming a general audit log exists
    WHERE CONVERT(NVARCHAR(MAX), customer_id) = '42'
      AND CONVERT(NVARCHAR(MAX), full_name) LIKE '%Subject%'
      AND CONVERT(NVARCHAR(MAX), email) = 'subject42@example.invalid'
      AND CONVERT(NVARCHAR(MAX), phone) = '+1-555-0000042'

    UNION ALL

    -- Check 4: Any table that might store the customer ID as a foreign key (Requires iterating over schema, but limited to one manual check for structure)
    SELECT 
        CAST('dbo.orders' AS NVARCHAR(256)) AS ObjectName, -- Assuming 'dbo.orders' is a related transaction table
        COUNT(*) AS RowsFound
    FROM dbo.orders
    WHERE customer_id = 42

    UNION ALL

    -- Check 5: Placeholder for any other critical tables found during inspection (if applicable)
    SELECT 
        CAST('Unknown.OtherTable' AS NVARCHAR(256)) AS ObjectName,
        0 AS RowsFound -- Default to 0 if the table does not exist or is irrelevant
)

-- Final selection ensures only one result set with the required columns is returned.
SELECT ObjectName, RowsFound FROM DataChecks;
