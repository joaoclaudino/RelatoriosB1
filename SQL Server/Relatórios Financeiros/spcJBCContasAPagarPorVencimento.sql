USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasAPagarPorVencimento]    Script Date: 06/09/2015 09:17:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcJBCContasAPagarPorVencimento]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcJBCContasAPagarPorVencimento]
GO

USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasAPagarPorVencimento]    Script Date: 06/09/2015 09:17:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--select  'V' 'Tipo','Dt. Vencimento' 'Desc' union all select  'LC','Dt. Lançamento'


CREATE PROC [dbo].[spcJBCContasAPagarPorVencimento] (
	@CarCode nvarchar(15),
	@dateini date,
	@datefim date,
	@tpdata  varchar(2)

)
with encryption
as 
begin

--execute [spcJBCContasAPagarPorVencimento] '*','2010-01-01 00:00:00','2020-01-01 00:00:00','2010-01-01 00:00:00','2020-01-01 00:00:00'

--JOÃO BORGES CLAUDINO JUNIOR
--bate com o saldo do fornecedor na tela de PN

--set @CarCode='F000900'
----set @CarCode='*'
--set @LancamentoIni='2010-01-01 00:00:00'
--set @LancamentoFim='2020-12-31 00:00:00'

--set @VencimentoIni='2010-01-01 00:00:00'
--set @VencimentoFim='2020-12-31 00:00:00'

if @CarCode='*' begin
	set @CarCode=null
end

--select SUM(saldo) from (
select 
	tb.ShortName
	,tb.CardName
	,tb.Lancamento
	,tb.Vencimento
	,tb.Origem
	,tb.OrigemNr
	,tb.Parcela
	,tb.ParcelaTotal
	,tb.Serial
	,tb.LineMemo
	,tb.Debit
	,tb.Credit
	,tb.Saldo
	,tb.DueDate

	,case 
			when Origem='18'  then  OPCH.PeyMethod
			when Origem='204'  then  ODPO.PeyMethod	  
			when Origem='19' then  ORPC.PeyMethod
			--else 'N/A'
	end 'PeyMethodNF' 
 from (
			SELECT 	
				T0.[ShortName],
				--ocrd.CardFName,
				ocrd.CardName,
				T0.[RefDate] as Lancamento, 
				T0.[DueDate] as Vencimento,
				T0.[TransType] as Origem,
				T0.[CreatedBy] as OrigemNr,
				T0.[SourceLine] as Parcela,
				OPCH.Installmnt as ParcelaTotal,
				OPCH.Serial,
				T0.[LineMemo],
				T0.[Debit], T0.[Credit],
				(T0.[Debit] - T0.[Credit])*-1 as Saldo
				,T0.DueDate
			FROM  
				[dbo].[JDT1] T0   LEFT OUTER  JOIN [dbo].[OUSR] T1  ON  T0.[UserSign] = T1.[USERID]    
				LEFT OUTER  JOIN (
						SELECT 
							T0.[TransId] AS 'TransId', T0.[TransRowId] AS 'TransRowId', MAX(T0.[ReconNum]) AS 'MaxReconNum' 
						FROM  
							[dbo].[ITR1] T0  
						GROUP BY 
							T0.[TransId], T0.[TransRowId]
				) T2  ON  T0.[TransId] = T2.[TransId]  AND  T0.[Line_ID] = T2.[TransRowId]   
				inner join ocrd on ocrd.CardCode=T0.[ShortName] and ocrd.CardType='S'
				left join OPCH on opch.docentry=T0.[CreatedBy] and T0.[TransType]='18'
	
	
			WHERE 
				(
				(
					((T0.[DueDate] >= (@dateini) and T0.[DueDate] <=(@datefim))  and @tpData='V')
					and (
						((/*T0.[RefDate] >= (@dateIni) and */T0.[RefDate] <= ((CAST(CAST(GETDATE() AS DATE) AS DATETIME))   )) and @tpData='V' )
					)
				)

				or
				((T0.[RefDate] >= (@dateIni) and T0.[RefDate] <= (@datefim)) and @tpData='LC' )

				)

				AND T0.[ShortName] = ISNULL(@CarCode,T0.[ShortName])

				AND  (T0.[BalDueDeb] <> 0  OR  T0.[BalDueCred] <> 0 OR  T0.[BalFcDeb] <> 0  OR  T0.[BalFcCred] <> 0 ) 
	
	
				--AND  (T0.[RefDate] >= @LancamentoIni  AND  T0.[RefDate] <= @LancamentoFim)
				--and (T0.[DueDate] >=@VencimentoIni and T0.[DueDate] <=@VencimentoFim )	
) as tb	
	left join OPCH on OPCH.DocEntry=OrigemNr and Origem='18'
	left join ODPO on ODPO.DocEntry=OrigemNr and Origem='204'
	left join ORPC on ODPO.DocEntry=OrigemNr and Origem='19'






ORDER BY 
	ShortName,DueDate asc
END









GO


--execute spcJBCContasAPagarPorVencimento '*','2015-01-01','2017-01-01','V'