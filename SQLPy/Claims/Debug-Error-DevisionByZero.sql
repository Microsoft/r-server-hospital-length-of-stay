select CAST(1 as varchar(2)) 
               AS number_of_issues;

select CAST((CAST(hemo as int) + CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
			        CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) +
                    CAST(psychother as int) + CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) 
               AS number_of_issues
from LengthOfStayBak

select
		       (PolicyVersionAttributesCoverageA - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'PolicyVersionAttributesCoverageA'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'PolicyVersionAttributesCoverageA') AS PolicyVersionAttributesCoverageA
from LoS		       

from LengthOfStay

SELECT  ClaimClaimID, 
                ClaimReportedDate, 
                ClaimClaimStatusID, 
                ClaimStatusDescription, 
                StatesStateCode, 
                LossTypeDescription, 
                PolicyVersionAttributesFormType, 
                PolicyVersionAttributesOccupancyType, 			   
		       (PolicyVersionAttributesCoverageA - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'PolicyVersionAttributesCoverageA'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'PolicyVersionAttributesCoverageA') AS PolicyVersionAttributesCoverageA,
		       --(ClaimMoneyReserve - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyReserve'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyReserve') AS ClaimMoneyReserve,
		       (ClaimMoneyLosses - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyLosses'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyLosses') AS ClaimMoneyLosses,
		       (ClaimMoneyLAE - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyLAE'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'ClaimMoneyLAE') AS ClaimMoneyLAE,
		       --(ClaimRoomsWithDamage - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'ClaimRoomsWithDamage'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'ClaimRoomsWithDamage') AS ClaimRoomsWithDamage,
CAST(1 as varchar(2)) 
               AS number_of_issues,
			   ClaimDateClosed,
			   (CASE WHEN 0=0 THEN CAST(lengthofstay as float) else 'NULL as lengthofstay' end) 
	    FROM LoS