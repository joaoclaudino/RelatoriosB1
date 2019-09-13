USE [SDO_DESENV]
GO

/****** Object:  StoredProcedure [dbo].[spcFaturamentoPorCliente]    Script Date: 04/22/2014 10:00:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcFaturamentoPorCliente]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcFaturamentoPorCliente]
GO

USE [SDO_DESENV]
GO

/****** Object:  StoredProcedure [dbo].[spcFaturamentoPorCliente]    Script Date: 04/22/2014 10:00:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--exec spcFaturamentoPorCliente '2013-01-01', '2013-12-31',0

CREATE PROCEDURE [dbo].[spcFaturamentoPorCliente]    
  @dt_inicial SMALLDATETIME,    
  @dt_final SMALLDATETIME,
  @NotasFaturamento bit
   WITH ENCRYPTION   
AS    
 
DECLARE @vvl_tot_mercadoria MONEY    
DECLARE @vvl_tot_geral MONEY    
    
    
DECLARE @tmpRet TABLE (ObjType nvarchar(4) null,DocEntry INT NULL, Serial INT NULL, DocDate SMALLDATETIME, CardCode CHAR(15) NULL,    
                       CardName VARCHAR(200) NULL, vl_mercadoria MONEY NULL, vl_total MONEY NULL, DocKey INT)    
    
INSERT INTO @tmpRet    
 SELECT DISTINCT 
	OINV.ObjType,OINV.DocEntry, OINV.Serial, OINV.DocDate, OINV.CardCode, OINV.CardName, 
	OINV.DocTotalSy - OINV.VatSum - OINV.TotalExpns vl_mercadoria, OINV.DocTotalSy, OINV.DocEntry    --INV1.DocEntry    
  FROM OINV  
	--INNER JOIN INV1 ON INV1.DocEntry = OINV.DocEntry  
 WHERE OINV.ObjType = 13    
   AND OINV.CANCELED = 'N'    
   AND OINV.DocDate BETWEEN @dt_inicial AND @dt_final
   --AND INV1.LineNum NOT IN(SELECT y.BaseLine
			--               FROM ORIN x, RIN1 y
			--		       WHERE x.DocEntry = y.DocEntry AND
			--			         x.ObjType = y.ObjType AND
			--				     y.BaseEntry = INV1.DocEntry AND
			--					 y.BaseType = INV1.ObjType AND
			--					 x.SeqCode = 1)
 union all
 SELECT DISTINCT	
	ORIN.ObjType,ORIN.DocEntry, ORIN.Serial, ORIN.DocDate, ORIN.CardCode, ORIN.CardName, 
	(ORIN.DocTotalSy - ORIN.VatSum - ORIN.TotalExpns)*-1 vl_mercadoria, ORIN.DocTotalSy *-1, ORIN.DocEntry
  FROM ORIN  	
 WHERE ORIN.ObjType = 14
   AND ORIN.CANCELED = 'N'    
   AND ORIN.DocDate BETWEEN @dt_inicial AND @dt_final		
   and @NotasFaturamento=0		
 ORDER BY 6,1--OINV.CardCode    

    
SELECT *    
  FROM @tmpRet
GO
--select * from ORIN

--select distinct ObjType from OINV
--select distinct ObjType from ORIN
