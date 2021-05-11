-- :connect localhost
:setvar CHG  "511"
:setvar DISK ""
:setvar Database "Hospital_Py"

--  +--------+
--  | Backup |
--  +--------+
set nocount on
use tempdb
go
declare @DB sysname, @SQL nvarchar(max), @Count int, @chg nvarchar(10), @timestamp nvarchar(25), @LastPath nvarchar(520)
set @chg = '$(CHG)' 
set @LastPath = '$(DISK)'

select @timestamp = replace(replace(replace(replace(convert(nvarchar(25), getdate(), 121),'-',''),':',''),'.',''),' ','_');

if ISNULL(@LastPath,'') = ''
begin
	select top 1 @LastPath=substring(bmf.physical_device_name,1,charindex('_backup',bmf.physical_device_name,0))
	from   		msdb.dbo.backupmediafamily as bmf
	inner join 	msdb.dbo.backupset as bs on bmf.media_set_id = bs.media_set_id  
	where  		bs.type = 'D' and bs.database_name in ('$(Database)')
	order by 	backup_start_date desc;
end;

if object_id('Tempdb..#dbs') is not null drop table #dbs;
select name into #dbs from sys.databases where name in ('$(Database)') --and database_id > 4

select @Count = count(*) from #dbs;

while @Count > 0
	begin
		select top 1 @DB = name FROM #dbs
		--set @DB = 'RockOn' --remove.
		set @SQL = 'backup database ['+@DB+'] to disk = '''+@LastPath+@DB+'_backup_'+@timestamp+'_pre'+@chg+'.bak'' 
			with noformat, noinit, skip, norewind, nounload, compression
			--, encryption(algorithm = AES_256, server certificate = [BackupCertWithPK])
			, stats = 25;'
		--exec sp_executesql @SQL;
		print @SQL;
		delete from #dbs --where name = @DB; --uncomment
		select @Count = Count(*) from #dbs;
	end
if object_id('Tempdb..#dbs') is not null drop table #dbs;
go
/*
--  +-------------------+
--  | RESTORE / REPLACE |
--  +-------------------+
set nocount on;
declare @kill nvarchar(max) = '', @LastPath nvarchar(520), @chg
set @chg = '$(CHG)' 
set @LastPath = '$(DISK)'

if exists (select 1 from sys.dm_exec_sessions where database_id  = db_id('$(Database)'))
begin
	select 	@kill = @kill + 'KILL ' + convert(varchar(5), session_id) + ';'
	from	sys.dm_exec_sessions
	where 	database_id  = db_id('$(Database)')

	exec sp_executesql @kill;
end
go

if db_id(N'$(Database)') is not null
begin 
	alter database [$(Database)] set single_user with rollback immediate;
	drop database [$(Database)] end
else begin
	restore database [$(Database)] from disk = 'C:\Deployments\RockOn.bak' with replace, file = 1,  
	move N'RockOn' to N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\RockOn.mdf', 
	move N'RockOn_log' to N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\RockOn_log.ldf',  
	nounload, stats = 25
go
*/