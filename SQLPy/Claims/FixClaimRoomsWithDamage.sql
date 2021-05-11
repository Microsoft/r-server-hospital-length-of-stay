Use Hospital_Py
go 

SELECT [ClaimRoomsWithDamage]
FROM [Hospital_Py].[dbo].[LengthOfStay]
group by [ClaimRoomsWithDamage];

update [LengthOfStay] set [ClaimRoomsWithDamage] = '4' 
where [ClaimRoomsWithDamage] = '4+';

go

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_LengthOfStay
	(
	ClaimClaimID int NULL,
	ClaimReportedDate date NULL,
	ClaimDateClosed date NULL,
	LengthOfStay smallint NULL,
	ClaimClaimStatusID int NULL,
	ClaimStatusDescription varchar(50) NULL,
	StatesStateCode varchar(10) NULL,
	ClaimRoomsWithDamage smallint NULL,
	LossTypeDescription varchar(100) NULL,
	PolicyVersionAttributesFormType varchar(50) NULL,
	PolicyVersionAttributesOccupancyType varchar(100) NULL,
	PolicyVersionAttributesCoverageA float(53) NULL,
	ClaimMoneyReserve decimal(10, 2) NULL,
	ClaimMoneyLosses decimal(10, 2) NULL,
	ClaimMoneyLAE decimal(10, 2) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_LengthOfStay SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.LengthOfStay)
	 EXEC('INSERT INTO dbo.Tmp_LengthOfStay (ClaimClaimID, ClaimReportedDate, ClaimDateClosed, LengthOfStay, ClaimClaimStatusID, ClaimStatusDescription, StatesStateCode, ClaimRoomsWithDamage, LossTypeDescription, PolicyVersionAttributesFormType, PolicyVersionAttributesOccupancyType, PolicyVersionAttributesCoverageA, ClaimMoneyReserve, ClaimMoneyLosses, ClaimMoneyLAE)
		SELECT ClaimClaimID, ClaimReportedDate, ClaimDateClosed, LengthOfStay, ClaimClaimStatusID, ClaimStatusDescription, StatesStateCode, CONVERT(smallint, ClaimRoomsWithDamage), LossTypeDescription, PolicyVersionAttributesFormType, PolicyVersionAttributesOccupancyType, PolicyVersionAttributesCoverageA, ClaimMoneyReserve, ClaimMoneyLosses, ClaimMoneyLAE FROM dbo.LengthOfStay WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.LengthOfStay
GO
EXECUTE sp_rename N'dbo.Tmp_LengthOfStay', N'LengthOfStay', 'OBJECT' 
GO
CREATE CLUSTERED COLUMNSTORE INDEX length_cci ON dbo.LengthOfStay ON [PRIMARY]
GO
COMMIT
