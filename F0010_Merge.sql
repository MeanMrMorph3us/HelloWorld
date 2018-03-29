USE [iSimPlan]
GO
/****** Object:  StoredProcedure [Imports].[F0010_Manual]    Script Date: 3/27/2018 2:49:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

   /*
	Author		:	Shaun Johnson
	Edit date	:	18-08-2017
	Description	:	added UPDATE isActive for 119 and 120
  */
ALTER PROCEDURE [Imports].[F0010_Manual]
(
	 @LinkedServer	VARCHAR(25)='MCBSPR01_DDMRP'
	,@MainLibrary	VARCHAR(25)='JDWDTA92P'
	 
)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT	@LinkedServer = J.LinkedServer, 
			@MainLibrary = J.MainLibrary	   
	FROM	[Imports].[JDEConfig] J			
	WHERE J.[Version] = '92'

	DECLARE @SQL VARCHAR(MAX)	
			--,@LinkedServer	VARCHAR(25)='MCBSPR03_92'
			--,@MainLibrary	VARCHAR(25)='JDWDTA92P'

DECLARE @resultsTable TABLE
(
    
    CCCO [VARCHAR](5),
    CCNAME [VARCHAR](30),
    isActive BIT,
    [UsrID] [VARCHAR](25),
    [TMStamp] [DATETIME]
);

	SET @SQL = 
'SELECT CCCO, CCNAME,0 ,''SQL_Imports'',GETDATE()
FROM OPENQUERY(' + @LinkedServer + 
',''SELECT F0010.CCCO, F0010.CCNAME
FROM ' + @MainLibrary + '.F0010 F0010
WITH UR'')'
  
	INSERT INTO @resultsTable
	EXEC(@SQL)	
	
	MERGE JDWDTA92P.F0010 AS C
	USING @resultsTable AS CImport
	ON (
		   C.[CCCO] = CImport.[CCCO]
	   )	
	WHEN NOT MATCHED THEN
		INSERT
		(
			CCCO,
			CCNAME,
			isActive,
			[UsrID],
			[TMStamp]
		)
		VALUES
		(   CImport.CCCO,
			CImport.CCNAME,
			CImport.isActive,
			CImport.[UsrID],
			CImport.[TMStamp]
		)	
	WHEN MATCHED AND (ISNULL(C.[CCNAME], '') <> ISNULL(CImport.[CCNAME], ''))            
	THEN
	UPDATE SET C.CCNAME = CImport.CCNAME;			
	
			
	UPDATE JDWDTA92P.F0010 SET isActive = 1 WHERE CCCO IN (
	'00119',
	'00120'
	)
END
