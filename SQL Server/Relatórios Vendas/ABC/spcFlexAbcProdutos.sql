USE [SDO_DESENV]
GO

/****** Object:  StoredProcedure [dbo].[spcAbcProdutos]    Script Date: 30/11/2016 16:42:26 ******/
DROP PROCEDURE [dbo].[spcAbcProdutos]
GO

/****** Object:  StoredProcedure [dbo].[spcAbcProdutos]    Script Date: 30/11/2016 16:42:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spcAbcProdutos]
  @dt_inicial  SMALLDATETIME    
 ,@dt_final    SMALLDATETIME
 ,@ordenar_por CHAR(01)
  WITH ENCRYPTION  
AS

--Variaveis padroes       
DECLARE @vl_faturamento  INT      
     ,  @qt_faturada     DECIMAL(10,4)      
     ,  @cd_empresaF     INT      
      
           
      
--TABELAS TMP      
CREATE TABLE #tmpRetorno(cd_item CHAR(40), descricao CHAR(400), vl_faturamento MONEY, qtde DECIMAL(10,4),
                          percentualvL DECIMAL(10,4), percentualqt DECIMAL(10,4))      

INSERT INTO #tmpRetorno       
 SELECT INV1.ItemCode, INV1.Dscription, SUM(INV1.LineTotal), SUM(INV1.Quantity), 0, 0
  FROM OINV, INV1
 WHERE OINV.DocEntry = INV1.DocEntry
   AND OINV.ObjType = 13
   AND OINV.CANCELED = 'N'
   AND OINV.DocDate BETWEEN @dt_inicial AND @dt_final
   --AND OINV.DocEntry NOT IN (SELECT BaseRef 
   --                            FROM RIN1, ORIN
   --                           WHERE RIN1.DocEntry = ORIN.DocEntry
   --                             AND ORIN.DocDate BETWEEN @dt_inicial AND @dt_final)
 GROUP BY INV1.ItemCode, INV1.Dscription

SELECT @vl_faturamento = ISNULL(SUM(vl_faturamento),0) , @qt_faturada = ISNULL(SUM(qtde),0)      
  FROM #tmpRetorno      

UPDATE #tmpRetorno SET percentualvL = vl_faturamento / @vl_faturamento      
UPDATE #tmpRetorno SET percentualqt = qtde / @qt_faturada      

 IF @ordenar_por = 'V'
	 SELECT  *
		 FROM #tmpRetorno a
		ORDER BY a.vl_faturamento DESC
 ELSE
	 SELECT  *
		 FROM #tmpRetorno a
		ORDER BY a.qtde DESC

DROP TABLE #tmpRetorno
GO


