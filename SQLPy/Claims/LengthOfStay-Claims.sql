:connect [redacted]
use [redacted] 
go
select top 10 c.ClaimNumber, c.ReportedDate, c.DateClosed, c.ClaimStatusID, cs.[Description] as Status, cm.*
from claim c
inner join ClaimStatus cs 
    on cs.ClaimStatusID = c.ClaimStatusID
inner join ClaimMoney cm
    on c.claimid = cm.claimid
where c.ReportedDate >= getdate()-365
and c.DateClosed is not null
and cs.[Description] = 'Closed'
and cm.Reserve = 0
go

use [redacted] 
go
with LoS as (
    select datediff(day, c.ReportedDate, c.DateClosed) as LenghOfStay
    from claim c
    inner join ClaimStatus cs 
        on cs.ClaimStatusID = c.ClaimStatusID
    inner join ClaimMoney cm
        on c.claimid = cm.claimid
    where c.ReportedDate >= getdate()-365
    and c.DateClosed is not null
    -- and cs.[Description] = 'Closed' -- get others too. withdrawn, denied, etc. (2, 9, 10, 11, 12)
    and c.ClaimStatusID in (2, 9, 10, 11, 12)
    and cm.Reserve = 0 -- not used at create. is 0 when actually closed.
) 
select min(LenghOfStay) as min, avg(LenghOfStay) as avg, max(LenghOfStay) as max 
from LoS

select c.reporteddate, c.dateclosed 
from claim c 
where datediff(day, c.ReportedDate, c.DateClosed) = 1207 
and c.createddate >= getdate()-60

/*
-- train on fields
Coverage A or C $$$
Losstype 
Formtype
PropertyState
Occupancy (tenant or owner)
Rooms with Damage

Split
train 2019 (70%) test 2019 (30%)
No worry about Quaters ie. hurricane season for now.
Internal Adj (AAC = Aldler) vs External Adj, run 2 models, should be faster if internal. 
If RepresentedClaim should take longer to close the claim, try without 2 seperate models at first. 
*/

use [redacted] 
go
select top 10 c.ClaimID, c.ReportedDate, c.DateClosed, c.ClaimStatusID, cs.[Description] as Status, 
                       s.StateCode, c.RoomsWithDamage, lt.Description as LossType, pva.FormType, pva.OccupancyType, pva.CoverageA,  cm.*
from claim c
inner join ClaimStatus cs 
    on cs.ClaimStatusID = c.ClaimStatusID
inner join ClaimMoney cm
    on c.claimid = cm.claimid
inner join LossType lt 
       on lt.LossTypeID = c.LossTypeID 
inner join InsuredEntity ie
       on ie.InsuredEntityID = c.InsuredEntityID 
inner join Addresses a 
       on a.AddressId = ie.PropertyAddressID 
inner join States s 
       on s.StateID = a.StateID 
inner join PolicyVersionAttributes pva 
       on pva.PolicyVersionID = c.PolicyVersionId 
where c.ReportedDate >= getdate()-365
and c.DateClosed is not null
and cs.[Description] = 'Closed'
and cm.Reserve = 0
go

Use [redacted]
go
drop view if exists Claim.ClaimLengthOfStay;
go
create view Claim.ClaimLengthOfStay
as 
    select  top 100000 
            c.ClaimID, 
            c.ReportedDate, 
            c.DateClosed, 
            datediff(day,c.ReportedDate,c.DateClosed) as LengthOfStay,
            c.ClaimStatusID, 
            cs.[Description] as Status, 
            s.StateCode, 
            c.RoomsWithDamage, 
            lt.Description as LossType, 
            pva.FormType, 
            pva.OccupancyType, 
            pva.CoverageA,  
            cm.Reserve,
            cm.Losses,
            cm.LAE

    from dbo.Claim c
    inner join ClaimStatus cs 
        on cs.ClaimStatusID = c.ClaimStatusID
    inner join dbo.ClaimMoney cm
        on c.claimid = cm.claimid
    inner join LossType lt 
        on lt.LossTypeID = c.LossTypeID 
    inner join InsuredEntity ie
        on ie.InsuredEntityID = c.InsuredEntityID 
    inner join Addresses a 
        on a.AddressId = ie.PropertyAddressID 
    inner join States s 
        on s.StateID = a.StateID 
    inner join PolicyVersionAttributes pva 
        on pva.PolicyVersionID = c.PolicyVersionId 
    where c.ReportedDate >= dateadd(year,-3,getdate())
    and c.DateClosed is not null
    and cs.[Description] = 'Closed'
    and cm.Reserve = 0
;
go
select top 10 * from Claim.ClaimLengthOfStay

:connect [redacted]
Use Hospital_Py
go 

drop table if exists [redacted].ClaimLengthOfStay;
go
create schema [redacted] authorization [dbo]
go 
create table [redacted].ClaimLengthOfStay (
    ClaimClaimID int, 
    ClaimReportedDate date, 
    ClaimDateClosed date, 
    ClaimLengthOfStay smallint, 
    ClaimClaimStatusID int, 
    ClaimStatusDescription varchar(50),
    StatesStateCode varchar(10), 
    ClaimRoomsWithDamage varchar(10), 
    LossTypeDescription varchar(100), 
    PolicyVersionAttributesFormType varchar(50), 
    PolicyVersionAttributesOccupancyType varchar(100), 
    PolicyVersionAttributesCoverageA float,  
    ClaimMoneyReserve decimal(10,2),
    ClaimMoneyLosses decimal(10,2),
    ClaimMoneyLAE decimal(10,2)
)
go 
Use Hospital_Py 
go
insert into [redacted].ClaimLengthOfStay
select * from [redacted].[redacted].Claim.ClaimLengthOfStay;