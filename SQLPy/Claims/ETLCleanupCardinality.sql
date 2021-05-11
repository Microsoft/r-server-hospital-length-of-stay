select  distinct 
        irondef,
        facid 
from    LengthOfStayBak 
order by 1 asc

select  
        facid ,
        count(facid)
from    LengthOfStayBak 
group by facid
order by 1 asc

sp_help LengthOfStayBak

select  distinct 
        -- StatesStateCode,
        -- ClaimRoomsWithDamage,
        --  LossTypeDescription,        
        -- PolicyVersionAttributesFormType,
        -- PolicyVersionAttributesOccupancyType,
        -- PolicyVersionAttributesCoverageA,
        -- ClaimMoneyReserve,
        -- ClaimMoneyLosses,
        -- ClaimMoneyLAE,
        -- ClaimClaimStatusID,
        -- ClaimStatusDescription,
        'a'
 from LengthOfStay order by 1 asc

-- cleanup on isle 5.
update LengthOfStay set ClaimRoomsWithDamage = 0 where ClaimRoomsWithDamage in ('','-1') or ClaimRoomsWithDamage is null; 
select * from LengthOfStay where ClaimRoomsWithDamage = '4 o'
update LengthOfStay set ClaimRoomsWithDamage = '4+' where ClaimRoomsWithDamage = '4 o';
