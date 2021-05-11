use Hospital_Py
go
-- Stored Procedure to use native scoring for RF model (rxDForest implementation) for a single new case

-- @eid: specify the patient id to retrive record and score, ie. 1234, 1235, 9999

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE or alter PROCEDURE [dbo].[do_native_predict] --1234
    @eid int
AS
BEGIN
    DECLARE @nativeModel VARBINARY(MAX)
    DECLARE @start DATETIME
    DECLARE @end DATETIME
    DECLARE @elapsed varchar(max)

    -- Get the native model from the models table
    SET @nativeModel = ( SELECT value FROM RTS WHERE id = 'RF')


    -- Get the patient record from a historical table using the eid
	INSERT INTO [QueryPatient]
    SELECT *
    FROM [LengthOfStay]
    WHERE eid = @eid

--	Step 1: Replace the missing values with the mode and the mean. 
	exec [dbo].[fill_NA_mode_mean] @input = [QueryPatient], @output = 'LoS0_Prod'

-- Step 2: Feature Engineering. 
    exec [dbo].[feature_engineering]  @input = 'LoS0_Prod', @output = 'Los_Prod', @is_production = 1


    SET @start = GETDATE()

    -- Do real time scoring using native PREDICT clause
    SELECT [LengthOfStay_Pred]
    FROM PREDICT (MODEL = @nativeModel, DATA = [LoS_Prod] ) WITH ( LengthOfStay_Pred FLOAT ) p;

    SET @end = GETDATE()

    SET @elapsed = CONVERT(VARCHAR(max),(SELECT DATEDIFF(MICROSECOND,@start,@end)))

    PRINT 'Elapsed Time for 1 row scoring is : ' + @elapsed + ' microseconds.'
	TRUNCATE table QueryPatient 

END
GO

drop table if exists dbo.QueryPatient;
go
/****** Object:  Table [dbo].[QueryPatient]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QueryPatient](
	[eid] [int] NOT NULL,
	[vdate] [date] NULL,
	[rcount] [varchar](2) NULL,
	[gender] [varchar](1) NULL,
	[dialysisrenalendstage] [varchar](1) NULL,
	[asthma] [varchar](1) NULL,
	[irondef] [varchar](1) NULL,
	[pneum] [varchar](1) NULL,
	[substancedependence] [varchar](1) NULL,
	[psychologicaldisordermajor] [varchar](1) NULL,
	[depress] [varchar](1) NULL,
	[psychother] [varchar](1) NULL,
	[fibrosisandother] [varchar](1) NULL,
	[malnutrition] [varchar](1) NULL,
	[hemo] [varchar](1) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[secondarydiagnosisnonicd9] [varchar](2) NULL,
	[discharged] [date] NULL,
	[facid] [varchar](1) NULL,
	[lengthofstay] [int] NULL
) ON [PRIMARY]
GO
