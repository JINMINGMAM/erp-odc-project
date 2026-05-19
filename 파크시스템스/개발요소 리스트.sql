SELECT max(a.WorkItemVer) as WorkItemVer,B.workitemname,max(a.workitemseq) as workitemseq --, max(b.UploadDateTime) AS UploadTime,b.UploadUserSeq ,C.USERNAME
  FROM _TWPKGWorkItemElement AS A                                   --factor    
       JOIN  _TWPKGWorkItem AS B ON A.WorkItemSeq = B.WorkItemSeq   --name
       left JOIN _TCAUSER AS C ON C.USERSEQ = B.UploadUserSeq
WHERE A.ElementTypeSeq = 290005  --select * from _tcaminor where majorseq = 290 and languageseq =1
AND  b.WorkItemName  like '파크시스템_%'
--and  a.ElementSeq = 72220099
and datediff(month,UploadDateTime,getdate())<=8
group by B.workitemname--,b.UploadUserSeq,C.USERNAME



select DISTINCT ElementSeq  FROM _TWPKGWorkItemElement AS A 
JOIN(SELECT max(a.WorkItemVer) as WorkItemVer,B.workitemname,max(a.workitemseq) as workitemseq --, max(b.UploadDateTime) AS UploadTime,b.UploadUserSeq ,C.USERNAME
  FROM _TWPKGWorkItemElement AS A                                   --factor    
       JOIN  _TWPKGWorkItem AS B ON A.WorkItemSeq = B.WorkItemSeq   --name
       left JOIN _TCAUSER AS C ON C.USERSEQ = B.UploadUserSeq
WHERE A.ElementTypeSeq = 290005  --select * from _tcaminor where majorseq = 290 and languageseq =1
AND  b.WorkItemName  like '파크시스템_%'
--and  a.ElementSeq = 72220099
and datediff(month,UploadDateTime,getdate())<=8
group by B.workitemname ) AS B ON B.WorkItemVer = A.WorkItemVer AND B.workitemseq = A.workitemseq
WHERE A.ElementTypeSeq = 290005 



SELECT * FROM _TCASQLSCRIPTS AS A

WHERE SqlScriptSeq IN (
72220187
,72220188
,72220192
,72220206
,72220207
,72220208
,72220209
,72220210
,72220211
,72220212
,72220213
,72220214
,72220215
,72220218
,72220220
,72220233
,72220234
,72220235
,72220236
,72220242
,72220243
,72220246
,72220249
,72220251
,72220253
,72220254
,72220255
,72220257
,72220258
,72220262
,72220263
,72220264
,72220271
,72220272
,72220277
,72220278
,72220280
,72220282
,72220283
,72220284
,72220285
,72220288
,72220289
,72220290
,72220291
,72220292
,72220293
,72220294
,72220297
,72220300
,72220301
,72220311
,72220312
,72220313
,72220314)