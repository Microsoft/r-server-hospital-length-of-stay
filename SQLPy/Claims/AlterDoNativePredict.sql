use Hospital_Py
go
ALTER   PROCEDURE [dbo].[do_native_predict]
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
	INSERT INTO [QueryClaim]
    SELECT *
    FROM [LengthOfStay]
    WHERE ClaimClaimID = @eid

--	Step 1: Replace the missing values with the mode and the mean. 
	exec [dbo].[fill_NA_mode_mean] @input = [QueryClaim], @output = 'LoS0_Prod'

-- Step 2: Feature Engineering. 
    exec [dbo].[feature_engineering]  @input = 'LoS0_Prod', @output = 'Los_Prod', @is_production = 1


    SET @start = GETDATE()

    -- Do real time scoring using native PREDICT clause
    SELECT [LengthOfStay_Pred]
    FROM PREDICT (MODEL = @nativeModel, DATA = [LoS_Prod] ) WITH ( LengthOfStay_Pred FLOAT ) p;

    SET @end = GETDATE()

    SET @elapsed = CONVERT(VARCHAR(max),(SELECT DATEDIFF(MICROSECOND,@start,@end)))

    PRINT 'Elapsed Time for 1 row scoring is : ' + @elapsed + ' microseconds.'
	TRUNCATE table QueryClaim 

END
GO
