use Hospital_Py
go
ALTER PROCEDURE [dbo].[compute_stats]  @input varchar(max) = 'LengthOfStay'
AS
BEGIN

	-- Create an empty table that will store the Statistics. 
	DROP TABLE if exists [dbo].[Stats]
	CREATE TABLE [dbo].[Stats](
		[variable_name] [varchar](128) NOT NULL,
		[type] [varchar](30) NOT NULL,
		[mode] [varchar](30) NULL, 
		[mean] [float] NULL,
		[std] [float] NULL
	)
	-- Get the names and variable types of the columns to analyze.
		DECLARE @sql nvarchar(max);
		SELECT @sql = N'
		INSERT INTO Stats(variable_name, type)
		SELECT *
		FROM (SELECT COLUMN_NAME as variable_name, DATA_TYPE as type
			  FROM INFORMATION_SCHEMA.COLUMNS
	          WHERE TABLE_NAME = ''' + @input + ''' 
			  AND COLUMN_NAME NOT IN (''ClaimClaimID'', ''ClaimLengthOfStay'', ''LengthOfStay'', ''ClaimDateClosed'', ''ClaimReportedDate'')) as t ';
		EXEC sp_executesql @sql;

	-- Loops to compute the Mode for categorical variables.
		DECLARE @name1 NVARCHAR(100)
		DECLARE @getname1 CURSOR

		SET @getname1 = CURSOR FOR
		SELECT variable_name FROM [dbo].[Stats] WHERE type IN('varchar', 'nvarchar', 'int', 'smallint')
	
		OPEN @getname1
		FETCH NEXT
		FROM @getname1 INTO @name1
		WHILE @@FETCH_STATUS = 0
		BEGIN	

			DECLARE @sql1 nvarchar(max);
			SELECT @sql1 = N'
			UPDATE Stats
			SET Stats.mode = T.mode
			FROM (SELECT TOP(1) ' + @name1 + ' as mode, count(*) as cnt
						 FROM ' + @input + ' 
						 GROUP BY ' + @name1 + ' 
						 ORDER BY cnt desc) as T
			WHERE Stats.variable_name =  ''' + @name1 + '''';
            EXEC sp_executesql @sql1;

			FETCH NEXT
		    FROM @getname1 INTO @name1
		END
		CLOSE @getname1
		DEALLOCATE @getname1
		
	-- Loops to compute the Mean and Standard Deviation for continuous variables.
		DECLARE @name2 NVARCHAR(100)
		DECLARE @getname2 CURSOR

		SET @getname2 = CURSOR FOR
		SELECT variable_name FROM [dbo].[Stats] WHERE type IN('float', 'decimal') or variable_name = 'ClaimRoomsWithDamage'
	
		OPEN @getname2
		FETCH NEXT
		FROM @getname2 INTO @name2
		WHILE @@FETCH_STATUS = 0
		BEGIN	

			DECLARE @sql2 nvarchar(max);
			SELECT @sql2 = N'
			UPDATE Stats
			SET Stats.mean = T.mean,
				Stats.std = T.std
			FROM (SELECT  AVG(' + @name2 + ') as mean, STDEV(' + @name2 + ') as std
				  FROM ' + @input + ') as T
			WHERE Stats.variable_name =  ''' + @name2 + '''';
			EXEC sp_executesql @sql2;

			FETCH NEXT
		    FROM @getname2 INTO @name2
		END
		CLOSE @getname2
		DEALLOCATE @getname2

END
GO
