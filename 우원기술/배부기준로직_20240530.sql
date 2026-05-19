             DECLARE @PJTStdResult       INT, 
                     @ProfCostUnitKind   INT, 
                     @CostYMFr           NCHAR(8), 
                     @CostYMTo           NCHAR(8),
                     @CostYM             nchar(6)


            select @CostYM  ='202212'

        SELECT @CostYMFr = @CostYM + N'01', @CostYMTo = @CostYM + N'31'


 SELECT distinct D.deptseq,row_number()over(order by d.deptseq) as No
 into #temp      
      FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    --JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                    --                                             AND A.AllocSeq   = D.AllocSeq
                    JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                              AND A.AllocSeq    = BB.AllocSeq 
                    join _THROrgDeptCCtr as D on D.CCtrSeq = bb.SendCCtrSeq and IsLast = '1'
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30

select * from #temp

       
              CREATE TABLE #Tmp_CTE_OrgDept
    (
        DeptSeq         INT          ,
        UppDeptSeq      INT          ,
        Seq             INT          ,
        BegDate         NCHAR(8)     ,
        EndDate         NCHAR(8)     ,
        UMDeptLevel     INT          ,
        Remark          NVARCHAR(200),
        DispSeq         INT          ,
        OrgCd           NVARCHAR(50)
    )

                  CREATE TABLE #Tmp_CTE_OrgDeptRet
                  (ParentDeptSeq INT ,
                   SubDeptSeq    INT)


    declare @Serl int ,@deptseq int 


    select @Serl = 0 

         WHILE  (1=1)                                              
         BEGIN                                              
             SELECT TOP 1                                              
                    @Serl      = A.No  , 
                    @deptseq   = a.deptseq
               FROM #temp AS A                                                   
              WHERE No > @Serl     
                --AND DEPTSEQ = 6
              Order By No                                              
                                                          
              IF @@ROWCOUNT = 0 BREAK    




        insert into #Tmp_CTE_OrgDept
        exec _SWHROrgDeptHR 1,1,@deptseq,@CostYMTo

        insert into #Tmp_CTE_OrgDeptRet
        select @deptseq , deptseq
        from #Tmp_CTE_OrgDept

        delete from #Tmp_CTE_OrgDept
end

select * from #Tmp_CTE_OrgDept


select * from #Tmp_CTE_OrgDeptRet ORDER BY SubDeptSeq

/*

         SELECT B.ResrcErpSeq,WorkStartDate,HumanResSerl,TimeUnitSeq,H.DeptSeq,F.AccUnit                 , a.PJTSeq,
                        D.CCtrSeq               , ISNULL(D.PJTItemSeq, 0) as PJTItemSeq              , 
                        A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)) as ManHour--,     
                        --N'1'                                         , ISNULL(A.HogiItemSeq, 0)--,b.MngDeptSeq
                  FROM  _TPJTResultHumanRes       AS A WITH(NOLOCK)
                        JOIN _TPJTResource        AS B WITH(NOLOCK) ON A.ResrcSeq   = B.ResrcSeq  
                                                                   AND A.CompanySeq = B.CompanySeq 
                                                                   AND SMResrCType  = 7005001  --(인적자원인 것만)
                        JOIN _TPJTProject         AS D WITH(NOLOCK) ON A.PJTSeq     = D.PJTSeq  
                                                                   AND A.CompanySeq = D.CompanySeq
                        JOIN _TDABizUnit          AS F WITH(NOLOCK) ON D.BizUnit    = F.BizUnit  
                                                                   AND D.CompanySeq = F.CompanySeq
             LEFT OUTER JOIN _TPJTBaseTimeUnit    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq
                                                                   AND A.ProcUnitSeq= G.TimeUnitSeq
           -- join _THROrgDeptCCtr as bb on bb.DeptSeq = b.MngDeptSeq and IsLast = '1'
           join _tdaemp as H ON H.EmpSeq = B.ResrcErpSeq AND H.CompanySeq = A.CompanySeq
           join (select distinct SubDeptSeq from  #Tmp_CTE_OrgDeptRet) AS CC ON CC.SubDeptSeq = H.DeptSeq
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = 1
                   AND F.AccUnit        = 1
                   order by B.ResrcErpSeq


                   select a.ParentDeptSeq,a.SubDeptSeq ,isnull(b.CCtrSeq,0) as CCtrSeq,isnull(manhour,0) as  manhour
from #Tmp_CTE_OrgDeptRet  as a 
left join (         SELECT B.ResrcErpSeq,WorkStartDate,HumanResSerl,TimeUnitSeq,H.DeptSeq,F.AccUnit                 , a.PJTSeq,
                        D.CCtrSeq               , ISNULL(D.PJTItemSeq, 0) as    PJTItemSeq            , 
                        A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)) as manhour--,     
                       -- N'1'                                         --, ISNULL(A.HogiItemSeq, 0)--,b.MngDeptSeq
                  FROM  _TPJTResultHumanRes       AS A WITH(NOLOCK)
                        JOIN _TPJTResource        AS B WITH(NOLOCK) ON A.ResrcSeq   = B.ResrcSeq  
                                                                   AND A.CompanySeq = B.CompanySeq 
                                                                   AND SMResrCType  = 7005001  --(인적자원인 것만)
                        JOIN _TPJTProject         AS D WITH(NOLOCK) ON A.PJTSeq     = D.PJTSeq  
                                                                   AND A.CompanySeq = D.CompanySeq
                        JOIN _TDABizUnit          AS F WITH(NOLOCK) ON D.BizUnit    = F.BizUnit  
                                                                   AND D.CompanySeq = F.CompanySeq
             LEFT OUTER JOIN _TPJTBaseTimeUnit    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq
                                                                   AND A.ProcUnitSeq= G.TimeUnitSeq
           -- join _THROrgDeptCCtr as bb on bb.DeptSeq = b.MngDeptSeq and IsLast = '1'
           join _tdaemp as H ON H.EmpSeq = B.ResrcErpSeq AND H.CompanySeq = A.CompanySeq
           join (select distinct SubDeptSeq from  #Tmp_CTE_OrgDeptRet) AS CC ON CC.SubDeptSeq = H.DeptSeq
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = 1
                   AND F.AccUnit        = 1
                 ) as  b on b.DeptSeq = a.SubDeptSeq 
                 --group by a.ParentDeptSeq,b.CCtrSeq

*/


select a.ParentDeptSeq,isnull(b.CCtrSeq,0) as recCCtrSeq,sum(isnull(manhour,0)) as  manhour
into #result
from #Tmp_CTE_OrgDeptRet  as a 
left join (         SELECT B.ResrcErpSeq,WorkStartDate,HumanResSerl,TimeUnitSeq,H.DeptSeq,F.AccUnit                 , a.PJTSeq,
                        D.CCtrSeq               , ISNULL(D.PJTItemSeq, 0) as    PJTItemSeq            , 
                        A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)) as manhour--,     
                       -- N'1'                                         --, ISNULL(A.HogiItemSeq, 0)--,b.MngDeptSeq
                  FROM  _TPJTResultHumanRes       AS A WITH(NOLOCK)
                        JOIN _TPJTResource        AS B WITH(NOLOCK) ON A.ResrcSeq   = B.ResrcSeq  
                                                                   AND A.CompanySeq = B.CompanySeq 
                                                                   AND SMResrCType  = 7005001  --(인적자원인 것만)
                        JOIN _TPJTProject         AS D WITH(NOLOCK) ON A.PJTSeq     = D.PJTSeq  
                                                                   AND A.CompanySeq = D.CompanySeq
                        JOIN _TDABizUnit          AS F WITH(NOLOCK) ON D.BizUnit    = F.BizUnit  
                                                                   AND D.CompanySeq = F.CompanySeq
             LEFT OUTER JOIN _TPJTBaseTimeUnit    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq
                                                                   AND A.ProcUnitSeq= G.TimeUnitSeq
           -- join _THROrgDeptCCtr as bb on bb.DeptSeq = b.MngDeptSeq and IsLast = '1'
           join _tdaemp as H ON H.EmpSeq = B.ResrcErpSeq AND H.CompanySeq = A.CompanySeq
           join (select distinct SubDeptSeq from  #Tmp_CTE_OrgDeptRet) AS CC ON CC.SubDeptSeq = H.DeptSeq
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = 1
                   AND F.AccUnit        = 1
                 ) as  b on b.DeptSeq = a.SubDeptSeq 
                where b.cctrseq >0
                 group by a.ParentDeptSeq,b.CCtrSeq

    select * from #result

--보내는 코스트 센터 check data 
SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,BB.SendCCtrSeq
              FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    --JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                    --                                             AND A.AllocSeq   = D.AllocSeq
                    JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                              AND A.AllocSeq    = BB.AllocSeq 
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30

--받는 코스트 센터 check data 
SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,d.RevCCtrSeq
              FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                                 AND A.AllocSeq   = D.AllocSeq
                    --JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                    --                                                          AND A.AllocSeq    = BB.AllocSeq 
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30



 SELECT distinct e.reccctrseq
      FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    --JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                    --                                             AND A.AllocSeq   = D.AllocSeq
                    JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                              AND A.AllocSeq    = BB.AllocSeq 
                    join _THROrgDeptCCtr as D on D.CCtrSeq = bb.SendCCtrSeq and IsLast = '1'
                    join #result as e on e.parentdeptseq  = d.deptseq
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30
              -- order by e.reccctrseq,deptseq


 SELECT A.AllocSeq,D.deptseq,manhour,bb.SendCCtrSeq,e.reccctrseq
      into #result2
      FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    --JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                    --                                             AND A.AllocSeq   = D.AllocSeq
                    JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                              AND A.AllocSeq    = BB.AllocSeq 
                    join _THROrgDeptCCtr as D on D.CCtrSeq = bb.SendCCtrSeq and IsLast = '1'
                    join #result as e on e.parentdeptseq  = d.deptseq
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30
               order by e.reccctrseq,deptseq


               select * from #result2

SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,d.RevCCtrSeq,sum(isnull(manhour,0)) as drivervalue
              FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                    JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                AND A.CompanySeq = B.CompanySeq
                    JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                 AND A.AllocSeq   = c.AllocSeq 
                    JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                                 AND A.AllocSeq   = D.AllocSeq
                    left join #result2 as e on e.reccctrseq = d.RevCCtrSeq 
             WHERE A.CompanySeq    = 1 
               AND A.CostUnit      = 1     
               AND A.CostKeySeq    = 132 
               AND B.IsCommon      = N'0' --공통비 아닌 것     
               AND B.IsNotUse      = N'0'  
               AND c.DriverSeq     = 30

group by A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,d.RevCCtrSeq


drop table #result
drop table #temp
drop table #Tmp_CTE_OrgDept
drop table #Tmp_CTE_OrgDeptRet 
drop table #result2


