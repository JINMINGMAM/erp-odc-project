-- =============================================
-- 프로그램 ID 매핑 및 업데이트 스크립트
-- 설명: 기존 프로그램 ID를 새로운 프로그램 ID로 매핑하여 업데이트
-- 작성일: 2026-04-09
-- =============================================
 
-- =============================================
-- 1. 백업 테이블 생성 (실행 전 필수)
-- =============================================
-- 실제 업데이트 전에 백업 테이블 생성 (주석 해제 후 실행)
/*
SELECT * 
INTO backup_20260409_twcnfprocessmenuitem 
FROM _twcnfprocessmenuitem;
*/
 
 
-- =============================================
-- 2. 프로그램 ID 매핑 테이블 생성
-- =============================================
WITH ProgramMapping AS (
    -- 기존 프로그램 ID → 새 프로그램 ID (pemtron 버전) 매핑
    SELECT 'FrmWPJTProjectList'             AS pgmid_from,
           'FrmWPJTProjectList_pemtron'     AS pgmid_to
    UNION ALL 
    SELECT 'FrmWPJTSupplyProgList',
           'FrmWPJTSupplyProgList_pemtron'
    UNION ALL 
    SELECT 'FrmWLGEtcOutMatReq',
           'FrmWLGEtcOutMatReq_pemtron'
    UNION ALL 
    SELECT 'FrmWLGEtcOutMatReqItemList',
           'FrmWLGEtcOutMatReqItemList_pemtron'
    UNION ALL 
    SELECT 'FrmWLGWHStockDetailList',
           'FrmWLGWHStockDetailList_pemtron'
    UNION ALL 
    SELECT 'FrmWLGEtcOutMat',
           'FrmWLGEtcOutMat_pemtron'
    UNION ALL 
    SELECT 'FrmWLGEtcOutMatItemList',
           'FrmWLGEtcOutMatItemList_pemtron'
    UNION ALL 
    SELECT 'FrmWPDQCTestKindASItem',
           'FrmWPDQCTestKindASItem_pemtron'
    UNION ALL 
    SELECT 'FrmWPJTProjectListAdd',
           'FrmWPJTProjectListAdd_pemtron'
)
 
-- =============================================
-- 3. 프로그램 시퀀스 매핑 테이블 생성 (임시 테이블)
-- =============================================
SELECT 
    from_pgm.pgmseq AS from_pgmseq,
    to_pgm.pgmseq AS to_pgmseq
INTO #ProgramSeqMapping
FROM ProgramMapping AS mapping
    INNER JOIN _tcapgm AS from_pgm ON from_pgm.pgmid = mapping.pgmid_from
    INNER JOIN _tcapgm AS to_pgm ON to_pgm.pgmid = mapping.pgmid_to;
 
 
-- =============================================
-- 4. 매핑 통계 확인
-- =============================================
SELECT 
    menu.PgmSeq,
    COUNT(map.to_pgmseq) AS mapping_count
FROM _twcnfprocessmenuitem AS menu
    INNER JOIN #ProgramSeqMapping AS map ON map.from_pgmseq = menu.PgmSeq
GROUP BY menu.PgmSeq
ORDER BY COUNT(map.to_pgmseq) DESC;
 
 
-- =============================================
-- 5. 업데이트 대상 확인 (실행 전 검증)
-- =============================================
SELECT 
    menu.ProcessMenuSeq,
    menu.PgmSeq AS current_pgmseq,
    map.to_pgmseq AS new_pgmseq,
    from_pgm.pgmid AS current_pgmid,
    to_pgm.pgmid AS new_pgmid
FROM _twcnfprocessmenuitem AS menu
    INNER JOIN #ProgramSeqMapping AS map ON map.from_pgmseq = menu.PgmSeq
    LEFT JOIN _tcapgm AS from_pgm ON from_pgm.pgmseq = menu.PgmSeq
    LEFT JOIN _tcapgm AS to_pgm ON to_pgm.pgmseq = map.to_pgmseq
ORDER BY menu.ProcessMenuSeq, menu.PgmSeq;
 
 
-- =============================================
-- 6. 프로그램 시퀀스 업데이트 (주의: 실제 데이터 변경)
-- =============================================
-- 실제 업데이트 실행 (주석 해제 후 실행)

UPDATE menu
SET PgmSeq = map.to_pgmseq
FROM _twcnfprocessmenuitem AS menu
    INNER JOIN #ProgramSeqMapping AS map ON map.from_pgmseq = menu.PgmSeq;
 
-- 업데이트 결과 확인
SELECT @@ROWCOUNT AS updated_rows;

 
 
-- =============================================
-- 7. 업데이트 후 검증
-- =============================================
-- 업데이트 후 실행하여 결과 확인

SELECT 
    menu.ProcessMenuSeq,
    menu.PgmSeq,
    pgm.pgmid,
    pgm.caption
FROM _twcnfprocessmenuitem AS menu
    LEFT JOIN _tcapgm AS pgm ON pgm.pgmseq = menu.PgmSeq
WHERE pgm.pgmid LIKE '%_pemtron'
ORDER BY menu.ProcessMenuSeq;

 
 
-- =============================================
-- 8. 임시 테이블 정리
-- =============================================
DROP TABLE #ProgramSeqMapping;
 