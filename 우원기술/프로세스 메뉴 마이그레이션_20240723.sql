
select * from _TWCNFProcessMenu 
where datediff(day,lastdatetime,getdate())<=7   
--select * from _TCOMCreateSeqMax where tablename = '_TWCNFProcessMenu'
--업무 공통테이블 채번
select * from _TCOMBisCreateSeqMax  where tablename = '_TWCNFProcessMenu'

/*
update _TCOMBisCreateSeqMax
set MaxSeq = 214000023
from _TCOMBisCreateSeqMax
here tablename = '_TWCNFProcessMenu'

*/


BEGIN TRAN
DECLARE @WhereScript1   NVARCHAR(1000),
        @WhereScript2   NVARCHAR(1000),
        @Menu           NVARCHAR(1)   ,
        @MenuLan        NVARCHAR(1)   ,
        @MenuItem       NVARCHAR(1)   ,
        @MenuItemLan    NVARCHAR(1)   ,
        @MenuBM         NVARCHAR(1)   ,
        @Sql            NVARCHAR(MAX) ,
        @NewCompanySeq  INT           ,
        @Backup         NVARCHAR(100)
-- SELECT * FROM _TWCNFProcessMenu WHERE ProcessMenuID IN ('ACE-150')
-- 입력 부분
SELECT @WhereScript2  = 'ProcessMenuSeq IN (214000023)' -- Patch Script 작성하기 위한 프로세스메뉴 내부코드

SELECT @Menu          = '1'           -- _TWCNFProcessMenu              Table Patch Script 작성 여부(1 OR 0)
SELECT @MenuLan       = '1'           -- _TWCNFProcessMenuLanguag       Table Patch Script 작성 여부(1 OR 0)
SELECT @MenuItem      = '1'           -- _TWCNFProcessMenuItem          Table Patch Script 작성 여부(1 OR 0)
SELECT @MenuItemLan   = '1'           -- _TWCNFProcessMenuItemLanguage  Table Patch Script 작성 여부(1 OR 0)
SELECT @MenuBM        = '0'           -- _TWCNFProcessMenuBM            Table Patch Script 작성 여부(1 OR 0)
SELECT @NewCompanySeq = '1'           -- 고객사 법인내부코드
SELECT @Backup        = 'BAK20191219' -- BACKUP Table 생성 시 Parameter
-- 입력 부분 종료

SELECT @WhereScript1  = 'WHERE CompanySeq = 1 AND ' + @WhereScript2
SELECT @Sql = 'BEGIN TRAN'

-- 백업 Table 만들기
--SELECT @Sql = @Sql + CHAR(13) + '-- 백업 Table 만들기'
--IF @Menu    = '1'
--    SELECT @Sql = @Sql + CHAR(13) + 'SELECT * INTO ' + @Backup + '_TWCNFProcessMenu FROM _TWCNFProcessMenu WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
--IF @MenuLan = '1'
--    SELECT @Sql = @Sql + CHAR(13) + 'SELECT * INTO ' + @Backup + '_TWCNFProcessMenuLanguage FROM _TWCNFProcessMenuLanguage WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
--IF @MenuItem = '1'
--    SELECT @Sql = @Sql + CHAR(13) + 'SELECT * INTO ' + @Backup + '_TWCNFProcessMenuItem FROM _TWCNFProcessMenuItem WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
--IF @MenuItemLan = '1'
--    SELECT @Sql = @Sql + CHAR(13) + 'SELECT * INTO ' + @Backup + '_TWCNFProcessMenuItemLanguage FROM _TWCNFProcessMenuItemLanguage WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
--IF @MenuBM = '1'
--    SELECT @Sql = @Sql + CHAR(13) + 'SELECT * INTO ' + @Backup + '_TWCNFProcessMenuBM FROM _TWCNFProcessMenuBM WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2

-- Data 삭제
SELECT @Sql = @Sql + CHAR(13) + '-- Data 삭제'
IF @Menu    = '1'
    SELECT @Sql = @Sql + CHAR(13) + 'DELETE _TWCNFProcessMenu FROM _TWCNFProcessMenu WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
IF @MenuLan = '1'                    
    SELECT @Sql = @Sql + CHAR(13) + 'DELETE _TWCNFProcessMenuLanguage FROM _TWCNFProcessMenuLanguage WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
IF @MenuItem = '1'                   
    SELECT @Sql = @Sql + CHAR(13) + 'DELETE _TWCNFProcessMenuItem FROM _TWCNFProcessMenuItem WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
IF @MenuItemLan = '1'                
    SELECT @Sql = @Sql + CHAR(13) + 'DELETE _TWCNFProcessMenuItemLanguage FROM _TWCNFProcessMenuItemLanguage WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
IF @MenuBM = '1'                     
    SELECT @Sql = @Sql + CHAR(13) + 'DELETE _TWCNFProcessMenuBM FROM _TWCNFProcessMenuBM WITH(NOLOCK) WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2

Print @Sql

IF @Menu = '1'
    EXEC INSERTSCRIPT '_TWCNFProcessMenu', @WhereScript1, @NewCompanySeq
IF @MenuLan = '1'                    
    EXEC INSERTSCRIPT '_TWCNFProcessMenuLanguage', @WhereScript1, @NewCompanySeq
IF @MenuItem = '1'                   
    EXEC INSERTSCRIPT '_TWCNFProcessMenuItem', @WhereScript1, @NewCompanySeq
IF @MenuItemLan = '1'                
    EXEC INSERTSCRIPT '_TWCNFProcessMenuItemLanguage', @WhereScript1, @NewCompanySeq
IF @MenuBM = '1'                     
    EXEC INSERTSCRIPT '_TWCNFProcessMenuBM', @WhereScript1, @NewCompanySeq

SELECT @Sql = ''

SELECT @Sql = @Sql + CHAR(13) + '-- 권한재집계'
SELECT @Sql = @Sql + CHAR(13) + 'UPDATE A SET A.ChgWorkDate = GETDATE(), A.IsWork = 0 FROM OTCAUserCheckGathering AS A'
SELECT @Sql = @Sql + CHAR(13) + '-- 썸네일 초기화'
SELECT @Sql = @Sql + CHAR(13) + 'UPDATE A SET A.ItemPhotoImgURL = NULL, A.ItemPhotoImgKey = NULL FROM _TWCNFPRocessMenuLanguage AS A WHERE CompanySeq = ' + CONVERT(NVARCHAR, @NewCompanySeq) + ' AND ' + @WhereScript2
--SELECT @Sql = @Sql + CHAR(13) + '-- 사용여부 UPDATE'
--SELECT @Sql = @Sql + CHAR(13) + 'UPDATE A SET A.IsUse = B.IsUse FROM _TWCNFPRocessMenu AS A JOIN ' + @Backup + '_TWCNFPRocessMenu AS B ON A.CompanySeq = B.CompanySeq AND A.ProcessMenuSeq = B.ProcessMenuSeq'
SELECT @Sql = @Sql + CHAR(13) + 'ROLLBACK TRAN'

Print @Sql
ROLLBACK TRAN

