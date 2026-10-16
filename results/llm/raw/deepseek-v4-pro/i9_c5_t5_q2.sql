-- QUERY
SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name;
