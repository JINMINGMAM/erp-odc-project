             DECLARE @PJTStdResult       INT, 
            @ProfCostUnitKind   INT, 
            @CostYMFr           NCHAR(8), 
            @CostYMTo           NCHAR(8),
            @CostYM     nchar(6)


            select @CostYM  ='202212'

        SELECT @CostYMFr = @CostYM + N'01', @CostYMTo = @CostYM + N'31'
         
         SELECT  F.AccUnit                 , a.PJTSeq,
                        D.CCtrSeq               , ISNULL(D.PJTItemSeq, 0)               , 
                        A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)),     
                        N'1'                                         , ISNULL(A.HogiItemSeq, 0),b.MngDeptSeq,bb.cctrseq
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
            join _THROrgDeptCCtr as bb on bb.DeptSeq = b.MngDeptSeq and IsLast = '1'
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = 1
                   AND F.AccUnit        = 1
                  -- and bb.cctrseq = 5386


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
             ORDER BY CONVERT(INT,A.OrdLevel)


              SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,D.RevCCtrSeq
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
             ORDER BY CONVERT(INT,A.OrdLevel)


            
         SELECT         a.PJTSeq,
                        DD.SendCCtrSeq as SendCCtrSeq,
                        D.CCtrSeq as recCCtrSeq                  , 
                        A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)) as manhour,     
                        bb.cctrseq AS deptcctrseq,
                        dd.AllocSeq
         into #temp
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
            join _tdaemp as H ON H.EmpSeq = B.ResrcErpSeq AND H.CompanySeq = A.CompanySeq
            join _THROrgDeptCCtr as bb on bb.DeptSeq = H.DeptSeq and IsLast = '1'
            JOIN( SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,BB.SendCCtrSeq
                    FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                          JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                      AND A.CompanySeq = B.CompanySeq
                          JOIN _TESMPDProdCCtrAcc     AS c WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                       AND A.AllocSeq   = c.AllocSeq 
                          JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                                    AND A.AllocSeq    = BB.AllocSeq 
                    WHERE A.CompanySeq    = 1 
                      AND A.CostUnit      = 1     
                      AND A.CostKeySeq    = 132 
                      AND B.IsCommon      = N'0' --공통비 아닌 것     
                      AND B.IsNotUse      = N'0'  
                      AND c.DriverSeq     = 30
            ) AS DD ON DD.SendCCtrSeq = bb.cctrseq 
         WHERE A.WorkStartDate >= @CostYMFr
           AND A.WorkEndDate   <= @CostYMTo
           And A.CompanySeq     = 1
           AND F.AccUnit        = 1


    select * from #temp

    select reccctrseq,sum(manhour) AS DriverValue ,allocseq 
    into #result
    from #temp
    group by reccctrseq,allocseq


    select * from #result

        --INSERT INTO #DriverSUM(
        --           CompanySeq  , AllocSeq   , AccSerl    , RevCCtrSeq , DriverSeq , DriverValue)
            SELECT A.CompanySeq,A.AllocSeq  ,B.AccSerl   ,C.RevCCtrSeq,B.DriverSeq   ,
                   F.DriverValue
              FROM  _TESMPDProdAllocName        AS A WITH(NOLOCK)
                    JOIN _TESMPDProdCCtrAcc     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                 AND A.AllocSeq   = B.AllocSeq 
                    JOIN _TESMPDProdCCtrRev     AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                                 AND A.AllocSeq   = C.AllocSeq
                    --JOIN _TESMPCProdDriverSum   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                    --                                             AND A.CostUnit   = D.CostUnit
                    --                                             AND A.CostKeySeq = D.CostKeySeq
                    --                                             AND B.DriverSeq  = D.DriverSeq
                    --                                             AND C.RevCCtrSeq = D.CCtrSeq
                   --JOIN #AllocCCtr              AS E              ON E.CCtrSeq    = C.RevCCtrSeq --2023.03.31 hylim 미사용코스트센터 제외
                   JOIN #result AS F ON F.allocseq = c.AllocSeq AND F.reccctrseq  = C.RevCCtrSeq
             WHERE A.CostKeySeq     = 132
               AND A.CostUnit       = 1 
               AND A.IsCommon       = N'0'       --공통비
               AND A.SMAllocMeth    = 5509003   --자원동인법 
               AND A.CompanySeq     = 1 
               --AND B.DriverSeq      = B.Driverseq = 1318  -- hard coding for new driver 프로젝트공수_woowon
               and F.DriverValue>0



    drop table #temp
    drop table #result











