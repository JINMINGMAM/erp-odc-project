declare @max int 


select @max = MaxSeq
from _TCOMCreateSeqMax
where tablename = 'park_TACSlipFileUpload' 


select @max

insert into park_TACSlipFileUpload
select  companyseq,@max+row_number()over(order by AttachFileConst)as seq,AttachFileConst,SlipMstSeq,SlipSeq,AttachFileSeq,LastUserSeq,LastDateTime
from 
(
select distinct companyseq,72220002 as AttachFileConst,AttachFileSeq,SlipMstSeq,SlipSeq,LastUserSeq,LastDateTime
from _TACSlipFileUpload) as  a 
where not exists(select 1 from park_TACSlipFileUpload where SlipMstSeq = a.SlipMstSeq and  SlipSeq = a.SlipSeq)


select max(AttachFileSeq) from park_TACSlipFileUpload
/*
update _TCOMCreateSeqMax
set maxseq = 22844
from _TCOMCreateSeqMax
where tablename = 'park_TACSlipFileUpload'
*/

update PARKTESTcommon.._TCAAttachFileData
set AttachFileConstSeq = 72220002
from PARKTESTcommon.._TCAAttachFileData as a 
        join (select distinct AttachFileSeq from _TACSlipFileUpload) as b on b.AttachFileSeq = a.attachfileseq
where AttachFileConstSeq = 49820010



select a.AttachFileConstSeq 
from PARKTESTcommon.._TCAAttachFileData as a 
        join (select distinct AttachFileSeq from _TACSlipFileUpload) as b on b.AttachFileSeq = a.attachfileseq
where AttachFileConstSeq = 49820010




/*


_TCAAttachFileConst
_TCAAttachFileData
_TCAAttachFileServer

select * into backup_20240206_TCAAttachFileData from _TCAAttachFileData
_TCAAttachFileData


select count(1) from backup_20240206_TCAAttachFileData
select count(1) from _TCAAttachFileData


select * from _TCAAttachFileData where attachfileconstseq = 49820010
select * from _TCAAttachFileData where attachfileconstseq = 49820010

72220002


select * from _TCAAttachFileConst where rootpath like '%slip%'

select * from sysobjects where name like '%file%const%'

*/












select a.AttachFileConstSeq
from PARKTESTcommon.._TCAAttachFileData as a 
        join (select distinct AttachFileSeq from _TACSlipFileUpload) as b on b.AttachFileSeq = a.attachfileseq
where AttachFileConstSeq = 49820010

select a.AttachFileConstSeq,b.AttachFileSeq,a.attachfileseq
from PARKTESTcommon.._TCAAttachFileData as a 
     left  join (select distinct AttachFileSeq from _TACSlipFileUpload) as b on b.AttachFileSeq = a.attachfileseq
where AttachFileConstSeq = 49820010
and b.AttachFileSeq is null 



select count(1) from PARKTESTcommon.._TCAAttachFileData
where AttachFileConstSeq = 49820010

