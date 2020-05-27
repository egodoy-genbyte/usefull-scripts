declare @db_name nvarchar(100)

declare cursor_size_srv cursor for

SELECT name AS DBName
FROM sys.databases
where name not in ('tempdb','master','msdb','model')
ORDER BY Name;

OPEN cursor_size_srv

FETCH NEXT FROM cursor_size_srv INTO @db_name

WHILE (@@FETCH_STATUS=0)

BEGIN

exec ('declare @logname nvarchar(100)
USE [' + @db_name + ']
SELECT @logname = name FROM sys.database_files where type = 1
ALTER DATABASE ' + @db_name + ' SET RECOVERY SIMPLE
DBCC SHRINKFILE (@logname , 10, TRUNCATEONLY)
ALTER DATABASE ' + @db_name + ' SET RECOVERY FULL')

FETCH NEXT FROM cursor_size_srv INTO @db_name

END

CLOSE cursor_size_srv

DEALLOCATE cursor_size_srv