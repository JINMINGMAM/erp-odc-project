select slipmstseq,count(1) as cnt
from _TACSlipFileUpload
group by slipmstseq 
order by count(1) desc

72220002

park_TACSlipFileUpload

CompanySeq
AttachFileSeq
AttachFileConst
SlipMstSeq
SlipSeq
FileSeq
LastUserSeq
LastDateTime

CompanySeq
AttachFileSeq
AttachFileNo
SlipMstSeq
SlipSeq
FileName
RealFilePathName
FileSize
AttachDateTime
LastUserSeq
LastDateTime

insert into park_TACSlipFileUpload
select 1,6,72220002,SlipMstSeq,SlipSeq,AttachFileSeq,LastUserSeq,LastDateTime
from _TACSlipFileUpload
 where slipmstseq =35060
 
 select  * from _tacslip where slipmstid = '20240205-0001' 

select * from _TACSlipFileUpload where  AttachFileSeq = 95827


 35121

    update park_TACSlipFileUpload
       set    FileSeq   =   101504
     where slipmstseq   =   35121


 select * from park_TACSlipFileUpload where slipmstseq =35121
 delete from park_TACSlipFileUpload where AttachFileSeq = 5
select * from _TACSlipFileUpload where slipmstseq =35121




select * from _tacslip where slipmstseq =35054

select  companyseq ,26+row_number()over(group by AttachFileSeq order by AttachFileSeqm,attachfileno),72220002,AttachFileSeq,LastUserSeq,LastDateTime
from (
select distinct AttachFileSeq from _TACSlipFileUpload
) as a 



select  companyseq,26+row_number()over(order by AttachFileConst)as seq,AttachFileConst,AttachFileSeq,SlipMstSeq,SlipSeq,LastUserSeq,LastDateTime
from 
(
select distinct companyseq,72220002 as AttachFileConst,AttachFileSeq,SlipMstSeq,SlipSeq,LastUserSeq,LastDateTime
from _TACSlipFileUpload) as  a 



update _TCOMCreateSeqMax
set maxseq = 6
from _TCOMCreateSeqMax
where tablename = 'park_TACSlipFileUpload'

select * from _TCOMCreateSeqMax
where tablename = 'park_TACSlipFileUpload'


select * from _tacslip where slipmstseq =31263