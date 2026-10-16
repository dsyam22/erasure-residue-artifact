SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check system tables for any residual data (e.g., change tracking, replication, etc.)
-- Since CDC is disabled and table is non-temporal, we check common system locations.

-- Check sys.dm_exec_query_stats for cached query plans containing the data (unlikely, but included for completeness)
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'sys.dm_exec_query_stats',
    COUNT(*)
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.text LIKE N'%' + @full_name + N'%'
   OR st.text LIKE N'%' + @email + N'%'
   OR st.text LIKE N'%' + @phone + N'%';

-- Check sys.dm_exec_requests for currently running queries that might reference the data
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'sys.dm_exec_requests',
    COUNT(*)
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE st.text LIKE N'%' + @full_name + N'%'
   OR st.text LIKE N'%' + @email + N'%'
   OR st.text LIKE N'%' + @phone + N'%';

-- Check sys.dm_exec_connections for connection attributes (unlikely to contain PII, but included)
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'sys.dm_exec_connections',
    COUNT(*)
FROM sys.dm_exec_connections AS c
WHERE c.client_net_address LIKE N'%' + @phone + N'%'
   OR c.client_net_address LIKE N'%' + @email + N'%';

-- Check sys.dm_exec_sessions for session context that might contain PII
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'sys.dm_exec_sessions',
    COUNT(*)
FROM sys.dm_exec_sessions AS s
WHERE s.host_name LIKE N'%' + @full_name + N'%'
   OR s.program_name LIKE N'%' + @full_name + N'%'
   OR s.login_name LIKE N'%' + @email + N'%';

-- Check sys.dm_db_partition_stats for any residual data in partitions (not directly PII, but included)
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'sys.dm_db_partition_stats',
    COUNT(*)
FROM sys.dm_db_partition_stats AS ps
WHERE ps.object_id = OBJECT_ID(N'dbo.customer');

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
