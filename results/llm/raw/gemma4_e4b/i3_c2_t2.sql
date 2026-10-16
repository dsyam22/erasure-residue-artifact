DECLARE @TargetName NVARCHAR(100) = 'Subject_0000042';
DECLARE @TargetEmail NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @TargetPhone NVARCHAR(50) = '+1-555-0000042';
DECLARE @CustomerInitialID INT = 42;

-- Temporary table to store the final results structure
SELECT 'dbo.customer' AS object_name, 0 AS rows_found
UNION ALL
SELECT 'dbo.member', 0
UNION ALL
SELECT 'dbo.member_history', 0
UNION ALL
SELECT 'cdc.dbo_customer_CT', 0;

-- Use a temporary table to accumulate results and ensure only one final result set is returned
IF OBJECT_ID('tempdb..#VerificationResults') IS NOT NULL DROP TABLE #VerificationResults;
CREATE TABLE #VerificationResults (
    object_name NVARCHAR(256),
    rows_found INT
);

-- Insert all object names with initial count of 0
INSERT INTO #VerificationResults (object_name, rows_found) VALUES
('dbo.customer', 0),
('dbo.member', 0),
('dbo.member_history', 0),
('cdc.dbo_customer_CT', 0);

-- ===============================================
-- 1. Check dbo.customer (Primary table)
-- Searching by the specific combination of personal data
UPDATE #VerificationResults SET rows_found = COUNT(T1.*)
FROM dbo.customer AS T1
WHERE T1.full_name = @TargetName OR T1.email = @TargetEmail OR T1.phone = @TargetPhone
GROUP BY 1 -- Grouping by the object name to ensure we update the correct row
HAVING MAX(CASE WHEN full_name = @TargetName THEN 1 ELSE 0 END) +
           MAX(CASE WHEN email = @TargetEmail THEN 1 ELSE 0 END) +
           MAX(CASE WHEN phone = @TargetPhone THEN 1 ELSE 0 END) > 0;


-- ===============================================
-- 2. Check dbo.member (Primary table)
UPDATE #VerificationResults SET rows_found = COUNT(T1.*)
FROM dbo.member AS T1
WHERE T1.full_name = @TargetName OR T1.email = @TargetEmail OR T1.phone = @TargetPhone
GROUP BY 1
HAVING MAX(CASE WHEN full_name = @TargetName THEN 1 ELSE 0 END) +
           MAX(CASE WHEN email = @TargetEmail THEN 1 ELSE 0 END) +
           MAX(CASE WHEN phone = @TargetPhone THEN 1 ELSE 0 END) > 0;


-- ===============================================
-- 3. Check dbo.member_history (System-versioned history table)
UPDATE #VerificationResults SET rows_found = COUNT(T1.*)
FROM dbo.member_history AS T1
WHERE T1.full_name = @TargetName OR T1.email = @TargetEmail OR T1.phone = @TargetPhone
GROUP BY 1 -- Must match the object name 'dbo.member_history'
HAVING MAX(CASE WHEN full_name = @TargetName THEN 1 ELSE 0 END) +
           MAX(CASE WHEN email = @TargetEmail THEN 1 ELSE 0 END) +
           MAX(CASE WHEN phone = @TargetPhone THEN 1 ELSE 0 END) > 0;


-- ===============================================
-- 4. Check cdc.dbo_customer_CT (CDC Change Table)
-- We check the CDC table for residual presence of the unique identifier (ID=42), as checking content data is unreliable here.
UPDATE #VerificationResults SET rows_found = COUNT(T1.*)
FROM cdc.dbo_customer_CT AS T1
WHERE T1.[customer_id] = @CustomerInitialID
GROUP BY 1 -- Must match the object name 'cdc.dbo_customer_CT'


-- Final selection to ensure exactly one result set is returned and ordered for readability
SELECT object_name, rows_found FROM #VerificationResults ORDER BY CASE WHEN object_name LIKE 'dbo%' THEN 1 ELSE 2 END;

DROP TABLE #VerificationResults;
