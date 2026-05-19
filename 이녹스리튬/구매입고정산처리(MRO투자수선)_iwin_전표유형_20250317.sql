declare @slipkind int ,@CompanySeq int ,@pmgseq int ,@copyslipkind int ,@copyPgmseq int ,@copypgmid nvarchar(100)
        ,@siteinit nvarchar(100)
--============변수================

select @slipkind = 13000155
select @copyslipkind = 13000498
select @siteinit = '_iwin'


--==================================


select  @CompanySeq =companyseq 
from _tcacompany
order by companyseq desc

--select @CompanySeq



--select @pmgseq=pgmseq
--from _tacslipkind
--where slipkind = @slipkind
--and companyseq= @CompanySeq



select @copyPgmseq = pgmseq
from _tacslipkind
where SlipKind =@copyslipkind
and companyseq = @companyseq

 select   @copyPgmseq = 125820007


--select @copyPgmseq = 72220100
-- select @copypgmid = ''

/* 전표유형이 등록 안했을 경우 프로그램 코드 강제로 넣어지구 
 select   @copyPgmseq = 72220103
 select @copypgmid = ''
*/

select @copypgmid = PgmId
from _tcapgm 
where pgmseq = @copyPgmseq

select @copypgmid = 'FrmWPUDelvInAccExcpt_iwin'
--========================================






--삭제후 넣을 경우 
/*
delete from _TACSlipKind				where SlipKind          =@slipkind
delete from _TACSlipAutoEnv             where SlipAutoEnvSeq    =@slipkind
delete from _TACSlipAutoEnvKey          where SlipAutoEnvSeq    =@slipkind
delete _TACSlipPgmControls
from _TACSlipPgmControls   AS A WITH(NOLOCK) 
            join _tacslipkind as b on b.pgmseq = a.Pgmseq  and a.companyseq =b.companyseq
 WHERE b.slipkind = @slipkind

delete from _TACSlipAutoEnvRow          where SlipAutoEnvSeq =@slipkind
delete from _TACSlipAutoEnvRem          where SlipAutoEnvSeq =@slipkind
delete from _TACSlipAutoEnvRowCol       where SlipAutoEnvSeq =@slipkind
*/

--================================
   select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipKind WHERE '+'SlipKind	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' )'+CHAR(13)+'BEGIN '+CHAR(13)+-- INSERT SCRIPT FOR [_TACSlipKind]  'INSERT _TACSlipKind(CompanySeq, SlipKind, SlipKindName, SlipKindNo, UMSlipKindGroup, JourMethod, PgmSeq, IsNotRowAdd, IsNotAccAmtMod, IsAutoSet, IsNotChkFoEss, IsNotAllModify, TableName, SlipColumnName, IsPurCash, SMAccStd, StdPaySeq, LastUserSeq, LastDateTime, OrderBySummary, AddCheckScript, AddSaveScript, IsNotUse, IsNotAllDelete, IsNotUseGroupWare, IsReplace, CustSeq, DevMode, ClientSeq, DevSystemSeq, OrderByRowSort, Sort, JournalizingScript, IsNotAccDateMod, ElecEvidenceScript, IsNotRowDel, IsNotAccModify, SourceRefFileColumnName, SourceRefJumpDataBlock, SourceRefKeyColumnName1, SourceRefKeyColumnName2, SourceRefKeyColumnName3, SourceRefNoColumnName, SourceRefPgmSeq, SourceRefTableName, IsEssGroupWare) '+CHAR(13)+ + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END + ',' + CASE WHEN A.SlipKind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END + ',' + CASE WHEN A.SlipKindName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SlipKindName+@siteinit) + ''')' END + ',' + CASE WHEN A.SlipKindNo IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(@copypgmid) + ''')' END + ',' + CASE WHEN A.UMSlipKindGroup IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.UMSlipKindGroup) END + ',' + CASE WHEN A.JourMethod IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.JourMethod) END + ',' + CASE WHEN A.PgmSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyPgmseq) END + ',' + CASE WHEN A.IsNotRowAdd IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotRowAdd) + ''')' END + ',' + CASE WHEN A.IsNotAccAmtMod IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotAccAmtMod) + ''')' END + ',' + CASE WHEN A.IsAutoSet IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsAutoSet) + ''')' END + ',' + CASE WHEN A.IsNotChkFoEss IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotChkFoEss) + ''')' END + ',' + CASE WHEN A.IsNotAllModify IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotAllModify) + ''')' END + ',' + CASE WHEN A.TableName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.TableName) + ''')' END + ',' + CASE WHEN A.SlipColumnName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SlipColumnName) + ''')' END + ',' + CASE WHEN A.IsPurCash IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsPurCash) + ''')' END + ',' + CASE WHEN A.SMAccStd IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.SMAccStd) END + ',' + CASE WHEN A.StdPaySeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.StdPaySeq) END + ',' + CASE WHEN A.LastUserSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.LastUserSeq) END + ',' + CASE WHEN A.LastDateTime IS NULL THEN N'NULL' ELSE '''' + CONVERT(NVARCHAR, A.LastDateTime, 121) + '''' END + ',' + CASE WHEN A.OrderBySummary IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.OrderBySummary) + ''')' END + ',' + CASE WHEN A.AddCheckScript IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.AddCheckScript) + ''')' END + ',' + CASE WHEN A.AddSaveScript IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.AddSaveScript) + ''')' END + ',' + CASE WHEN A.IsNotUse IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotUse) + ''')' END + ',' + CASE WHEN A.IsNotAllDelete IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotAllDelete) + ''')' END + ',' + CASE WHEN A.IsNotUseGroupWare IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotUseGroupWare) + ''')' END + ',' + CASE WHEN A.IsReplace IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsReplace) + ''')' END + ',' + CASE WHEN A.CustSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.CustSeq) END + ',' + CASE WHEN A.DevMode IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.DevMode) END + ',' + CASE WHEN A.ClientSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ClientSeq) END + ',' + CASE WHEN A.DevSystemSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.DevSystemSeq) END + ',' + CASE WHEN A.OrderByRowSort IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.OrderByRowSort) + ''')' END + ',' + CASE WHEN A.Sort IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Sort) END + ',' + CASE WHEN A.JournalizingScript IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.JournalizingScript) + ''')' END + ',' + CASE WHEN A.IsNotAccDateMod IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotAccDateMod) + ''')' END + ',' + CASE WHEN A.ElecEvidenceScript IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.ElecEvidenceScript) + ''')' END + ',' + CASE WHEN A.IsNotRowDel IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotRowDel) + ''')' END + ',' + CASE WHEN A.IsNotAccModify IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsNotAccModify) + ''')' END + ',' + CASE WHEN A.SourceRefFileColumnName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefFileColumnName) + ''')' END + ',' + CASE WHEN A.SourceRefJumpDataBlock IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefJumpDataBlock) + ''')' END + ',' + CASE WHEN A.SourceRefKeyColumnName1 IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefKeyColumnName1) + ''')' END + ',' + CASE WHEN A.SourceRefKeyColumnName2 IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefKeyColumnName2) + ''')' END + ',' + CASE WHEN A.SourceRefKeyColumnName3 IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefKeyColumnName3) + ''')' END + ',' + CASE WHEN A.SourceRefNoColumnName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefNoColumnName) + ''')' END + ',' + CASE WHEN A.SourceRefPgmSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.SourceRefPgmSeq) END + ',' + CASE WHEN A.SourceRefTableName IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.SourceRefTableName) + ''')' END + ',' + CASE WHEN A.IsEssGroupWare IS NULL THEN N'NULL' ELSE 'dbo._FWDBAXmlUnescaped(N''' + dbo._FWDBAXmlEscaped(A.IsEssGroupWare) + ''')' END +' FROM _TCACOMPANY'+CHAR(13)+' end' FROM _TACSlipKind AS A WITH(NOLOCK) 
  WHERE slipkind = @slipkind
   and companyseq=@CompanySeq

 union all

select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnv  WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' )'+CHAR(13)+'BEGIN '+CHAR(13)+ 'INSERT _TACSlipAutoEnv(CompanySeq, SlipAutoEnvSeq, SlipKindNo, ControlAccUnit, ControlAccUnitSheet, ControlSlipUnit, ControlSlipUnitSheet, ControlAccDate, ControlRemark1, ControlRemark2, ControlRemark3, LastUserSeq, LastDateTime) '+CHAR(13)+ + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END + ',' + CASE WHEN A.SlipKindNo IS NULL THEN N'NULL' ELSE 'N''' + (@copypgmid) + '''' END + ',' + CASE WHEN A.ControlAccUnit IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAccUnit) END + ',' + CASE WHEN A.ControlAccUnitSheet IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAccUnitSheet) END + ',' + CASE WHEN A.ControlSlipUnit IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSlipUnit) END + ',' + CASE WHEN A.ControlSlipUnitSheet IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSlipUnitSheet) END + ',' + CASE WHEN A.ControlAccDate IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAccDate) END + ',' + CASE WHEN A.ControlRemark1 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlRemark1) END + ',' + CASE WHEN A.ControlRemark2 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlRemark2) END + ',' + CASE WHEN A.ControlRemark3 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlRemark3) END + ',' + CASE WHEN A.LastUserSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.LastUserSeq) END + ',' + CASE WHEN A.LastDateTime IS NULL THEN N'NULL' ELSE '''' + CONVERT(NVARCHAR, A.LastDateTime, 121) + '''' END +' FROM _TCACOMPANY'+CHAR(13)+' end' FROM _TACSlipAutoEnv AS A WITH(NOLOCK) 
 WHERE SlipAutoEnvSeq = @slipkind
   and companyseq=@CompanySeq
 union all
select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnvKey  WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' AND '+'ControlSeq	='+CONVERT(VARCHAR(30), ISNULL(ControlSeq, 0))+' )'+CHAR(13)+'BEGIN '+CHAR(13)+ 'INSERT _TACSlipAutoEnvKey(CompanySeq, SlipAutoEnvSeq, ControlSeq, TableName, ColumnName, IsUsedQry, IsUsedInput) '+CHAR(13)+ + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END + ',' + CASE WHEN A.ControlSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSeq) END + ',' + CASE WHEN A.TableName IS NULL THEN N'NULL' ELSE 'N''' + (A.TableName) + '''' END + ',' + CASE WHEN A.ColumnName IS NULL THEN N'NULL' ELSE 'N''' + (A.ColumnName) + '''' END + ',' + CASE WHEN A.IsUsedQry IS NULL THEN N'NULL' ELSE 'N''' + (A.IsUsedQry) + '''' END + ',' + CASE WHEN A.IsUsedInput IS NULL THEN N'NULL' ELSE 'N''' + (A.IsUsedInput) + '''' END +' FROM _TCACOMPANY'+CHAR(13)+' end' FROM _TACSlipAutoEnvKey AS A WITH(NOLOCK) 
 WHERE SlipAutoEnvSeq = @slipkind
   and companyseq=@CompanySeq
 union all
select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipPgmControls WHERE '+'PgmSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyPgmseq, 0))+' AND '+'Serl	='+CONVERT(VARCHAR(30), ISNULL(Serl, 0))+' )'
+CHAR(13)+'BEGIN '+CHAR(13)+
 'INSERT _TACSlipPgmControls(CompanySeq, PgmSeq, Serl, ControlName, ControlType, DataBlockName, DataFieldName, DataFieldCd, CellType, ControlCaption, WordSeq, LastUserSeq, LastDateTime, CodeHelpConst, CodeHelpParams) '+CHAR(13)+
 + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END
 + ',' + CASE WHEN @copyPgmseq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyPgmseq) END
 + ',' + CASE WHEN A.Serl IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Serl) END
 + ',' + CASE WHEN A.ControlName IS NULL THEN N'NULL' ELSE 'N''' + (A.ControlName) + '''' END
 + ',' + CASE WHEN A.ControlType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlType) END
 + ',' + CASE WHEN A.DataBlockName IS NULL THEN N'NULL' ELSE 'N''' + (A.DataBlockName) + '''' END
 + ',' + CASE WHEN A.DataFieldName IS NULL THEN N'NULL' ELSE 'N''' + (A.DataFieldName) + '''' END
 + ',' + CASE WHEN A.DataFieldCd IS NULL THEN N'NULL' ELSE 'N''' + (A.DataFieldCd) + '''' END
 + ',' + CASE WHEN A.CellType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.CellType) END
 + ',' + CASE WHEN A.ControlCaption IS NULL THEN N'NULL' ELSE 'N''' + (A.ControlCaption) + '''' END
 + ',' + CASE WHEN A.WordSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.WordSeq) END
 + ',' + CASE WHEN A.LastUserSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.LastUserSeq) END
 + ',' + CASE WHEN A.LastDateTime IS NULL THEN N'NULL' ELSE '''' + CONVERT(NVARCHAR, A.LastDateTime, 121) + '''' END
 + ',' + CASE WHEN A.CodeHelpConst IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.CodeHelpConst) END
 + ',' + CASE WHEN A.CodeHelpParams IS NULL THEN N'NULL' ELSE 'N''' + (A.CodeHelpParams) + '''' END
 +' FROM _TCACOMPANY'+CHAR(13)+' end'
 FROM _TACSlipPgmControls AS A WITH(NOLOCK) 
       join _tacslipkind as b on b.pgmseq = a.Pgmseq  and a.companyseq =b.companyseq
 WHERE b.slipkind = @slipkind
   and a.companyseq=@CompanySeq
  union all
 
 select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnvRow WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' AND '+'Serl	='+CONVERT(VARCHAR(30), ISNULL(Serl, 0))+' )'
+CHAR(13)+'BEGIN '+CHAR(13)+
 'INSERT _TACSlipAutoEnvRow(CompanySeq, SlipAutoEnvSeq, Serl, AccSeq, UMCostType, SMDrOrCr, RowSort, IsAnti, IsDftAcc, IsSumProc, IsUseCash, DefaultEvidSeq, DefaultTaxKindSeq, SMCostItemKind, ControlAccSeq, ControlAccName, ControlAmt, ControlForAmt, ControlCurrSeq, ControlCurrName, ControlExRate, ControlDivExRate, ControlEvidSeq, ControlEvidName, ControlUMCostType, ControlUMCostTypeName, ControlCostItemSeq, ControlCostItemName, ControlCashDate, ControlCashMethod, ControlCashMethodName, ControlSummary1, ControlSummary2, ControlSummary3, ControlOnSlipSeq, ControlOnSlipID, ControlCostDeptSeq, ControlCostDeptName, ControlBgtDeptSeq, ControlBgtDeptName, ControlCostCCtrSeq, ControlCostCCtrName, ControlBgtCCtrSeq, ControlBgtCCtrName, ControlMtCostDeptSeq, ControlMtCostDeptName, ControlMtCostCCtrSeq, ControlMtCostCCtrName, ControlMtAmt, ControlSumCol1, ControlSumCol2, ControlSumCol3, ControlSumCol4, ControlSumCol5, ControlSelRow, ControlSourceSeq, ControlSourceID, DefaultSMCashMethod, ControlCoCustSeq, ControlCoCustName, ProcTypeName, ControlSMProcType, ControlSMProcTypeName, ControlControlSeq, ControlControlName, ControlCodeHelpSeq, ControlCodeHelpName, ControlProcAccType, ControlProcAccTypeName, ControlEtcCol1, ControlEtcCol2, ControlEtcCol3, ControlEtcCol4, ControlEtcCol5, ControlCashItemSeq, LastDateTime, LastUserSeq, RegDateTime, RegUserSeq) '+CHAR(13)+
 + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END
 + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END
 + ',' + CASE WHEN A.Serl IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Serl) END
 + ',' + CASE WHEN A.AccSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.AccSeq) END
 + ',' + CASE WHEN A.UMCostType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.UMCostType) END
 + ',' + CASE WHEN A.SMDrOrCr IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.SMDrOrCr) END
 + ',' + CASE WHEN A.RowSort IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.RowSort) END
 + ',' + CASE WHEN A.IsAnti IS NULL THEN N'NULL' ELSE 'N''' + (A.IsAnti) + '''' END
 + ',' + CASE WHEN A.IsDftAcc IS NULL THEN N'NULL' ELSE 'N''' + (A.IsDftAcc) + '''' END
 + ',' + CASE WHEN A.IsSumProc IS NULL THEN N'NULL' ELSE 'N''' + (A.IsSumProc) + '''' END
 + ',' + CASE WHEN A.IsUseCash IS NULL THEN N'NULL' ELSE 'N''' + (A.IsUseCash) + '''' END
 + ',' + CASE WHEN A.DefaultEvidSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.DefaultEvidSeq) END
 + ',' + CASE WHEN A.DefaultTaxKindSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.DefaultTaxKindSeq) END
 + ',' + CASE WHEN A.SMCostItemKind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.SMCostItemKind) END
 + ',' + CASE WHEN A.ControlAccSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAccSeq) END
 + ',' + CASE WHEN A.ControlAccName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAccName) END
 + ',' + CASE WHEN A.ControlAmt IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlAmt) END
 + ',' + CASE WHEN A.ControlForAmt IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlForAmt) END
 + ',' + CASE WHEN A.ControlCurrSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCurrSeq) END
 + ',' + CASE WHEN A.ControlCurrName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCurrName) END
 + ',' + CASE WHEN A.ControlExRate IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlExRate) END
 + ',' + CASE WHEN A.ControlDivExRate IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlDivExRate) END
 + ',' + CASE WHEN A.ControlEvidSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEvidSeq) END
 + ',' + CASE WHEN A.ControlEvidName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEvidName) END
 + ',' + CASE WHEN A.ControlUMCostType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlUMCostType) END
 + ',' + CASE WHEN A.ControlUMCostTypeName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlUMCostTypeName) END
 + ',' + CASE WHEN A.ControlCostItemSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostItemSeq) END
 + ',' + CASE WHEN A.ControlCostItemName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostItemName) END
 + ',' + CASE WHEN A.ControlCashDate IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCashDate) END
 + ',' + CASE WHEN A.ControlCashMethod IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCashMethod) END
 + ',' + CASE WHEN A.ControlCashMethodName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCashMethodName) END
 + ',' + CASE WHEN A.ControlSummary1 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSummary1) END
 + ',' + CASE WHEN A.ControlSummary2 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSummary2) END
 + ',' + CASE WHEN A.ControlSummary3 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSummary3) END
 + ',' + CASE WHEN A.ControlOnSlipSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlOnSlipSeq) END
 + ',' + CASE WHEN A.ControlOnSlipID IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlOnSlipID) END
 + ',' + CASE WHEN A.ControlCostDeptSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostDeptSeq) END
 + ',' + CASE WHEN A.ControlCostDeptName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostDeptName) END
 + ',' + CASE WHEN A.ControlBgtDeptSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlBgtDeptSeq) END
 + ',' + CASE WHEN A.ControlBgtDeptName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlBgtDeptName) END
 + ',' + CASE WHEN A.ControlCostCCtrSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostCCtrSeq) END
 + ',' + CASE WHEN A.ControlCostCCtrName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCostCCtrName) END
 + ',' + CASE WHEN A.ControlBgtCCtrSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlBgtCCtrSeq) END
 + ',' + CASE WHEN A.ControlBgtCCtrName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlBgtCCtrName) END
 + ',' + CASE WHEN A.ControlMtCostDeptSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlMtCostDeptSeq) END
 + ',' + CASE WHEN A.ControlMtCostDeptName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlMtCostDeptName) END
 + ',' + CASE WHEN A.ControlMtCostCCtrSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlMtCostCCtrSeq) END
 + ',' + CASE WHEN A.ControlMtCostCCtrName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlMtCostCCtrName) END
 + ',' + CASE WHEN A.ControlMtAmt IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlMtAmt) END
 + ',' + CASE WHEN A.ControlSumCol1 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSumCol1) END
 + ',' + CASE WHEN A.ControlSumCol2 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSumCol2) END
 + ',' + CASE WHEN A.ControlSumCol3 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSumCol3) END
 + ',' + CASE WHEN A.ControlSumCol4 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSumCol4) END
 + ',' + CASE WHEN A.ControlSumCol5 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSumCol5) END
 + ',' + CASE WHEN A.ControlSelRow IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSelRow) END
 + ',' + CASE WHEN A.ControlSourceSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSourceSeq) END
 + ',' + CASE WHEN A.ControlSourceID IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSourceID) END
 + ',' + CASE WHEN A.DefaultSMCashMethod IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.DefaultSMCashMethod) END
 + ',' + CASE WHEN A.ControlCoCustSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCoCustSeq) END
 + ',' + CASE WHEN A.ControlCoCustName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCoCustName) END
 + ',' + CASE WHEN A.ProcTypeName IS NULL THEN N'NULL' ELSE 'N''' + (A.ProcTypeName) + '''' END
 + ',' + CASE WHEN A.ControlSMProcType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSMProcType) END
 + ',' + CASE WHEN A.ControlSMProcTypeName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlSMProcTypeName) END
 + ',' + CASE WHEN A.ControlControlSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlControlSeq) END
 + ',' + CASE WHEN A.ControlControlName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlControlName) END
 + ',' + CASE WHEN A.ControlCodeHelpSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCodeHelpSeq) END
 + ',' + CASE WHEN A.ControlCodeHelpName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCodeHelpName) END
 + ',' + CASE WHEN A.ControlProcAccType IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlProcAccType) END
 + ',' + CASE WHEN A.ControlProcAccTypeName IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlProcAccTypeName) END
 + ',' + CASE WHEN A.ControlEtcCol1 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEtcCol1) END
 + ',' + CASE WHEN A.ControlEtcCol2 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEtcCol2) END
 + ',' + CASE WHEN A.ControlEtcCol3 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEtcCol3) END
 + ',' + CASE WHEN A.ControlEtcCol4 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEtcCol4) END
 + ',' + CASE WHEN A.ControlEtcCol5 IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlEtcCol5) END
 + ',' + CASE WHEN A.ControlCashItemSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ControlCashItemSeq) END
 + ',' + CASE WHEN A.LastDateTime IS NULL THEN N'NULL' ELSE '''' + CONVERT(NVARCHAR, A.LastDateTime, 121) + '''' END
 + ',' + CASE WHEN A.LastUserSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.LastUserSeq) END
 + ',' + CASE WHEN A.RegDateTime IS NULL THEN N'NULL' ELSE '''' + CONVERT(NVARCHAR, A.RegDateTime, 121) + '''' END
 + ',' + CASE WHEN A.RegUserSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.RegUserSeq) END
 +' FROM _TCACOMPANY'+CHAR(13)+' end'
 FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK) 
 where  SlipAutoEnvSeq=@slipkind 
   and companyseq=@CompanySeq
  union all
 
 select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnvRem WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' AND '+'Serl	='+CONVERT(VARCHAR(30), ISNULL(Serl, 0))+'and '+ 'RemSeq	='+CONVERT(VARCHAR(30), ISNULL(a.RemSeq, 0))+' )'
+CHAR(13)+'BEGIN '+CHAR(13)+
 'INSERT _TACSlipAutoEnvRem(CompanySeq, SlipAutoEnvSeq, Serl, RemSeq, RemControlSeq, RemControlSheet) '+CHAR(13)+
 + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END
 + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END
 + ',' + CASE WHEN A.Serl IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Serl) END
 + ',' + CASE WHEN A.RemSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.RemSeq) END
 + ',' + CASE WHEN A.RemControlSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.RemControlSeq) END
 + ',' + CASE WHEN A.RemControlSheet IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.RemControlSheet) END
 +' FROM _TCACOMPANY'+CHAR(13)+' end'
 FROM _TACSlipAutoEnvRem AS A WITH(NOLOCK) 
  where SlipAutoEnvSeq=@slipkind 
   and companyseq=@CompanySeq
  union all
select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnvRowCol  WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' AND '+'Serl	='+CONVERT(VARCHAR(30), ISNULL(Serl, 0))+' AND '+'ColKey	='+CONVERT(VARCHAR(30), ISNULL(ColKey, 0))+' )'+CHAR(13)+'BEGIN '+CHAR(13)+ 'INSERT _TACSlipAutoEnvRowCol(CompanySeq, SlipAutoEnvSeq, Serl, ColKey, EnvControlSeq) '+CHAR(13)+ + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END + ',' + CASE WHEN A.Serl IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Serl) END + ',' + CASE WHEN A.ColKey IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ColKey) END + ',' + CASE WHEN A.EnvControlSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.EnvControlSeq) END +' FROM _TCACOMPANY'+CHAR(13)+' end' FROM _TACSlipAutoEnvRowCol AS A WITH(NOLOCK) 
 where  SlipAutoEnvSeq=@slipkind 
   and companyseq=@CompanySeq


 union all
 select 'IF NOT EXISTS(SELECT 1 FROM _TACSlipAutoEnvRowCol WHERE '+'SlipAutoEnvSeq	='+CONVERT(VARCHAR(30), ISNULL(@copyslipkind, 0))+' AND '+'Serl	='+CONVERT(VARCHAR(30), ISNULL(Serl, 0))+' AND '+'ColKey	='+CONVERT(VARCHAR(30), ISNULL(ColKey, 0))+' )'
+CHAR(13)+'BEGIN '+CHAR(13)+
 'INSERT _TACSlipAutoEnvRowCol(CompanySeq, SlipAutoEnvSeq, Serl, ColKey, EnvControlSeq) '+CHAR(13)+
 + 'SELECT '+ CASE WHEN 'CompanySeq' IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, 'CompanySeq') END
 + ',' + CASE WHEN @copyslipkind IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, @copyslipkind) END
 + ',' + CASE WHEN A.Serl IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.Serl) END
 + ',' + CASE WHEN A.ColKey IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.ColKey) END
 + ',' + CASE WHEN A.EnvControlSeq IS NULL THEN N'NULL' ELSE CONVERT(NVARCHAR, A.EnvControlSeq) END
 +' FROM _TCACOMPANY'+CHAR(13)+' end'
 FROM _TACSlipAutoEnvRowCol AS A WITH(NOLOCK) 
 where  SlipAutoEnvSeq=@slipkind 
   and companyseq=@CompanySeq


