 /************************************************************
 설    명 - 분개전표입력(전자결재)  : 출력
 작 성 일 - 2021.09.01
 작 성 자 - 정구슬 
 수 정 자 - 김동현 2022.02.17 :: 그룹웨어 페이지에 숫자표기가 안 되는 경우가 있어 ISNULL처리.
            전자증빙 html 보내기 추가 김명남 20240806
************************************************************/
CREATE PROC dbo.woowon_SWACSlipGWPrintQuery
    @xmlDocument    NVARCHAR(MAX) ,
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    EXEC _SYMMETRICKeyOpen

    -- 서비스 마스타 등록 생성
     CREATE TABLE #BIZ_IN_DataBlock1 (WorkingTag NCHAR(1) NULL)
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#BIZ_IN_DataBlock1'

    DECLARE @MessageType        INT,
            @Results            NVARCHAR(300),
            @Status             INT, 
            @SlipMstSeq         INT,        
            @IsNotGW            NCHAR(1),
            @SlipSeq            INT 

    -- 조회조건            
    SELECT @SlipMstSeq      = ISNULL(SlipMstSeq ,   0),
           @IsNotGW         = ISNULL(IsNotGW    , N'')           
      FROM #BIZ_IN_DataBlock1 


    CREATE TABLE #Temp (Cnt         INT IDENTITY(0,1),
                        SlipMstSeq  INT)


    INSERT INTO #Temp (SlipMstSeq)
    SELECT DISTINCT ISNULL(SlipMstSeq, 0) --개인별전표조회 화면에서 출력시 SlipMstSeq를 여러개 가져오므로 Distinct 추가 by 유태우 2019.11.20
      FROM #BIZ_IN_DataBlock1 


    --===========================================================
    --차대 일치 여부 CHECK
    --===========================================================
    CREATE TABLE #CTE_Check (IDX_NO         INT IDENTITY(1,1),
                             DrAmt          DECIMAL(19,5),                         
                             CrAmt          DECIMAL(19,5))    
    
    INSERT INTO #CTE_Check (DrAmt, CrAmt)
    SELECT SUM(DrAmt), 
           SUM(CrAmt) 
      FROM _TACSlipRow AS A WITH(NOLOCK) 
      JOIN #Temp       AS B ON A.SlipMstSeq = B.SlipMstSeq
     WHERE CompanySeq = @CompanySeq
     GROUP BY A.SlipMstSeq

    DECLARE @CHECK_CNT INT

    SELECT @CHECK_CNT = COUNT(*) FROM #CTE_Check

    WHILE(@CHECK_CNT > 0)
    BEGIN
        -- 전표 중 차대가 일치 하지 않는 데이터가 하나라도 있으면 RETURN
        IF (SELECT DrAmt FROM #CTE_Check WHERE IDX_NO =@CHECK_CNT) 
           <> (SELECT CrAmt FROM #CTE_Check WHERE IDX_NO =@CHECK_CNT) 
        BEGIN 
             EXEC dbo._SWCOMMessage @MessageType OUTPUT,
                                    @Status      OUTPUT,
                                    @Results     OUTPUT,
                                    1282               , -- @1이(가) @2이면 @3을(를) @4 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1282)
                                    @LanguageSeq       ,
                                    325,   N'차대금액' ,
                                    69359, N'금액불일치', 
                                    9,     N'전표'     ,
                                    9578,  N'출력'             

            UPDATE #BIZ_IN_DataBlock1
               SET Status = @Status,
                   Result = @Results
              FROM #BIZ_IN_DataBlock1
             WHERE Status = 0
           

            SELECT Status, Result FROM #BIZ_IN_DataBlock1
            SELECT 0                                     -- 조회의 테이블 수를 맞춰주기 위해 0 SELECT 

            RETURN 

        END

        SELECT @CHECK_CNT  = @CHECK_CNT - 1
    END

    --======================
    -- 환경설정
    --======================
    DECLARE @NativeCurr         INT,
            @KORDecimal         INT,    
            @FORDecimal         INT,    
            @ExraDecimal        INT,
            @EnvValue           NVARCHAR(20),
            @PersonId           NVARCHAR(20),
            @Env4121            INT
            

    
    SELECT @NativeCurr  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 13   -- 자국통화
    SELECT @KORDecimal  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 15   -- 원화소수점자리수        
    SELECT @FORDecimal  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 14   -- 외화소수점자리수    
    SELECT @ExraDecimal = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 11   -- 환율소수점자리수     
    
    IF ISNULL(@KORDecimal ,0) = 0 SELECT @KORDecimal = 0  
    IF ISNULL(@FORDecimal ,0) = 0 SELECT @FORDecimal = 0    
    IF ISNULL(@ExraDecimal,0) = 0 SELECT @ExraDecimal = 0   

    
    SELECT @EnvValue = EnvValue     FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 17   -- 사업자번호 형태 환경설정에서 가져오기
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue, '') = ''     SELECT @EnvValue = ''
    SELECT @PersonId = EnvValue     FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 16   -- 주민등록번호 형태 환경설정에서 가져오기
    IF @@ROWCOUNT = 0 OR ISNULL(@PersonId, '') = ''     SELECT @PersonId = ''

    -- 환경설정 4121 전표 출력시 귀속부서/코스트센터 표현 방법 추가 by.sykim
    SELECT @Env4121 = EnvValue      FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 4121 -- 전표 출력시 귀속부서 / 코스트센터 표현 방법
    IF @@ROWCOUNT = 0 OR ISNULL(@Env4121, 0) = 0        SELECT @Env4121 = 4597001    -- 디폴트:귀속부서


    DECLARE @CurrDate           NCHAR(8),    
            @Cnt                INT,
            @MaxCnt             INT,            
            @ProductType        INT


    -- 제품구분
    SELECT @ProductType = (SELECT ProductType FROM _TCACompanyConfig WITH(NOLOCK) WHERE CompanySeq = @CompanySeq)
    SELECT @ProductType = ISNULL(@ProductType, 0)
    
    --============
    -- 출납정보
    --============
    CREATE TABLE #tempCash
    (
        CompanySeq      INT, 
        SlipSeq         INT, 
        CashDate        NCHAR(8),
        SMCashMethod    INT, 
        Serl            INT
    )
         
    INSERT INTO #tempCash (CompanySeq, SlipSeq, CashDate, SMCashMethod, Serl)
    SELECT C.CompanySeq, C.SlipSeq, C.CashDate, C.SMCashMethod, 1
      FROM #Temp AS A
            JOIN _TACSlipRow AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  AND B.SlipMstSeq = A.SlipMstSeq
            JOIN _TACCashOn  AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq AND C.SlipSeq    = B.SlipSeq


     
    CREATE TABLE #TACSlip(
           CompanySeq       INT,            
           SlipMstSeq       INT,             
           AccUnit          INT,                      
           SlipUnit         INT,                     
           AccDate          NCHAR(8),                     
           SlipNo           NVARCHAR(6),
           SlipKind         INT,              
           SlipKindName     NVARCHAR(100),           
           RegEmpSeq        INT,                  
           RegDeptSeq       INT,                  
           Remark           NVARCHAR(200),                     
           SMCurrStatus     INT,               
           AptDate          NCHAR(8),                   
           AptEmpSeq        INT,                  
           AptDeptSeq       INT,                 
           AptRemark        NVARCHAR(100),                   
           SMCheckStatus    INT,             

           CheckOrigin       INT,                
           IsSet            NCHAR(1),                 
           SetSlipNo        NVARCHAR(6),                  
           SetEmpSeq        INT,                 
           SetDeptSeq       INT,                   
           SlipMstID        NVARCHAR(30),                    
           SlipAppNo        NVARCHAR(30),         
           RegAccDate       NCHAR(8),     
           RegDateTime      DATETIME)
               
    INSERT INTO #TACSlip(
           CompanySeq,            
           SlipMstSeq,        -- 전표마스터코드            
           AccUnit,           -- 회계단위            
           SlipUnit,          -- 전표관리단위            
           AccDate,           -- 회계일            
           SlipNo,            -- 기표일련번호            
           SlipKind,          -- 전표구분       
           SlipKindName,           
           RegEmpSeq,         -- 기표자            
           RegDeptSeq,        -- 기표부서            
           Remark,            -- 비고            
           SMCurrStatus,      -- 접수상태            
           AptDate,           -- 접수일            
           AptEmpSeq,         -- 접수자            
           AptDeptSeq,        -- 접수부서            
           AptRemark,         -- 접수비고            
           SMCheckStatus,     -- 정정상태            
           CheckOrigin,       -- 원천번호            
           IsSet,             -- 승인여부      
           SetSlipNo,         -- 승인일련번호            
           SetEmpSeq,         -- 승인자            
           SetDeptSeq,        -- 승인부서            
           SlipMstID,         -- 전표기표번호            
           SlipAppNo, -- 전표번호            
           RegAccDate,     -- 기표번호
           RegDateTime)
     
    SELECT A.CompanySeq,            
           A.SlipMstSeq,        -- 전표마스터코드            
           A.AccUnit,           -- 회계단위            
           A.SlipUnit,          -- 전표관리단위            
           A.AccDate,           -- 회계일            
           A.SlipNo,            -- 기표일련번호            
           A.SlipKind,          -- 전표구분       
           B.SlipKindName,           
           A.RegEmpSeq,         -- 기표자            
           A.RegDeptSeq,        -- 기표부서            
           A.Remark,            -- 비고            
           A.SMCurrStatus,      -- 접수상태            
           A.AptDate,           -- 접수일            
           A.AptEmpSeq,         -- 접수자            
           A.AptDeptSeq,        -- 접수부서            
           A.AptRemark,         -- 접수비고            
           A.SMCheckStatus,     -- 정정상태            
           A.CheckOrigin,       -- 원천번호            
           A.IsSet,             -- 승인여부      
           A.SetSlipNo,         -- 승인일련번호            
           A.SetEmpSeq,         -- 승인자            
           A.SetDeptSeq,        -- 승인부서            
           A.SlipMstID,         -- 전표기표번호            
           CASE WHEN A.IsSet = '1' THEN ISNULL(A.SetSlipID, '')
                ELSE '' END AS SlipAppNo, -- 전표번호            
           A.RegAccDate,     -- 기표번호
           A.RegDateTime     -- 전표등록일자
      FROM _TACSlip AS A WITH (NOLOCK)    
                      JOIN #Temp        AS C ON A.SlipMstSeq = C.SlipMstSeq   
           LEFT OUTER JOIN _TACSlipKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SlipKind = B.SlipKind      
     WHERE A.CompanySeq = @CompanySeq    


    CREATE TABLE #Result_tmp(          
           SlipMstSeq       INT,             
           AccUnit          INT,                      
           SlipUnit         INT,                     
           AccDate          NCHAR(8),                     
           SlipNo           NVARCHAR(6),
           SlipKind         INT,              
           SlipKindName     NVARCHAR(100),           
           RegEmpSeq        INT,                  
           RegDeptSeq       INT,                  
           Remark           NVARCHAR(200),                     
           SMCurrStatus     INT,               
           AptDate          NCHAR(8),                   
           AptEmpSeq        INT,                  
           AptDeptSeq       INT, 
           AptRemark        NVARCHAR(100),                  
           SMCheckStatus    INT,                 
           CheckOrigin      INT,              
           IsSet            NCHAR(1),                 
           SetSlipNo        NVARCHAR(30),                     
           SetEmpSeq        INT,                     
           SetDeptSeq       INT,                
           RegEmpName       NVARCHAR(100),                
           RegDeptName      NVARCHAR(100),              
           AptEmpName       NVARCHAR(100),                  
           AptDeptName      NVARCHAR(100),               
           SetEmpName       NVARCHAR(100),                
           SetDeptName      NVARCHAR(100),                
           SlipUnitName     NVARCHAR(100),
           SlipMstID        NVARCHAR(30),                          
           SlipAppNo        NVARCHAR(30),                             
           RegAccDate       NCHAR(8),    
           RegDateTime      DATETIME)
               
    INSERT INTO #Result_tmp(     
           SlipMstSeq,        -- 전표마스터코드            
           AccUnit,           -- 회계단위            
           SlipUnit,          -- 전표관리단위            
           AccDate,           -- 회계일            
           SlipNo,            -- 기표일련번호            
           SlipKind,          -- 전표구분       
           SlipKindName,           
           RegEmpSeq,         -- 기표자            
           RegDeptSeq,        -- 기표부서            
           Remark,            -- 비고            
           SMCurrStatus,      -- 접수상태            
           AptDate,           -- 접수일            
           AptEmpSeq,         -- 접수자            
           AptDeptSeq,        -- 접수부서            
           AptRemark,         -- 접수비고            
           SMCheckStatus,     -- 정정상태            
           CheckOrigin,       -- 원천번호            
           IsSet,             -- 승인여부      
           SetSlipNo,         -- 승인일련번호            
           SetEmpSeq,         -- 승인자            
           SetDeptSeq,        -- 승인부서 
           RegEmpName,        -- 기표자            
           RegDeptName,       -- 기표부서            
           AptEmpName,        -- 접수자            
           AptDeptName,       -- 접수부서            
           SetEmpName,        -- 승인자            
           SetDeptName,       -- 승인부서            
           SlipUnitName,      -- 전표관리단위            
           SlipMstID,         -- 전표기표번호            
           SlipAppNo,         -- 전표번호               
           RegAccDate,        -- 기표번호
           RegDateTime)

    SELECT A.SlipMstSeq,        -- 전표마스터코드            
           A.AccUnit,           -- 회계단위            
           A.SlipUnit,          -- 전표관리단위            
           A.AccDate,           -- 회계일            
           A.SlipNo,            -- 기표일련번호            
           A.SlipKind,          -- 전표구분         
           A.SlipKindName,      -- 전표구분         
           A.RegEmpSeq,         -- 기표자            
           A.RegDeptSeq,        -- 기표부서            
           A.Remark,            -- 비고            
           A.SMCurrStatus,      -- 접수상태            
           A.AptDate,           -- 접수일            
           A.AptEmpSeq,         -- 접수자            
           A.AptDeptSeq,        -- 접수부서            
           A.AptRemark,         -- 접수비고            
           A.SMCheckStatus,     -- 정정상태            
           A.CheckOrigin,       -- 원천번호            
           A.IsSet,             -- 승인여부            
           A.SetSlipNo,         -- 승인일련번호            
           A.SetEmpSeq,         -- 승인자            
           A.SetDeptSeq,        -- 승인부서            
           C.EmpName    AS RegEmpName,      -- 기표자            
           F.DeptName   AS RegDeptName,     -- 기표부서            
           D.EmpName    AS AptEmpName,      -- 접수자            
           G.DeptName   AS AptDeptName,     -- 접수부서            
           E.EmpName    AS SetEmpName,      -- 승인자            
           H.DeptName   AS SetDeptName,     -- 승인부서            
           I.SlipUnitName,                  -- 전표관리단위
           A.SlipMstID,               -- 전표기표번호            
           A.SlipAppNo,               -- 전표번호                    
           A.RegAccDate,    --기표번호
           A.RegDateTime    -- 전표등록일자
      FROM #TACSlip AS A
           LEFT OUTER JOIN _TDAEmp      AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.EmpSeq   = A.RegEmpSeq     -- 기표자
           LEFT OUTER JOIN _TDAEmp      AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.EmpSeq   = A.AptEmpSeq     -- 접수자
           LEFT OUTER JOIN _TDAEmp      AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.EmpSeq   = A.SetEmpSeq     -- 승인자
           LEFT OUTER JOIN _TDADept     AS F WITH(NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.DeptSeq  = A.RegDeptSeq    -- 기표부서
           LEFT OUTER JOIN _TDADept     AS G WITH(NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.DeptSeq  = A.AptDeptSeq    -- 접수부서
           LEFT OUTER JOIN _TDADept     AS H WITH(NOLOCK) ON H.CompanySeq = A.CompanySeq AND H.DeptSeq  = A.SetDeptSeq    -- 승인부서
           LEFT OUTER JOIN _TACSlipUnit AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq AND I.SlipUnit = A.SlipUnit      -- 전표관리단위


    -- 초기화면 띄울때는 다른 정보는 필요없으므로 빠져 나감 2009.01.12 by 홍기화            
    IF ISNULL(@SlipMstSeq,0) = 0
    BEGIN            
        SELECT 0 AS RowNum FROM _TDAAccUnit  WITH(NOLOCK)  WHERE 1 = 0            
        SELECT 0 AS RowIDX FROM _TDAAccUnit  WITH(NOLOCK)  WHERE 1 = 0            
        RETURN            
    END            
    ELSE            
    BEGIN
        CREATE TABLE #TempFixedCol(
               RowIDX           INT,                
               MaxIDX           INT,              
               SlipSeq          INT,                      
               SlipMstSeq       INT,                        
               SlipID           NVARCHAR(30),                          
               AccUnit          INT,                          
               SlipUnit         INT,                        
               AccDate          NCHAR(8),                         
               SlipNo           NVARCHAR(6),
               RowNo            NCHAR(4),                           
               RowSlipUnit      INT,                     
               AccSeq           INT,                           
               UMCostType       INT,                      
               SMDrOrCr         INT,                        
               DrAmt            DECIMAL(19,5),                         
               CrAmt            DECIMAL(19,5),                        
               DrForAmt         DECIMAL(19,5),                       
               CrForAmt         DECIMAL(19,5),                    
               CurrSeq          INT,                     
               ExRate           DECIMAL(19,5),                 
               DivExRate        DECIMAL(19,5),                  
               EvidSeq          INT,                        
               TaxKindSeq       INT,                   
               NDVATAmt         DECIMAL(19,5),                    
               CashItemSeq      INT,                   
               SMCostItemKind   INT,                
               CostItemSeq      INT,                  
               Summary          NVARCHAR(100),               
               BgtDeptSeq       INT,                
               BgtCCtrSeq       INT,                 
               BgtSeq           INT,                       
               IsSet            NCHAR(1),                      
               AccName          NVARCHAR(100),                   

               AccNo            NVARCHAR(20),                      
               CurrName         NVARCHAR(100),           
               CurrUnit         NVARCHAR(10),            
               EvidName         NVARCHAR(100),                 
               TaxKindName      NVARCHAR(100),                
               CashItemName     NVARCHAR(100),                
               SMCostItemKindName   NVARCHAR(100),        
               CostItemName     NVARCHAR(100),              
               BgtDeptName      NVARCHAR(100),               
               BgtCCtrName      NVARCHAR(100),              
               BgtName          NVARCHAR(100),                
               SMInOrOut        INT,            
               IsCash           NCHAR(1),                
               CashDate         NCHAR(8),                 
               SMCashMethod     INT,             
               CashOffSerl      INT,                
               OnSlipSeq        INT,            
               OnSlipID         NVARCHAR(30),            
               SMAccDrOrCr      INT,            
               IsAnti           NCHAR(1),            
               IsSlip           NCHAR(1),            
               IsLevel2         NCHAR(1),            
               IsZeroAllow      NCHAR(1),            
               IsEssForAmt      NCHAR(1),            
               SMIsEssEvid      INT,            
               IsEssCost        NCHAR(1),            
               IsCostTrn        NCHAR(1),            
               SMIsUseRNP       INT,            
               SMRNPMethod      INT,            
               SMBgtType        INT,            
               IsCashAcc        NCHAR(1),                  
               SMCashItemKind   INT,            
               IsFundSet        NCHAR(1),            
               IsAutoExec       NCHAR(1),            
               SMAccType        INT,            
               SMAccKind        INT,            
               OffRemSeq        INT,            
               BgtRemSeq        INT,            
               RemSeq1          INT,            
               RemSeq2          INT,            
               CostTypeCount    INT,            
               CoCustSeq        INT,                
               CoCustName       NVARCHAR(100),            
               SMCashMethodName NVARCHAR(100), 
               SumDrAmt         DECIMAL(19,5),  
               SumCrAmt         DECIMAL(19,5),  
               DrSumFirstFage   DECIMAL(19,5), 
               CrSumFirstFage   DECIMAL(19,5), 
               IsOnlyOnPage     INT,    
               CustSeq          INT, 
               S_AccUnitName    NVARCHAR(100), 
               TopUserName      NVARCHAR(100),
               EmpSeq           INT) 
               
    INSERT INTO #TempFixedCol(
               RowIDX,              -- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  
               MaxIDX,             -- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  
               SlipSeq,               -- 전표코드            
               SlipMstSeq,            -- 전표마스터코드            
               SlipID,                -- 전표기표번호            
               AccUnit,               -- 회계단위            
               SlipUnit,              -- 전표관리단위            
               AccDate,               -- 회계일            
               SlipNo,                -- 기표일련번호            
               RowNo,                 -- 행번호            
               RowSlipUnit,           -- 행별전표관리단위            
               AccSeq,                -- 계정코드            
               UMCostType,            -- 비용구분            
               SMDrOrCr,              -- 차대구분            
               DrAmt,                 -- 차변금액            
               CrAmt,                 -- 대변금액            
               DrForAmt,              -- 외화차변금액            

               CrForAmt,              -- 외화대변금액             
               CurrSeq,               -- 통화코드            
               ExRate,                -- 환율            
               DivExRate,             -- 나누기 환율            
               EvidSeq,               -- 증빙코드            
               TaxKindSeq,            -- 세무구분코드            
               NDVATAmt,              -- 불공제세액            
               CashItemSeq,           -- 현금흐름표과목코드            
               SMCostItemKind,        -- 원가항목유형            
               CostItemSeq,           -- 원가항목            
               Summary,           -- 적요            
               BgtDeptSeq,            -- 예산부서            
               BgtCCtrSeq,            -- 예산활동센터            
               BgtSeq,                -- 예산과목코드            
               IsSet,                 -- 승인여부            
               AccName,               -- 계정과목            
               AccNo,                 -- 계정번호            
               CurrName,            -- 통화코드  
               CurrUnit,            -- 통화표시단위
               EvidName,            -- 증빙코드            
               TaxKindName,         -- 세무구분코드            
               CashItemName,        -- 현금흐름표과목코드            
               SMCostItemKindName,  -- 원가항목유형            
               CostItemName,          -- 원가항목            
               BgtDeptName,         -- 예산부서            
               BgtCCtrName,         -- 예산활동센터            
               BgtName,             -- 예산과목코드            
               SMInOrOut,            
               IsCash,           -- 출납처리여부            
               CashDate,            -- 출납예정일            
               SMCashMethod,        -- 출납방법            
               CashOffSerl,         -- 출납지급정보 순번            
               OnSlipSeq,            
               OnSlipID,            
               SMAccDrOrCr,            
               IsAnti,            
               IsSlip,            
               IsLevel2,            
               IsZeroAllow,            
               IsEssForAmt,            
               SMIsEssEvid,            
               IsEssCost,            
               IsCostTrn,            
               SMIsUseRNP,            
               SMRNPMethod,            
               SMBgtType,            
               IsCashAcc,            
               SMCashItemKind,            
               IsFundSet,            
               IsAutoExec,            
               SMAccType,            
               SMAccKind,            
               OffRemSeq,            
               BgtRemSeq,            
               RemSeq1,            
               RemSeq2,            
               CostTypeCount,            
               CoCustSeq,    --관계회사코드            
               CoCustName,    --관계회사            
               SMCashMethodName  , 
               SumDrAmt,  
               SumCrAmt,  
               DrSumFirstFage, -- 일단0 바로아래서update한다.  
               CrSumFirstFage, -- 일단0 바로아래서update한다.  
               IsOnlyOnPage,    -- 일단 '' 바로 아래서 update한다.
               CustSeq, -- 거래처코드  , 출납정보에 거래처가 있을때 거래처 정보를 받기 위해 추가함.
               S_AccUnitName, -- 본지점계정이면서 반제전표(설정전표가 있는 경우)라면, 관리항목의 회계단위명도 보여주도록 수정
               TopUserName,
               EmpSeq) -- 사원코드, 출납정보에 사원이 있는 경우의 처리를 위해)

            
        --================================================================================================================================            
        -- 고정컬럼값 조회            
        --================================================================================================================================            
        SELECT --IDENTITY(INT, 0, 1)  AS RowIDX, 
               0 AS RowIDX,             -- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  
               0 AS MaxIDX,             -- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  

               A.SlipSeq,                -- 전표코드            
               A.SlipMstSeq,            -- 전표마스터코드            
               A.SlipID,                -- 전표기표번호            
               A.AccUnit,               -- 회계단위            
               A.SlipUnit,              -- 전표관리단위            
               A.AccDate,               -- 회계일            
               A.SlipNo,                -- 기표일련번호            
               A.RowNo,                 -- 행번호            
               A.RowSlipUnit,           -- 행별전표관리단위            
               A.AccSeq,                -- 계정코드            
               A.UMCostType,            -- 비용구분            
               A.SMDrOrCr,              -- 차대구분            
               A.DrAmt,                 -- 차변금액            
               A.CrAmt,                 -- 대변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.DrForAmt END AS DrForAmt,              -- 외화차변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CrForAmt END AS CrForAmt,              -- 외화대변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CurrSeq END AS CurrSeq,               -- 통화코드            
               A.ExRate,                -- 환율            
               A.DivExRate,             -- 나누기 환율            
               A.EvidSeq,               -- 증빙코드            
               0 AS TaxKindSeq,            -- 세무구분코드            
               CAST(0 AS DECIMAL(19,5))  AS NDVATAmt,              -- 불공제세액            
               A.CashItemSeq,           -- 현금흐름표과목코드            
               A.SMCostItemKind,        -- 원가항목유형            
               A.CostItemSeq,           -- 원가항목            
               REPLACE(REPLACE(A.Summary,'<','〈'),'>','〉') AS Summary,           -- 적요            
               A.BgtDeptSeq,            -- 예산부서            
               A.BgtCCtrSeq,            -- 예산활동센터            
               A.BgtSeq,                -- 예산과목코드            
               A.IsSet,                 -- 승인여부            
               B.AccName,               -- 계정과목            
               B.AccNo,                 -- 계정번호            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrName, '') END      AS CurrName,            -- 통화코드  
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrUnit, '') END      AS CurrUnit,            -- 통화표시단위
               ISNULL(E.EvidName, '')       AS EvidName,            -- 증빙코드            
               ''    AS TaxKindName,         -- 세무구분코드            
               ISNULL(CAI.CashItemName, '') AS CashItemName,        -- 현금흐름표과목코드            
               CostKind.MinorName           AS SMCostItemKindName,  -- 원가항목유형            
               '' AS CostItemName,          -- 원가항목            
               ISNULL(D.DeptName, '')       AS BgtDeptName,         -- 예산부서
               ISNULL(CC.CCtrName, '')      AS BgtCCtrName,         -- 예산활동센터            
               ISNULL(BG.BgtName, '')       AS BgtName,             -- 예산과목코드            
               CA.SMInOrOut,            
               CASE ISNULL(CA.SlipSeq, 0)            
                    WHEN 0 THEN '0'            
                    ELSE '1'            
               END AS IsCash,           -- 출납처리여부            
               CAO.CashDate,            -- 출납예정일            
               CAO.SMCashMethod,        -- 출납방법               
               1                            AS CashOffSerl,         -- 출납지급정보 순번      
               SlipOff.OnSlipSeq            AS OnSlipSeq,            
               SlipOnRow.SlipID             AS OnSlipID,            
               B.SMDrOrCr                   AS SMAccDrOrCr,            
               B.IsAnti,            
               B.IsSlip,            

               B.IsLevel2,             
               B.IsZeroAllow,            
               B.IsEssForAmt,            
               B.SMIsEssEvid,            
               B.IsEssCost,            
               B.IsCostTrn,            
               B.SMIsUseRNP,            
               B.SMRNPMethod,            
               B.SMBgtType,            
               B.IsCash                     AS IsCashAcc,            
               B.SMCashItemKind,            
               B.IsFundSet,            
               B.IsAutoExec,            
               B.SMAccType,            
               B.SMAccKind,            
               B.OffRemSeq,            
               B.BgtRemSeq,            
               B.RemSeq1,            
               B.RemSeq2,            
               ISNULL((SELECT COUNT(*) FROM _TDAAccountCostType  WITH(NOLOCK)  WHERE CompanySeq = A.CompanySeq AND AccSeq = A.AccSeq), 0)  AS CostTypeCount,            
               A.CoCustSeq                  AS CoCustSeq,    --관계회사코드            
               CoCust.CustName              AS CoCustName,    --관계회사            
               CM.MinorName                 AS SMCashMethodName  , 
               CAST(0 AS DECIMAL(19,5)) AS SumDrAmt,  
               CAST(0 AS DECIMAL(19,5)) AS SumCrAmt,  
               CAST(0 AS DECIMAL(19,5)) AS DrSumFirstFage, -- 일단0 바로아래서update한다.  
               CAST(0 AS DECIMAL(19,5)) AS CrSumFirstFage, -- 일단0 바로아래서update한다.  
               '' AS IsOnlyOnPage,  -- 일단 '' 바로 아래서 update한다.
               CA.CustSeq           AS CustSeq,
               CASE WHEN B.SMAccType = 4002012 AND SlipOff.OnSlipSeq <> 0 THEN
                    ISNULL(SUnit.AccUnitName , '') ELSE '' END AS S_AccUnitName, -- 본지점계정이면서 반제전표(설정전표가 있는 경우)라면, 관리항목의 회계단위명도 보여주도록 수정
               GW.TopUserName,
               Ca.EmpSeq             AS EmpSeq -- 사원코드, 출납정보에 사원이 있는 경우의 처리를 위해
          FROM _TACSlipRow AS A WITH (NOLOCK)            
               LEFT OUTER JOIN _TDAAccount      AS B    WITH(NOLOCK) ON B.CompanySeq   = A.CompanySeq AND B.AccSeq        = A.AccSeq       -- 계정과목
               LEFT OUTER JOIN _TDACurr         AS C    WITH(NOLOCK) ON C.CompanySeq   = A.CompanySeq AND C.CurrSeq       = A.CurrSeq      -- 통화
               LEFT OUTER JOIN _TDAEvid         AS E    WITH(NOLOCK) ON E.CompanySeq   = A.CompanySeq AND E.EvidSeq       = A.EvidSeq      -- 증빙
               LEFT OUTER JOIN _TACDCashItem    AS CAI  WITH(NOLOCK) ON CAI.CompanySeq = A.CompanySeq AND CAI.CashItemSeq = A.CashItemSeq  -- 현금흐름과목
               LEFT OUTER JOIN _TACBgtItem      AS BG   WITH(NOLOCK) ON BG.CompanySeq  = A.CompanySeq AND BG.BgtSeq       = A.BgtSeq       -- 예산
               LEFT OUTER JOIN _TDADept         AS D    WITH(NOLOCK) ON D.CompanySeq   = A.CompanySeq AND D.DeptSeq       = A.BgtDeptSeq   -- 예산부서
               LEFT OUTER JOIN _TDACCtr         AS CC   WITH(NOLOCK) ON CC.CompanySeq  = A.CompanySeq AND CC.CCtrSeq      = A.BgtCCtrSeq   -- 예산코스트센터
               LEFT OUTER JOIN _TACCashOn       AS CA   WITH(NOLOCK) ON CA.CompanySeq  = A.CompanySeq AND CA.SlipSeq      = A.SlipSeq      -- 출납발생
               LEFT OUTER JOIN _TDACust       AS CoCust WITH(NOLOCK) ON CoCust.CompanySeq = A.CompanySeq AND CoCust.CustSeq = A.CoCustSeq  -- 관계회사                           
               LEFT OUTER JOIN _TACSlipOff AS SlipOff   WITH(NOLOCK) ON SlipOff.CompanySeq   = A.CompanySeq       AND SlipOff.SlipSeq   = A.SlipSeq             -- 반제정보  
               LEFT OUTER JOIN _TACSlipRow AS SlipOnRow WITH(NOLOCK) ON SlipOnRow.CompanySeq = SlipOff.CompanySeq AND SlipOnRow.SlipSeq = SlipOff.OnSlipSeq     -- 발생정보
               LEFT OUTER JOIN _TDAAccUnit AS SUnit WITH(NOLOCK) ON SlipOnRow.CompanySeq = SUnit.CompanySeq AND SlipOnRow.AccUnit    = SUnit.AccUnit        -- 발생전표의 회계단위
               LEFT OUTER JOIN _TDASMinor     AS CostKind WITH(NOLOCK)      -- 원가항목구분
                            ON CostKind.CompanySeq = A.CompanySeq
                    AND CostKind.MinorSeq   = A.SMCostItemKind            
                           AND CostKind.MajorSeq   = 5508 -- 원가항목 구분            
               LEFT OUTER JOIN _TCOMGroupWare AS GW WITH(NOLOCK)            -- 그룹웨어
                            ON GW.CompanySeq       = A.CompanySeq 
                           AND GW.TblKey           = A.SlipMstSeq
                           AND GW.WorkKind         = 'Slip'
               LEFT OUTER JOIN #tempCash  AS CAO ON CAO.SlipSeq = A.SlipSeq               
               LEFT OUTER JOIN _TDAUMinor AS CM WITH(NOLOCK)
                            ON CM.CompanySeq = @CompanySeq
                           AND CM.MinorSeq   = CAO.SMCashMethod
                           AND CM.MajorSeq   = 4008                    -- 출납방법
         WHERE A.CompanySeq = @CompanySeq   
           AND A.SlipMstSeq IN (SELECT SlipMstSeq FROM #Temp) 
         ORDER BY A.RowNo            

    --===================================================
    -- 발생전표 기준 거래처 / 사원
    -- 건별반제 계정이나, 출납계정 중 [반제전표]인 경우에도, CustSeq, EmpSeq에 값을 넣어,
    -- 거래처 지불계좌나, 사원 주계좌정보를 출력물에 포함할 수 있도록 수정함.
    --===================================================
    UPDATE A
       SET CustSeq  = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TACSlipRow AS B WITH(NOLOCK)
                                ON B.CompanySeq = @CompanySeq
                               AND B.SlipSeq    = A.OnSlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)
                                ON C.CompanySeq = @CompanySeq
                               AND C.SlipSeq    = A.OnSlipSeq
                               AND C.RemSeq     = 1017 ------ 거래처 관리항목
     WHERE A.CustSeq    = 0
       AND ISNULL(A.OnSlipSeq, 0) <> 0


    UPDATE A
       SET EmpSeq = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TACSlipRow AS B WITH(NOLOCK)
                                ON B.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = B.SlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)
                                ON C.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = C.SlipSeq
                               AND C.RemSeq     = 1002 ------ 사원 관리항목
     WHERE A.CustSeq    = 0
       AND ISNULL(A.OnSlipSeq, 0) <> 0

    --================================================================================================================================            
    -- 원가항목조회      
    --================================================================================================================================          

    CREATE TABLE #tmp_SlipCostItemName
    (ID_Count       INT IDENTITY(1,1),
     SMCostItemKind INT, --원가항목구분
     CostItemSeq    INT, --원가항목코드
     CostItemName   NVARCHAR(400), --원가항목
     SlipSeq        INT
    )


    INSERT INTO #tmp_SlipCostItemName(SMCostItemKind, CostItemSeq, SlipSeq)
    SELECT SMCostItemKind, CostItemSeq, SlipSeq FROM #TempFixedCol WHERE SMCostItemKind > 0 
    EXEC _SWESMBGetCostIemNameData @CompanySeq, @LanguageSeq,149, '#tmp_SlipCostItemName','CostItemName'
    --================================================================================================================================            
    -- 원가항목조회끝    
    --================================================================================================================================


    --=============================
    -- 비용배부
    --=============================
    CREATE TABLE #TACSlipCost(
               SlipSeq          INT,            
               CostDeptSeq      INT,            
               CostCCtrSeq      INT,            
               CostDeptName     NVARCHAR(100),            
               CostCCtrName     NVARCHAR(100),            
               SlipCostCnt      INT   )

    INSERT INTO #TACSlipCost(

               SlipSeq,             
               CostDeptSeq,            
               CostCCtrSeq,            
               CostDeptName,            
               CostCCtrName,            
               SlipCostCnt   )
              
        SELECT A.SlipSeq,            
               A.CostDeptSeq,            
               A.CostCCtrSeq,            
               CASE WHEN X.Cnt > 1 
                    THEN ISNULL(D.DeptName, '') + '◐' + CAST(X.Cnt AS NVARCHAR)
                    ELSE ISNULL(D.DeptName, '')
               END          AS CostDeptName,
               ISNULL(C.CCtrName, '')   AS CostCCtrName,            
               X.Cnt        AS SlipCostCnt  
          FROM _TACSlipCost AS A WITH(NOLOCK)
               INNER JOIN (            
                            SELECT A.SlipSeq, MIN(A.Serl) AS Serl, COUNT(*) AS Cnt            
                              FROM _TACSlipCost AS A WITH(NOLOCK)
                             WHERE A.CompanySeq = @CompanySeq            
                               AND EXISTS (SELECT * FROM #TempFixedCol WHERE SlipSeq = A.SlipSeq)            
                             GROUP BY A.SlipSeq            
                          ) AS X            
                       ON X.SlipSeq = A.SlipSeq
                      AND X.Serl    = A.Serl            
               LEFT JOIN _TDACCtr AS C WITH(NOLOCK)            
                      ON C.CompanySeq   = A.CompanySeq            
                     AND C.CCtrSeq      = A.CostCCtrSeq            
               LEFT JOIN _TDADept AS D WITH(NOLOCK)            
                      ON D.CompanySeq   = A.CompanySeq            
                     AND D.DeptSeq      = A.CostDeptSeq            
         WHERE A.CompanySeq = @CompanySeq

    --=================================
    -- 비용배부 리스트
    --=================================
    CREATE TABLE #TACSlipCostList(
        SlipSeq                 INT,
        CostDeptNameList        NVARCHAR(1000),
        CostCCtrNameList        NVARCHAR(1000)
    )

    INSERT INTO #TACSlipCostList(SlipSeq, CostDeptNameList, CostCCtrNameList)
    SELECT A.SlipSeq, 
           CASE WHEN A.SlipCostCnt > 1
                THEN STUFF((SELECT N',' + ISNULL(C.DeptName, N'')
                              FROM _TACSlipCost AS B WITH(NOLOCK)
                                       JOIN _TDADept AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq AND C.DeptSeq = B.CostDeptSeq
                             WHERE B.CompanySeq = @CompanySeq
                               AND B.SlipSeq    = A.SlipSeq
                               FOR XML PATH(''),TYPE).value('(./text())[1]', 'NVARCHAR(1000)'), 1, 1, '')
                ELSE A.CostDeptName
           END,
           CASE WHEN A.SlipCostCnt > 1
                THEN STUFF((SELECT N',' + ISNULL(C.CCtrName, N'')
                              FROM _TACSlipCost AS B WITH(NOLOCK)
                                       JOIN _TDACCtr AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq AND C.CCtrSeq = B.CostCCtrSeq
                             WHERE B.CompanySeq = @CompanySeq
                               AND B.SlipSeq    = A.SlipSeq
                               FOR XML PATH(''),TYPE).value('(./text())[1]', 'NVARCHAR(1000)'), 1, 1, '')
                ELSE A.CostCCtrName
           END
      FROM #TACSlipCost AS A



    --===========================================================================
    -- 귀속부서로 출력되는 CostDeptName이 환경설정에 따라 조회되도록 수정 by.sykim.
    --===========================================================================
    UPDATE #TACSlipCost    
       SET CostDeptName = CASE WHEN @Env4121 = 4597001 THEN CostDeptName
                               WHEN @Env4121 = 4597002 THEN CostCCtrName                                            
                               WHEN @Env4121 = 4597003 AND ( CostDeptName = '' OR CostCCtrName = '' ) THEN CostDeptName + CostCCtrName  -- 둘중에 하나만 있으면 하나만 출력되도록 
                WHEN @Env4121 = 4597003 THEN CostDeptName + ' / ' + CostCCtrName 
                               ELSE CostDeptName END

    --================================================================================================================================              
    -- 변동컬럼값 조회(관리항목)            
    --================================================================================================================================            
    -- 코드헬프의 명칭을 가져오기 위한 임시테이블 생성            
    CREATE TABLE #tmp_SlipRemValue            
    (            
        SlipSeq         INT,            
        RemSeq          INT,            
        --RemName         NVARCHAR(100),            
        Seq             INT,            
        RemValText      NVARCHAR(100),            
        CellType        NVARCHAR(50),            
        IsDrEss         NCHAR(1),            
        IsCrEss         NCHAR(1),            
        Sort            INT   ,
  AccSubRemSeq    INT,  
    )            
            
    -- 임시테이블에 명칭을 가져오기 위한 키값을 넣어주고            
    INSERT INTO #tmp_SlipRemValue(SlipSeq, RemSeq, Seq, RemValText, CellType, IsDrEss, IsCrEss, Sort, AccSubRemSeq)
        SELECT A.SlipSeq,            
               B.RemSeq,            
               B.RemValSeq,            
               B.RemValText,            
               CASE D.SMInputType            
                    WHEN 4016001 THEN 'enText'            
                    WHEN 4016002 THEN 'enCodeHelp'            
                    WHEN 4016003 THEN 'enFloat'            
                    WHEN 4016004 THEN 'enFloat'            
                    WHEN 4016005 THEN 'enDate'            
                    WHEN 4016006 THEN 'enText'            
                    WHEN 4016007 THEN 'enFloat'            
                    ELSE 'enText'            
               END AS CellType,       -- 입력형태            
               C.IsDrEss,            
               C.IsCrEss,            
               C.Sort,
      CASE WHEN C.IsAccSub = '1' THEN C.Sort ELSE 0 END AS AccSubRemSeq
          FROM #TempFixedCol AS A            
               INNER JOIN _TACSlipRem AS B WITH (NOLOCK)            
                       ON B.CompanySeq  = @CompanySeq            
                      AND B.SlipSeq     = A.SlipSeq            
               INNER JOIN _TDAAccountSub AS C WITH (NOLOCK)            
                       ON C.CompanySeq  = B.CompanySeq            
                      AND C.AccSeq      = A.AccSeq            
                      AND C.RemSeq      = B.RemSeq 
               INNER JOIN _TDAAccountRem AS D WITH (NOLOCK)            
                       ON D.CompanySeq  = B.CompanySeq            
                      AND D.RemSeq      = B.RemSeq            
                          
    -- 명칭을 가져온다.            
    -- 실행 후에는 ValueName 컬럼이 자동생성되어 진다.            
    
    EXEC _SWUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue'   

    -- 기간
    UPDATE #tmp_SlipRemValue
       SET RemValue = LEFT(RemValue, 8) + '-' + RIGHT(RemValue, 8)
     WHERE RemSeq = 3013                -- 기간(YYYYMMDD-YYYYMMDD)
       AND LEN(RemValue) = 16  
       
    -- 부가세계정의 "공급가액", "불공제세" 금액 ","붙이는 FUNCTION사용 (_fnCOMCurrency)
    UPDATE #tmp_SlipRemValue
       SET RemValue     = dbo._fnCOMCurrency(RemValText,@KORDecimal)
     WHERE RemSeq   IN (3009, 3108) -- 공급가액, 불공제세

    -- 부가세계정의 "외화공급가액"은 ","붙이는 FUNCTION사용 (_fnCOMCurrency)
    UPDATE #tmp_SlipRemValue
       SET RemValue     = dbo._fnCOMCurrency(RemValText,@FORDecimal)
     WHERE RemSeq   IN (3113) -- 외화공급가액

    -- 부가세계정의 "불공제세" 금액이 0일 경우, 공백으로 출력되도록 수정(불공제 증빙이 아닌 경우)
    UPDATE #tmp_SlipRemValue
       SET RemValue     = CASE WHEN A.RemValue = '0' THEN '' ELSE A.RemValue END
      FROM #tmp_SlipRemValue  AS A JOIN #TempFixedCol AS B ON A.SlipSeq     = B.SlipSeq

                                   JOIN _TDAEvid       AS C ON C.CompanySeq  = @CompanySeq 
                                                          AND C.EvidSeq     = B.EvidSeq
     WHERE A.RemSeq   = 3108 -- 불공제세
       AND ISNULL(C.IsNDVAT, '') <> '1'  -- 불공제 증빙이 아닌 경우에만 공백으로 처리

    -- 관리항목 입력형태가 비율이면 뒤에 출려깃 '%'가 붙도록 처리(출력시 비율은 2자리로 우선 세팅)    
    -- 화면상에서는 5자리까지 입력이 가능한데 출력시에는 2자리만 출력되어 5자리까지 출력되도록 수정 - (서비스요청번호 : 201802200049) 2018.02.23. by sryoun. 
    UPDATE #tmp_SlipRemValue
       SET RemValue     = CASE WHEN ISNULL(RemValText, '') = '' THEN dbo._fnCOMCurrency(RemValText,5) 
                               ELSE dbo._fnCOMCurrency(RemValText,5) + '%'  END
     WHERE SMInputTypeForConvertDateType = 4016004 -- 비율
    

    --------------------------------------------------------------------------------------------------------------------------------------------
    -- #tmp_SlipRemValue 의 RemValue 중 관리항목 사업자번호 (1013), 거래처(1017) 인 경우엔 이력에 따라 명칭을 가져올수 있도록 한다. 시작
    --------------------------------------------------------------------------------------------------------------------------------------------
    IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1013)
    BEGIN 
        UPDATE A
           SET A.RemValue       = CASE WHEN ISNULL(C.TaxNoAlias,'') = '' THEN A.RemValue ELSE C.TaxNoAlias END,
               A.RemRefValue    = CASE WHEN ISNULL(C.TaxNo,'') = '' THEN A.RemRefValue ELSE C.TaxNo END
          FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                        AND A.SlipSeq    = B.SlipSeq
                           LEFT OUTER JOIN _TDATaxUnitHist   AS C WITH(NOLOCK) ON C.CompanySeq    = @CompanySeq
                                                                              AND C.TaxUnit       = A.Seq
                                                                              AND B.AccDate       BETWEEN C.FrDate AND C.ToDate       
         WHERE A.RemSeq = 1013
    END
   
    IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1017)
    BEGIN
        UPDATE A
           SET A.RemValue   = CASE WHEN ISNULL(C.FullName,'') = '' THEN A.RemValue ELSE C.FullName END,
               A.RemRefValue    = CASE WHEN ISNULL(C.BizNo,'') = '' THEN A.RemRefValue ELSE C.BizNo END
          FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                        AND A.SlipSeq    = B.SlipSeq
                          LEFT OUTER JOIN _TDACustTaxHist   AS C WITH(NOLOCK) ON C.CompanySeq    = @CompanySeq
                                                                             AND C.CustSeq       = A.Seq
                                                                             AND B.AccDate       BETWEEN ISNULL(C.FrDate,'') AND ISNULL(C.ToDate,'29991231')                                                                  
         WHERE A.RemSeq = 1017    
    END 
    
    -- 사업자번호에 '-' 넣기
    UPDATE #tmp_SlipRemValue    
       SET RemRefValue = dbo._FCOMMaskConv(@EnvValue,RemRefValue)
      FROM #tmp_SlipRemValue AS A    
                JOIN _TCACodeHelpData AS B WITH(NOLOCK) ON A.CodeHelpSeq = B.CodeHelpSeq    
     WHERE B.CompanySeq = 0    
       AND B.RefColumnName IN ('BizNo', 'TaxNo')    
       AND ISNULL(A.RemRefValue, '') <> ''    

    -- 환경설정에 '전표 출력시 개인거래처의 주민등록번호 출력함'이 체크 되어 있는 경우에만 주민번호 가져가기.  
    IF EXISTS (select * From _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 4705 AND EnvValue = '1')  
    BEGIN  
        -- 사업자번호가 없다면 주민번호 가져오기  
        IF EXISTS (SELECT RemRefValue FROM #tmp_SlipRemValue WHERE RemSeq = 1017 AND RemRefValue = '')       
        BEGIN  
            UPDATE #tmp_SlipRemValue  
               SET RemRefValue = dbo._FCOMMASKConv(@PersonId, CASE WHEN @ProductType = 282001 

                                                                   THEN dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq)
                                                                   ELSE dbo._FWCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq)
                                                              END)  
              FROM #tmp_SlipRemValue AS A JOIN _TDACust AS B WITH(NOLOCK) ON A.Seq = B.CustSeq  
             WHERE B.CompanySeq = @CompanySeq  
               AND A.RemSeq = 1017      -- 거래처
               AND A.RemRefValue = ''   -- 사업자번호가 존재하지 않는 것

        END  
    END  
    
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- #tmp_SlipRemValue 의 RemValue 중 관리항목 사업자번호 (1013), 거래처(1017) 인 경우엔 이력에 따라 명칭을 가져올수 있도록 한다. 끝
    --------------------------------------------------------------------------------------------------------------------------------------------
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   
       

    SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)  

    -- 페이지 관련 정보 처리 시작

    SELECT @MaxCnt      = COUNT(*) FROM #Temp
    SELECT @Cnt         = 0
    
    WHILE (@Cnt < @MaxCnt)          
    BEGIN
            SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt

            UPDATE A
               SET A.RowIDX = B.RowIDX
             FROM #TempFixedCol AS A JOIN (SELECT ROW_NUMBER() OVER(ORDER BY RowIDX)-1 AS RowIDX, 
                                                  SlipMstSeq,
                                                  SlipSeq
                                             FROM  #TempFixedCol
                                            WHERE SlipMstSeq = @SlipMstSeq) AS B ON A.SlipMstSeq    = B.SlipMstSeq
                                                                                AND A.SlipSeq       = B.SlipSeq

            UPDATE A
               SET A.SumDrAmt = B.SumDrAmt,
                   A.SumCrAmt = B.SumCrAmt,
                   A.MaxIDX   = B.MaxIDX,
                   A.IsOnlyOnPage = CASE WHEN B.TotCnt < 10 THEN '1' ELSE '0' END
              FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt)   AS SumDrAmt, 
                                                   SUM(CrAMt)   AS SumCrAmt, 
                                                   MAX(RowIDX)  AS MaxIDX,
                                                   COUNT(*)     AS TotCnt,
                                                   SlipMstSeq
                                              FROM #TempFixedCol
                                             WHERE SlipMstSeq = @SlipMstSeq
                                             GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq
                                            
            UPDATE A
               SET A.DrSumFirstFage = B.DrSumFirstFage,
                   A.CrSumFirstFage = B.CrSumFirstFage
              FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt) AS DrSumFirstFage, 
                                                   SUM(CrAMt) AS CrSumFirstFage,
                                                   SlipMstSeq
                                              FROM  #TempFixedCol
                                             WHERE SlipMstSeq = @SlipMstSeq
                                               AND CONVERT(INT, RIGHT(RTRIM(RowNo), 2)) < 10
                                             GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq
            
            SELECT @Cnt = @Cnt + 1
    END 

    --==================================
    -- 전자증빙 HTML (SUB SP 전달용)
    --==================================
    CREATE TABLE #THTMLDataFinal(
        HtmlData        NVARCHAR(MAX)   ,   -- 전자증빙 Html
        HtmlWidth       INT             ,   -- 다이얼로그 너비
        HtmlHeight      INT                 -- 다이얼로그 높이
    )


    ALTER TABLE #TempFixedCol ADD  IsEvidBtn NCHAR(1) 
    ALTER TABLE #TempFixedCol ADD  EvidHtml  NVARCHAR(MAX) 

    UPDATE #TempFixedCol
    SET IsEvidBtn = '1'
    FROM #TempFixedCol AS A 
    join _TSIEBillPurchaseSlip as b on b.CompanySeq = @CompanySeq and b.slipseq = a.slipseq
    
    SELECT TOP 1  @SlipSeq = SlipSeq 
      FROM #TempFixedCol
     WHERE IsEvidBtn = '1'

     EXEC woowon_SWACElectronicEvidenceQuery 
          @SlipSeq
         ,@ServiceSeq    
         ,@WorkingTag    
         ,@CompanySeq    
         ,@LanguageSeq   
         ,@UserSeq       
         ,@PgmSeq        


    UPDATE #TempFixedCol
    SET EvidHtml = HtmlData
    FROM #TempFixedCol AS A 
         JOIN #THTMLDataFinal AS B ON 1=1
     WHERE A.IsEvidBtn = '1'


    -- 페이지 관련 정보 처리 끝

        SELECT A.MaxIDX,    
               A.RowIDX,    

               LEFT(MstSlip.AccDate   ,4) + N'년' + SUBSTRING(MstSlip.AccDate,5   ,2) + N'월' + RIGHT(MstSlip.AccDate   ,2) + N'일' AS AccDate, -- 회계일 
               LEFT(MstSlip.RegAccDate,4) + N'년' + SUBSTRING(MstSlip.RegAccDate,5,2) + N'월' + RIGHT(MstSlip.RegAccDate,2) + N'일' AS RegDate, -- 기표일  
               MstSlip.AccDate                      AS OrgAccDate, 
               @CurrDate                            AS CurrDate,    
               ISNULL(MstSlip.RegDeptName,'')       AS RegDeptName,    
               ISNULL(MstSlip.RegEmpName,'')        AS RegEmpName,          
               ISNULL(MstSlip.SetSlipNo,'')         AS SetSlipNo,       
               A.SlipMstSeq,
               ISNULL(MstSlip.SlipKind, 0)          AS SlipKind,    
               ISNULL(MstSlip.SlipKindName, '')     AS SlipKindName,    
               ISNULL(MstSlip.RegEmpSeq,0)          AS RegEmpSeq,    
               ISNULL(MstSlip.RegDeptSeq,0)         AS RegDeptSeq,    
               ISNULL(REPLACE(REPLACE(MstSlip.Remark,'<','〈'),'>','〉'),'') AS Remark,           -- 적요            
               ISNULL(MstSlip.SMCurrStatus,0)       AS SMCurrStatus,    
               ISNULL(MstSlip.AptDate,'')           AS AptDate,    
               ISNULL(MstSlip.AptEmpSeq,0)          AS AptEmpSeq,    
               ISNULL(MstSlip.AptDeptSeq,0)         AS AptDeptSeq,    
               ISNULL(MstSlip.AptRemark,'')         AS AptRemark,    
               ISNULL(MstSlip.SMCheckStatus,0)      AS SMCheckStatus,    
               ISNULL(MstSlip.CheckOrigin,'')       AS CheckOrigin,  
               ISNULL(MstSlip.SetEmpSeq,0)          AS SetEmpSeq,   
               ISNULL(MstSlip.SetDeptSeq,0)         AS SetDeptSeq,    
               ISNULL(MstSlip.SlipUnitName,'')      AS SlipUnitName,  
               ISNULL(MstSlip.SlipAppNo,'')         AS SlipAppNo,
               CASE WHEN MstSlip.IsSet = '1' THEN MstSlip.AccDate ELSE '' END  AS AccDateFull,    -- 승인일
               A.RowIDX + 1 AS RowNum,            
               A.SlipSeq,               -- 전표코드
               ISNULL(MstSlip.SlipMstID,'') AS SlipMstID,
               Right(ISNULL(MstSlip.SlipAppNo,''),4) AS Right_SlipAppNo,
               Right(ISNULL(MstSlip.SlipMstID,''),4) AS Right_SlipMstID,           
               A.SlipID,                -- 전표기표번호 
               Right(A.SlipID,4)          AS Right_SlipID,  
               A.AccUnit,               -- 회계단위         
               ISNULL(Acc.AccUnitName,'') AS AccUnitName,         
               A.SlipUnit,              -- 전표관리단위            
               A.SlipNo,                -- 기표일련번호            
               A.RowNo,                 -- 행번호            
               A.RowSlipUnit,           -- 행별전표관리단위            
               A.AccSeq,                -- 계정코드            
               A.UMCostType,            -- 비용구분            
               A.SMDrOrCr,              -- 차대구분            
               ISNULL(A.DrAmt, 0)    AS DrAmt,    -- 차변금액            
               ISNULL(A.CrAmt, 0)    AS CrAmt,    -- 대변금액            
               ISNULL(A.DrForAmt, 0) AS DrForAmt, -- 외화차변금액            
               ISNULL(A.CrForAmt, 0) AS CrForAmt, -- 외화대변금액            
               A.CurrSeq,               -- 통화코드            
               CASE WHEN A.DrForAmt = 0 THEN 0 ELSE A.ExRate END DrExRate,                -- 환율        
               CASE WHEN A.CrForAmt = 0 THEN 0 ELSE A.ExRate END CrExRate,                -- 환율        
               A.DivExRate,             -- 나누기 환율            
               A.EvidSeq,               -- 증빙코드            
               A.TaxKindSeq,            -- 세무구분코드            
               A.NDVATAmt,              -- 불공제세액            
               A.CashItemSeq,           -- 현금흐름표과목코드            
               ISNULL(L.SMCostItemKind,0)   AS SMCostItemKind,        -- 원가항목유형            
               ISNULL(L.CostItemSeq,0)      AS CostItemSeq,           -- 원가항목            
               A.Summary,               -- 적요            
               ISNULL(A.BgtDeptSeq,0)       AS BgtDeptSeq,            -- 예산부서            
               ISNULL(A.BgtCCtrSeq,0)       AS BgtCCtrSeq,            -- 예산활동센터            
               ISNULL(A.BgtSeq,0)           AS BgtSeq,                -- 예산과목코드            
               ISNULL(A.IsSet,'')           AS IsSet,                 -- 승인여부            
               ISNULL(A.AccName,'')         AS AccName,               -- 계정과목            
               ISNULL(A.AccNo, '')          AS AccNo,                 -- 계정번호            
               CASE WHEN A.DrForAmt = 0 THEN '' ELSE ISNULL(A.CurrName,'') END AS DrCurrName,              -- 통화코드  
               CASE WHEN A.CrForAmt = 0 THEN '' ELSE ISNULL(A.CurrName,'') END AS CrCurrName,              -- 통화코드     
               ISNULL(A.CurrUnit,'')        AS CurrUnit,              -- 통화표시단위         
               ISNULL(A.EvidName, '')       AS EvidName,              -- 증빙코드            
               ISNULL(A.TaxKindName,'')     AS TaxKindName,           -- 세무구분코드            
               ISNULL(A.CashItemName,'')    AS CashItemName,          -- 현금흐름표과목코드            
               ISNULL(A.SMCostItemKindName,'') AS SMCostItemKindName, -- 원가항목유형            
               ISNULL(L.CostItemName, '')   AS CostItemName,          -- 원가항목            
               A.BgtDeptName,   -- 예산부서            
               A.BgtCCtrName,  -- 예산활동센터            
               A.BgtName,               -- 예산과목코드            
               ISNULL(A.SMInOrOut,0) AS SMInOrOut,            
               ISNULL(A.IsCash,'') AS IsCash,           -- 출납처리여부            
               ISNULL(LEFT(A.CashDate,4) + '-' + SubString(A.CashDate,5,2) + '-' + RIGHT(A.CashDate,2),'') AS CashDate,            -- 출납예정일            
               ISNULL(A.SMCashMethod,0) AS SMCashMethod,        -- 출납방법            
               ISNULL(A.CashOffSerl,0) AS CashOffSerl,            
               ISNULL(A.OnSlipSeq,0) AS OnSlipSeq,            
               ISNULL(A.OnSlipID,'') AS OnSlipID,            
               A.SMAccDrOrCr,            
               A.IsAnti,            
               A.IsSlip,            
               A.IsLevel2,            
               A.IsZeroAllow,            
               A.IsEssForAmt,            
               A.SMIsEssEvid,            
               A.IsEssCost,            
               A.IsCostTrn,            
               A.SMIsUseRNP,            
               A.SMRNPMethod,            
               A.SMBgtType,            
               A.IsCashAcc,            
               A.SMCashItemKind,            
               A.IsFundSet,         
               A.IsAutoExec,            
               A.SMAccType,            
               A.SMAccKind,            
               A.OffRemSeq,            
               A.BgtRemSeq,            
               A.RemSeq1,            
               A.RemSeq2,            
               A.CostTypeCount,                      
               ISNULL(C.MinorName,'')  AS UMCostTypeName,                 
               ISNULL(B.CostDeptName,'') AS CostDeptName,
               ISNULL(B.CostCCtrName,'') AS CostCCtrName,
               B.CostDeptSeq,            
               B.CostCCtrSeq,            
               B.SlipCostCnt,            
               A.CoCustSeq,            
               ISNULL(A.CoCustName,'') AS CoCustName,
               -- 거래처 관리항목의 경우 (사업자번호)도 출력될 수 있도록..    
               ISNULL(CASE WHEN D.RemSeq IN (1017, 1013) THEN RTRIM(D.RemValue) + (CASE WHEN ISNULL(D.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(D.RemRefValue) + N')' END) ELSE ISNULL(D.RemValue,'') END, N'') AS RemValue1,        
               ISNULL(CASE WHEN E.RemSeq IN (1017, 1013) THEN RTRIM(E.RemValue) + (CASE WHEN ISNULL(E.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(E.RemRefValue) + N')' END) ELSE ISNULL(E.RemValue,'') END, N'') AS RemValue2,        
               ISNULL(CASE WHEN F.RemSeq IN (1017, 1013) THEN RTRIM(F.RemValue) + (CASE WHEN ISNULL(F.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(F.RemRefValue) + N')' END) ELSE ISNULL(F.RemValue,'') END, N'') AS RemValue3,        

               ISNULL(CASE WHEN G.RemSeq IN (1017, 1013) THEN RTRIM(G.RemValue) + (CASE WHEN ISNULL(G.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(G.RemRefValue) + N')' END) ELSE ISNULL(G.RemValue,'') END, N'') AS RemValue4,     
               ISNULL(CASE WHEN H.RemSeq IN (1017, 1013) THEN RTRIM(H.RemValue) + (CASE WHEN ISNULL(H.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(H.RemRefValue) + N')' END) ELSE ISNULL(H.RemValue,'') END, N'') AS RemValue5,    
               ISNULL(CASE WHEN I.RemSeq IN (1017, 1013) THEN RTRIM(I.RemValue) + (CASE WHEN ISNULL(I.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(I.RemRefValue) + N')' END) ELSE ISNULL(I.RemValue,'') END, N'') AS RemValue6,    
               ISNULL(CASE WHEN J.RemSeq IN (1017, 1013) THEN RTRIM(J.RemValue) + (CASE WHEN ISNULL(J.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(J.RemRefValue) + N')' END) ELSE ISNULL(J.RemValue,'') END, N'') AS RemValue7,    
               ISNULL(CASE WHEN K.RemSeq IN (1017, 1013) THEN RTRIM(K.RemValue) + (CASE WHEN ISNULL(K.RemRefValue, '') = '' THEN N'' ELSE N' (' + RTRIM(K.RemRefValue) + N')' END) ELSE ISNULL(K.RemValue,'') END, N'') AS RemValue8,  
               ISNULL(D.RemName,'') AS RemName1,  
               ISNULL(E.RemName,'') AS RemName2,
               ISNULL(F.RemName,'') AS RemName3,
               ISNULL(G.RemName,'') AS RemName4,
               ISNULL(H.RemName,'') AS RemName5,
               ISNULL(I.RemName,'') AS RemName6,
               ISNULL(J.RemName,'') AS RemName7,
               ISNULL(K.RemName,'') AS RemName8,
               CASE WHEN ISNULL(dbo._FWCOMDecrypt(Bank.BankAccNo,N'_TDACustBankAcc', N'BankAccNo', @CompanySeq),'') = '' 
                    THEN ISNULL(C3.MinorName, '') + N' ' + CASE WHEN ISNULL(dbo._FWCOMDecrypt(EmpBank.AccNo ,N'_VWXHRBasEmpAccNo', N'AccNo'    , @CompanySeq), '') = '' THEN '' ELSE N'(' + RTRIM(dbo._FWCOMDecrypt(EmpBank.AccNo ,N'_VWXHRBasEmpAccNo', N'AccNo'    , @CompanySeq)) + N')' END 
                    ELSE ISNULL(C2.MinorName, '') + N' ' + CASE WHEN ISNULL(dbo._FWCOMDecrypt(Bank.BankAccNo,N'_TDACustBankAcc', N'BankAccNo', @CompanySeq), '') = '' THEN '' ELSE N'(' + RTRIM(dbo._FWCOMDecrypt(Bank.BankAccNo,N'_TDACustBankAcc', N'BankAccNo', @CompanySeq)) + N')' END
               END AS CustInfo,
               ISNULL(A.SMCashMethodName,'') AS SMCashMethodName ,    
               A.SumDrAmt,    
               A.SUMCrAmt  ,
               A.SlipNo AS SlipNoOne,
               CASE WHEN CONVERT(INT, RIGHT(RTRIM(A.RowNo), 2)) < 10 THEN '1' ELSE '0' END IsFirstPage,
               A.DrSumFirstFage,
               A.CrSumFirstFage,
               A.IsOnlyOnPage,
               CONVERT(NCHAR(8),MstSlip.RegDateTime,112)  AS RegDateTime, -- 전표 작성일
               A.S_AccUnitName                            AS S_AccUnitName, -- 본지점 반제전표인 경우 발생전표의 회계단위명
               ISNULL(cctr.Remark, '')                    AS CCtrRemark,
               ISNULL(A.TopUserName,'') AS TopUserName,
               CASE WHEN ISNULL(C.MinorName, '') <> '' 
                    THEN A.AccName + N'(' + RTRIM(ISNULL(C.MinorName, N'')) + N')'
                    ELSE A.AccName
               END AS AccName2,
               ISNULL(MstSlip.SetEmpName,'') AS SetEmpName,
               CASE WHEN ISNULL(dbo._FWCOMDecrypt(Bank.BankAccNo,N'_TDACustBankAcc', N'BankAccNo', @CompanySeq),'') = '' 
                    THEN ISNULL(C3.MinorName, N'') + N' ' + CASE WHEN ISNULL(dbo._FWCOMDecrypt(EmpBankFBS.AccNo,N'_VWXHRBasEmpAccNo', N'AccNo'    , @CompanySeq),'') = '' THEN '' ELSE N'(' + RTRIM(dbo._FWCOMDecrypt(EmpBankFBS.AccNo, N'_VWXHRBasEmpAccNo', N'AccNo'    , @CompanySeq)) + N')' END
                    ELSE ISNULL(C2.MinorName, N'') + N' ' + CASE WHEN ISNULL(dbo._FWCOMDecrypt(Bank.BankAccNo  ,N'_TDACustBankAcc', N'BankAccNo', @CompanySeq),'') = '' THEN '' ELSE N'(' + RTRIM(dbo._FWCOMDecrypt(Bank.BankAccNo  , N'_TDACustBankAcc', N'BankAccNo', @CompanySeq)) + N')' END
               END AS CustInfoFBS,
               @KORDecimal      AS DecLenKor,
               @FORDecimal      AS DecLenFor,
               @ExraDecimal     AS DecLenExRate,
               SCL.CostDeptNameList     AS CostDeptNameList,
               SCL.CostCCtrNameList     AS CostCCtrNameList,
      ISNULL(AccSubRem.RemValue, '')      AS AccSubName,      -- 계정세목  
      CASE WHEN ISNULL(MstSlip.SlipKind, 0) IN (10000094, 10000095, 10000103) THEN '개인경비 전표'
     WHEN ISNULL(MstSlip.SlipKind, 0) IN (10000109, 10356, 10329, 10331, 10000046, 10000043, 10000045, 10332) THEN '법인카드 전표'
     -- 명칭변경요청
     ELSE '회계전표' END AS SlipTitleName , 
      CASE WHEN ISNULL(MstSlip.SlipKind, 0) IN (10000094, 10000095, 10000103) THEN 1
     WHEN ISNULL(MstSlip.SlipKind, 0) IN (10000109, 10356, 10329, 10331, 10000046, 10000043, 10000045, 10332) THEN 2
     ELSE 3 END AS SlipTitleSeq ,
     A.IsEvidBtn,
     A.EvidHtml
          FROM #TempFixedCol AS A            
               LEFT OUTER JOIN #TACSlipCost AS B      ON B.SlipSeq      = A.SlipSeq
               LEFT OUTER JOIN #Result_tmp AS MstSlip ON A.SlipMstSeq = MstSlip.SlipMstSeq          
               LEFT OUTER JOIN #tmp_SlipRemValue AS D ON A.SlipSeq = D.SlipSeq AND D.Sort = 1        
               LEFT OUTER JOIN #tmp_SlipRemValue AS E ON A.SlipSeq = E.SlipSeq AND E.Sort = 2        
               LEFT OUTER JOIN #tmp_SlipRemValue AS F ON A.SlipSeq = F.SlipSeq AND F.Sort = 3        
               LEFT OUTER JOIN #tmp_SlipRemValue AS G ON A.SlipSeq = G.SlipSeq AND G.Sort = 4        
               LEFT OUTER JOIN #tmp_SlipRemValue AS H ON A.SlipSeq = H.SlipSeq AND H.Sort = 5        
               LEFT OUTER JOIN #tmp_SlipRemValue AS I ON A.SlipSeq = I.SlipSeq AND I.Sort = 6        
               LEFT OUTER JOIN #tmp_SlipRemValue AS J ON A.SlipSeq = J.SlipSeq AND J.Sort = 7        
               LEFT OUTER JOIN #tmp_SlipRemValue AS K ON A.SlipSeq = K.SlipSeq AND K.Sort = 8        
               LEFT OUTER JOIN #tmp_SlipCostItemName AS L ON A.SlipSeq = L.SlipSeq
               LEFT OUTER JOIN _TDAAccUnit     AS Acc  WITH(NOLOCK) ON Acc.CompanySeq = @CompanySeq
                                                                   AND Acc.AccUnit    = A.AccUnit
               LEFT OUTER JOIN _TDACustBankAcc AS bank WITH(NOLOCK) ON bank.CompanySeq = @CompanySeq
                                                                   AND bank.CustSeq    = A.CustSeq    
                                                                   AND bank.IsDefault  = '1' 
                                                                   AND bank.CustSeq   <> 0
               LEFT OUTER JOIN _VWXHRBasEmpAccNo AS EmpBank WITH(NOLOCK) ON EmpBank.CompanySeq  = @CompanySeq
                                                                        AND EmpBank.EmpSeq      = A.EmpSeq
                                                                        AND EmpBank.UMAccNoType = 3098001 -- 주계좌만
                                                                        AND EmpBank.AccNo       > N''
               LEFT OUTER JOIN _TCOMEnvAccFBS  AS AccFBS  WITH(NOLOCK) ON AccFBS.CompanySeq = @CompanySeq 
                                                                      AND AccFBS.AccSeq     = A.AccSeq
               LEFT OUTER JOIN _VWXHRBasEmpAccNo AS EmpBankFBS WITH(NOLOCK) ON EmpBankFBS.CompanySeq = @CompanySeq 
                                                                           AND EmpBankFBS.EmpSeq      = A.EmpSeq
                                                                           AND EmpBankFBS.UMAccNoType = AccFBS.SMBankAccClass
               LEFT OUTER JOIN _TDAUMinor AS C  WITH(NOLOCK) ON C.CompanySeq   = @CompanySeq        AND C.MinorSeq  = A.UMCostType       AND C.MajorSeq  = 4001     -- 비용구분
               LEFT OUTER JOIN _TDAUMinor AS C2 WITH(NOLOCK) ON C2.CompanySeq  = bank.CompanySeq    AND C2.MinorSeq = bank.UMBankHQ      AND C2.MajorSeq = 4003     -- 거래처계좌(금융기관)
               LEFT OUTER JOIN _TDAUMinor AS C3 WITH(NOLOCK) ON C3.CompanySeq  = EmpBank.CompanySeq AND C3.MinorSeq = EmpBank.PayBankSeq AND C3.MajorSeq = 4003     -- 사원계좌(금융기관)               
               LEFT OUTER JOIN _TDACCtr AS cctr WITH(NOLOCK) ON cctr.CompanySeq = @CompanySeq       AND cctr.CCtrSeq = A.BgtCCtrSeq
               LEFT OUTER JOIN #TACSlipCostList AS SCL       ON SCL.SlipSeq    = A.SlipSeq
      LEFT OUTER JOIN #tmp_SlipRemValue AS AccSubRem       -- 세목관리항목  
                                             ON A.SlipSeq       = AccSubRem.SlipSeq  
                                            AND AccSubRem.AccSubRemSeq > 0  

         ORDER BY MstSlip.SlipMstID, A.RowNo
    
        --=========================================================================================================================
        -- 출력회수 증가
        --=========================================================================================================================
        IF EXISTS (SELECT 1 FROM #Temp)
        BEGIN
            SELECT @Cnt = 0
            SELECT @MaxCnt = MAX(Cnt) FROM #Temp
            WHILE @Cnt <= @MaxCnt
            BEGIN
                SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt

                UPDATE _TACSlipPrintCount
                   SET PrintCnt = PrintCnt + 1
                 WHERE CompanySeq   = @CompanySeq
                   AND SlipMstSeq   = @SlipMstSeq
                
                IF @@ROWCOUNT = 0
                BEGIN
                    INSERT INTO _TACSlipPrintCount (CompanySeq, SlipMstSeq, PrintCnt, LastUserSeq, LastDateTime)
                        SELECT @CompanySeq, @SlipMstSeq, 1, @UserSeq, GETDATE()
                END

                SELECT @Cnt = @Cnt + 1
            END
        END

    END            
              
            
    --> 최초 뜰때 실행계획을 다시 잡는 것 같아 별도 SUB SP로 분리함. ---> 대행사 끝나고 전표는 다시 정리해야 할 것임       
       

RETURN

--GO

--exec _SWCOMGroupWarePrint 1,1,1,502082,'Slip_woowon','34','woowon'

----SELECT * FROM _TCAPgm WHERE Caption LIKE '%전표입력%'
