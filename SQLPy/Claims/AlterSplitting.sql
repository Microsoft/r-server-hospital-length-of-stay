Use Hospital_Py
go
ALTER PROCEDURE [dbo].[splitting]  @splitting_percent int = 70, @input varchar(max) 
AS
BEGIN

  DECLARE @sql nvarchar(max);
  SET @sql = N'
  DROP TABLE IF EXISTS Train_Id
  SELECT ClaimClaimID 
  INTO Train_Id
  FROM ' + @input + ' 
  WHERE ABS(CAST(BINARY_CHECKSUM(ClaimClaimID, NEWID()) as int)) % 100 < ' + Convert(Varchar, @splitting_percent);

  EXEC sp_executesql @sql
;
END
GO


