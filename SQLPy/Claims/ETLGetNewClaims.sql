/*ETL New Claims from Prod*/
Use Hospital_Py 
go
insert into [redacted].ClaimLengthOfStay
select * from [redacted].[redacted].Claim.ClaimLengthOfStay;

/*Archive LoS Claims*/
use hospital_py
go

declare @archive nvarchar(50), @archivecci nvarchar(50);

select @archive = 'LengthOfStay' + replace(replace(replace(replace(convert(nvarchar(25), getdate(), 121),'-',''),':',''),'.',''),' ','');
select @archivecci = 'cciLengthOfStay' + replace(replace(replace(replace(convert(nvarchar(25), getdate(), 121),'-',''),':',''),'.',''),' ','');

exec sp_rename N'LengthOfStay.length_cci', @archivecci, N'INDEX';   
exec sp_rename 'LengthOfStay', @archive;

select * into LengthOfStay
from [redacted].ClaimLengthOfStay
go 

create clustered columnstore index length_cci on LengthOfStay with (drop_existing = off);
go

