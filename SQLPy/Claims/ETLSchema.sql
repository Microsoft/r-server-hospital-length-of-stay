Use [redacted] --prod db
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

:connect [redacted] --dev
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
