use Hospital_Py
go
ALTER PROCEDURE [dbo].[get_column_info] @input varchar(max)
AS 
BEGIN
	-- Create an empty table to store the serialized column information. 
	DROP TABLE IF EXISTS [dbo].[ColInfo]
	CREATE TABLE [dbo].[ColInfo](
		[info] [varbinary](max) NOT NULL
		)

	-- Serialize the column information. 
	DECLARE @database_name varchar(max) = db_name()
	INSERT INTO ColInfo
	EXECUTE sp_execute_external_script @language = N'Python',
     					               @script = N' 
from dill import dumps
from pandas import DataFrame

# TODO: replace with rxCreateColInfo once available
col_info = {"StatesStateCode": {"type": "factor", "levels":["AL", "DE", "FL", "GA", "HI", "IL", "IN", "MA", "MD", "MI", "MN", "NC", "NH", "NJ", "NY", "PA", "SC", "VA"]},
               "ClaimRoomsWithDamage": {"type": "integer"},
               "LossTypeDescription": {"type": "factor", "levels":["All Other Physical Damage", "Buried Utility Line", "Catastrophic Ground Cover Collapse", "Collapse", "Damage by Vehicle, Aircraft or Watercraft", "Dropped Objects", "Earthquake, Landslide & Earth Movement", "Explosion", "Fire", "Fire Department Service Charge", "Flood & Rising Water", "Freezing", "Fungi", "Glass Breakage", "Hail", "Liability", "Liability - Bodily Injury", "Liability - Property Damage", "Lightning", "Loss Assessment", "Open Perils", "Other", "Power Outage", "Riot & Civil Commotion", "Sinkhole", "Smoke", "Theft", "Vandalism & Malicious Mischief", "Water Damage", "Water Damage - Non Weather Related", "Water Damage - Weather Related", "Weight of Ice, Snow or Sleet", "Wind"]},
               "PolicyVersionAttributesFormType": {"type": "factor", "levels":["CP30", "DP1", "DP2", "DP3", "HO2", "HO3", "HO4", "HO5", "HO6", "HO8"]},
               "PolicyVersionAttributesOccupancyType": {"type": "factor", "levels":["Owner", "Tenant", "Unoccupied"]},
               "PolicyVersionAttributesCoverageA": {"type": "numeric"},
               "ClaimClaimID": {"type": "integer"},
               "ClaimReportedDate": {"type": "factor"},
               "ClaimDateClosed": {"type": "factor"},
               "lengthofstay": {"type": "numeric"},
               "ClaimClaimStatusID": {"type": "integer"},
               "ClaimStatusDescription": {"type": "factor"},
               "ClaimMoneyReserve": {"type": "numeric"},
               "ClaimMoneyLosses": {"type": "numeric"},
               "ClaimMoneyLAE": {"type": "numeric"}}

OutputDataSet = DataFrame({"payload": dumps(col_info)}, index=[0])
'
, @params = N'@input varchar(max), @database_name varchar(max)'
, @input = @input
, @database_name = @database_name 
;
END
GO
