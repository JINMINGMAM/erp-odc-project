select isnull(devusername,''),b.*,a.* from _tcapgm as a 
left join ACESITEDEVcommon.._TDVDeveloper as b on b.DevUserSeq = lastuserseq
where pgmseq in (
72220099
,72220098
,72220104
,72220103
,72220100
,72220102
,72220109
,72220106
,72220113
,72220116
,72220101
,72220108
,72220111
,72220112
,72220110
,72220126
,72220131
,72220129
,108220002
,72220115
,72220105)
order by pgmid

select isnull(username,''),b.*,a.* from _tcapgm as a 
left join _tcauser as b on b.lastuserseq = a.lastuserseq
where pgmseq in (
72220099
,72220098
,72220104
,72220103
,72220100
,72220102
,72220109
,72220106
,72220113
,72220116
,72220101
,72220108
,72220111
,72220112
,72220110
,72220126
,72220131
,72220129
,108220002
,72220115
,72220105)
order by pgmid





select * from _tcapgm 
where pgmid = 'FrmWBIMonthlyIncomeStatementA_park'


select * from _tcapgm 
where pgmid like 'FrmWBIMonthlyIncomeStatement%_park'
