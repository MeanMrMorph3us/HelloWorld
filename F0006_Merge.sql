USE [iSimPlan]
GO
/****** Object:  StoredProcedure [Imports].[F0006_Manual]    Script Date: 3/27/2018 2:00:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  /*
	Author		:	Shaun Johnson
	Edit date	:	18-08-2017
	Description	:	added WHERE F0010.CCCO IN (' + @ActiveCompanyList + ')
  */
 
ALTER PROCEDURE [Imports].[F0006_Manual]
(
	 @LinkedServer	VARCHAR(25)='MCBSPR01_DDMRP'
	,@MainLibrary	VARCHAR(25)='JDWDTA92P'
	,@EQ_MCSTYL VARCHAR(10)  = 'BP,BS'
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	 @SQL VARCHAR(MAX)	
			
			--,@LinkedServer	VARCHAR(25)='MCBSPR03_92'
			--,@MainLibrary	VARCHAR(25)='JDWDTA92P'
			--,@EQ_MCSTYL VARCHAR(10)  = 'BP,BS'
	
	SELECT	@LinkedServer = J.LinkedServer, 
			@MainLibrary = J.MainLibrary	   
	FROM	[Imports].[JDEConfig] J			
	WHERE J.[Version] = '92'

	DECLARE @ActiveCompanyList VARCHAR(100)
	SELECT	@ActiveCompanyList =  COALESCE(@ActiveCompanyList + ', ', '') +
			CAST(CCCO AS VARCHAR(5)) FROM  [JDWDTA92P].[F0010] WHERE IsActive = 1
 
	DECLARE @EQRange VARCHAR(200)
	SELECT @EQRange = Imports.StringifyJDERange(@EQ_MCSTYL)

	DECLARE @resultsTable TABLE
(
    [F0010Key] [UNIQUEIDENTIFIER],
    MCMCU [VARCHAR](12),
    MCDL01 [VARCHAR](30),
    MCCO [VARCHAR](5),
    MCSTYL [VARCHAR](2),
    MCDC [VARCHAR](40),
    [UsrID] [VARCHAR](25),
    [TMStamp] [DATETIME]
);

	SET @SQL =	'SELECT F0010Key
						,A.MCMCU
						,A.MCDL01
						,A.MCCO
						,A.MCSTYL
						,A.MCDC
						,''SQL_Imports''
						,GETDATE()
					FROM OPENQUERY(' + @LinkedServer + ',
						''SELECT                        
							LTRIM(RTRIM(F0006.MCMCU)) AS MCMCU
							,F0006.MCDL01 AS MCDL01
							,F0006.MCCO AS MCCO
							,F0006.MCSTYL AS MCSTYL
							,F0006.MCDC AS MCDC
							,F0010.CCCO AS CCCO

						FROM ' + @MainLibrary + '.F0006  F0006
						INNER JOIN ' + @MainLibrary + '.F0010 F0010
							ON  F0006.MCCO = F0010.CCCO 
							WHERE F0010.CCCO IN (' + @ActiveCompanyList + ')
							AND MCCO IN (' + @ActiveCompanyList + ')
							AND MCSTYL IN (' + @EQRange + ')
				    WITH UR'') A
					INNER JOIN [JDWDTA92P].[F0010] JDWF0010 ON A.CCCO = JDWF0010.CCCO'
    
	INSERT INTO @resultsTable
	EXEC(@SQL)			
	
MERGE JDWDTA92P.F0006 AS B
USING @resultsTable AS BImport
ON (
       B.[MCMCU] = BImport.[MCMCU]
       AND B.[MCCO] = BImport.[MCCO]
	   AND B.[MCSTYL] = BImport.[MCSTYL]
   )	
WHEN NOT MATCHED THEN
    INSERT
    (
		[F0010Key],
		MCMCU,
		MCDL01,
		MCCO,
		MCSTYL,
		MCDC,
		[UsrID],
		[TMStamp]
    )
    VALUES
    (   BImport.[F0010Key],
		BImport.MCMCU,
		BImport.MCDL01,
		BImport.MCCO,
		BImport.MCSTYL,
		BImport.MCDC,
		BImport.[UsrID],
		BImport.[TMStamp]
    )	
WHEN MATCHED AND (ISNULL(B.[MCDL01], '') <> ISNULL(BImport.[MCDL01], ''))
                 OR (ISNULL(B.[MCDC], '') <> ISNULL(BImport.[MCDC], ''))
                  THEN
 UPDATE SET B.[MCDL01] = BImport.[MCDL01],
               B.[MCDC] = BImport.[MCDC];


	 
END



