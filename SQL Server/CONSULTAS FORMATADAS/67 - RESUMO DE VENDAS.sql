use SBODemoBR_31_10_2020 
 
go 
 
--RESUMO DE VENDAS

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pcdJBC_ResumoDeVendas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[pcdJBC_ResumoDeVendas]
GO

USE SBODemoBR_31_10_2020
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc  [dbo].[pcdJBC_ResumoDeVendas]
  @DateIni DateTime,@DateFim DateTime
as

	SELECT
	  'Nota de Venda' as Tipo,
	   OINV.CardCode,
	   OINV.CardName,
	   OINV.DocDate,
	   OINV.DocDueDate 'VENCIMENTO',
	   DATEPART(MONTH, OINV.DocDate) 'MES',
	   DATEPART(YEAR, OINV.DocDate) 'ANO',
	   OINV.DocEntry,
	   OINV.Serial,
	   OINV.Installmnt 'PRESTACOES',
	   INV1.ItemCode,
	   INV1.Dscription,
	   INV1.Quantity,
	   INV1.Price,
	   (
		  INV1.Quantity * INV1.Price
	   )
	   'TOTAL' 	--,*
	FROM
	   OINV 
	   INNER JOIN
		  INV1 INV1 
		  ON INV1.DocEntry = OINV.DocEntry 
	WHERE
	   CANCELED = 'N' 
	   AND OINV.DocDate BETWEEN @DateIni AND @DateIni
	UNION ALL
	SELECT
	   'Devolução' as Tipo,
	   ORIN.CardCode,
	   ORIN.CardName,
	   ORIN.DocDate,
	   ORIN.DocDueDate 'VENCIMENTO',
	   DATEPART(MONTH, ORIN.DocDate) 'MES',
	   DATEPART(YEAR, ORIN.DocDate) 'ANO',
	   ORIN.DocEntry,
	   ORIN.Serial,
	   ORIN.Installmnt,
	   RIN1.ItemCode,
	   RIN1.Dscription,
	   RIN1.Quantity * - 1,
	   RIN1.Price,
	   (
			(RIN1.Quantity * RIN1.Price) * - 1
	   )
	   'TOTAL'
	FROM
	   ORIN 
	   INNER JOIN
		  RIN1 RIN1 
		  ON RIN1.DocEntry = ORIN.DocEntry 
	WHERE
	   CANCELED = 'N' 
	   AND rin1.BaseEntry IN 
	   (
		  SELECT
			 OINV .DocEntry 
		  FROM
			 OINV 
			 INNER JOIN
				INV1 INV1 
				ON INV1.DocEntry = OINV.DocEntry 
		  WHERE
			 CANCELED = 'N' 
			 AND OINV.DocDate BETWEEN @DateIni AND @DateIni
	   )

	ORDER BY
	   OINV.CardCode,
	   OINV.DocDate
go


/*Select  1  From OINV T0 Where T0.DocDate =[%0]*/
declare @DateIni DateTime

/*Select  1  From OINV T0 Where T0.DocDate =[%1]*/
declare @DateFim DateTime
SET @DateIni = '[%0]'
SET @DateFim = '[%1]'


execute [pcdJBC_ResumoDeVendas] @DateIni,@DateFim