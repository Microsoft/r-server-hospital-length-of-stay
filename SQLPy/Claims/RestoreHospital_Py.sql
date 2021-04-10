USE [master]
ALTER DATABASE [Hospital_Py] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [Hospital_Py] FROM  DISK = N'\\NAS\share\Deployments\Hospital_Py_backup_2021_03_07_190008_9538659.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5
RESTORE DATABASE [Hospital_Py] FROM  DISK = N'\\NAS\share\Deployments\Hospital_Py_backup_2021_03_10_190004_7063343.dif' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
go
ALTER DATABASE [Hospital_Py] SET MULTI_USER

GO


