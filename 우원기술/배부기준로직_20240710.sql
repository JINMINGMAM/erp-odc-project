             DECLARE @CostYMFr           NCHAR(8), 
                     @CostYMTo           NCHAR(8),
                     @CostYM             nchar(6),
                     @CostKeySeq         INT ,
                     @CompanySeq         INT 

            select @CostYM  ='202404'
            select @CostKeySeq = CostKeySeq
            from _TESMDCostKey		
            WHERE CostYM = @CostYM

            SELECT @CompanySeq = 1

        SELECT @CostYMFr = @CostYM + N'01', @CostYMTo = @CostYM + N'31'
         


                  SELECT -- F.AccUnit                 , a.PJTSeq,
                        --D.CCtrSeq               , ISNULL(D.PJTItemSeq, 0)               , 
                       d.PJTName,b.MngDeptSeq,A.*, A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1))    
                        --N'1'                                         , ISNULL(A.HogiItemSeq, 0),b.MngDeptSeq,bb.cctrseq
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
           Left join _THROrgDeptCCtr as bb on bb.DeptSeq = b.MngDeptSeq and IsLast = '1'
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = 1
                   AND F.AccUnit        = 1
                   and bb.DeptSeq is null
                  -- and bb.cctrseq = 5386



            
         SELECT F.AccUnit,                 
                a.PJTSeq,
                D.CCtrSeq as RecCCtrSeq               , 
                ISNULL(D.PJTItemSeq, 0)    AS     PJTItemSeq        , 
                A.ManHour * (ISNULL(G.ConvNum,1)/ISNULL(G.ConvDen,1)) AS ManHour,     
               ISNULL(A.HogiItemSeq, 0) AS HogiItemSeq,
                B.MngDeptSeq,
                BB.cctrseq AS Hrcctrseq,
                DD.AllocSeq ,
                DD.AccSerl
         INTO #DriverResult_woowon         
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
            JOIN _TDAEmp as H ON H.EmpSeq = B.ResrcErpSeq AND H.CompanySeq = A.CompanySeq
            JOIN _THROrgDeptCCtr as bb on bb.DeptSeq = H.DeptSeq and IsLast = '1'
            JOIN( SELECT A.AllocSeq,B.SMAllocMeth,A.CostKeySeq,c.DriverSeq,BB.SendCCtrSeq,C.AccSerl
                    FROM _TESMPDProdAllocOrd          AS A WITH(NOLOCK)
                          JOIN _TESMPDProdAllocName   AS B WITH(NOLOCK) ON A.AllocSeq   = B.AllocSeq
                                                                      AND A.CompanySeq = B.CompanySeq
                          JOIN _TESMPDProdCCtrAcc     AS C WITH(NOLOCK) ON A.CompanySeq = c.CompanySeq
                                                                       AND A.AllocSeq   = c.AllocSeq 
                          --JOIN _TESMPDProdCCtrRev     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                          --                                             AND A.AllocSeq   = D.AllocSeq
                          JOIN _TESMPDProdCCtrSend            AS BB WITH (NOLOCK) ON A.CompanySeq  =BB.CompanySeq 
                                                                                    AND A.AllocSeq    = BB.AllocSeq 
                   WHERE A.CompanySeq    = @CompanySeq 
                     AND A.CostUnit      = 1     
                     AND A.CostKeySeq    = @CostKeySeq 
                     AND B.IsCommon      = N'0' --공통비 아닌 것     
                     AND B.IsNotUse      = N'0'  
                     AND c.DriverSeq     = 318
            ) AS DD ON DD.SendCCtrSeq = BB.cctrseq
                 WHERE A.WorkStartDate >= @CostYMFr
                   AND A.WorkEndDate   <= @CostYMTo
                   And A.CompanySeq     = @CompanySeq
                   AND F.AccUnit        = 1


    SELECT * FROM #DriverResult_woowon

    SELECT @CompanySeq AS CompanySeq ,A.AllocSeq,A.AccSerl,A.RecCCtrSeq,318 AS DriverSeq,sum(ManHour) AS DriverValue 
    FROM #DriverResult_woowon AS A 
         JOIN _TESMPDProdCCtrRev     AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND A.AllocSeq   = B.AllocSeq
                                                      AND B.RevCCtrSeq = A.RecCCtrSeq
   GROUP BY A.AllocSeq,A.AccSerl,A.RecCCtrSeq
    ORDER BY AllocSeq


        SELECT @CompanySeq AS CompanySeq ,A.AllocSeq,A.AccSerl,A.RecCCtrSeq,318 AS DriverSeq,sum(ManHour) AS DriverValue 
    FROM #DriverResult_woowon AS A 
         JOIN _TESMPDProdCCtrRev     AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND A.AllocSeq   = B.AllocSeq
                                                      AND B.RevCCtrSeq = A.RecCCtrSeq
    WHERE  A.AllocSeq = 512
   GROUP BY A.AllocSeq,A.AccSerl,A.RecCCtrSeq
    ORDER BY AllocSeq



    SELECT * FROM _TESMPDProdCCtrRev WHERE  AllocSeq = 512 

    --CompanySeq  , AllocSeq   , AccSerl    , RevCCtrSeq , DriverSeq , DriverValue


    drop table #DriverResult_woowon







