USE [SBO_OPERSAN_PROD]
GO
/****** Object:  StoredProcedure [dbo].[RSD_CONTAS_A_RECEBER_RETRATO]    Script Date: 05/06/2016 10:06:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[RSD_CONTAS_A_RECEBER_RETRATO] (
  @DataBase DATETIME
)
as
BEGIN

SELECT BPLName AS [Branch],ShortName AS [Code], T0.CardName AS [Customer name],
T1.TaxId0 AS 'CNPJ',
T1.TaxId4 AS 'CPF'
	--,N_Vencido
	,Total_AR
	, REFDATE as Emissao
	, duedate as Vencimento
	, BaseRef as doc_origem
	,Tipo_lancamento
	,TransId
	,Ref2
	,case BoeStatus
		when 'G' then 'Gerado'
		when 'P' then 'Pendente'
		when 'C' then 'Calcelado'
		when 'F' then 'Fechado'
		else BoeStatus
	end as Status,
	U_pdd
	,U_juros
	,U_UltimaData
	,U_NovaDataPgto
	,U_Observacao_1
	,BaseAmnt
	FROM (
	SELECT BPLName, ShortName, Saldo_Dia AS Total_AR
		, REFDATE
		, DueDate
		, BaseRef
		, case TransType 
			when 13 then 'NS'
			when 14 then 'DS'
			when 18 then 'NE'
			when 182 then 'BT'
			when 19 then 'DE'
			when -2 then 'SI'
			when 20 then 'RM'
			when 203 then 'AT'
			when 204 then 'AT'
			when 21 then 'DM'
			when 24 then 'CR'
			when 25 then 'DP'
			when -3 then 'FC'
			when 30 then 'LC'
			when 321 then 'RI'
			when 46 then 'CP'
			when 59 then 'EM'
		End as Tipo_lancamento
		, TransId
		
		,case 
			when ref2 <> '' then ref2 
			when ref2 = '' then (
					select c.NumAtCard 
					from ORCT a inner join RCT2 b on a.docentry = b.docnum inner join OINV c on b.docentry = c.DocEntry
					where SourceID = a.DocEntry)end as ref2
					
		,case 
			when ref2 <> '' then 'Em Aberto' 
			when ref2 = '' then (
					select a.BoeStatus
					from ORCT a
					where SourceID = a.DocEntry)end as BoeStatus
		,U_pdd
		,U_juros
		,U_UltimaData
		,U_NovaDataPgto
		,U_Observacao_1
		,BaseAmnt
		FROM (
			SELECT DATEDIFF(dd,@DataBase,DueDate) AS Base_Dias,BPLName,ShortName, SUM(Saldo_Dia) AS Saldo_Dia, TransId, Line_ID, RefDate, DueDate, BaseRef, TransType, Ref2, SourceID, U_pdd,U_juros,U_UltimaData, U_NovaDataPgto,U_Observacao_1,BaseAmnt
				FROM (
					SELECT T0.DueDate, T0.BPLName, T0.ShortName, (T0.Debit-COALESCE(T2.ReconDebit,0))-(T0.Credit-COALESCE(T2.ReconCredit,0)) AS Saldo_Dia, 
						T0.TransId, T0.Line_ID, T0.RefDate, t0.BaseRef, t1.TransType, t0.Ref2, t0.SourceID, a.U_pdd, CAST(a.U_Observacao_1 as Varchar(8000))as U_Observacao_1, a.U_UltimaData, a.U_NovaDataPgto, a.U_juros, a.BaseAmnt 
						FROM 
							JDT1 T0 INNER JOIN 
							OJDT T1 ON T0.TransId = T1.TransId LEFT JOIN (
								SELECT X1.TransId, X1.TransRowId, 
									CASE WHEN MIN(X1.IsCredit) = 'D' THEN SUM(X1.ReconSum) ELSE 0 END AS ReconDebit, 
									CASE WHEN MIN(X1.IsCredit) = 'C' THEN SUM(X1.ReconSum) ELSE 0 END AS ReconCredit 
								FROM 
									OITR X0 INNER JOIN 
									ITR1 X1 ON X0.ReconNum = X1.ReconNum WHERE X0.Canceled = 'N' AND X0.CancelAbs = 0 AND X0.ReconDate <= @DataBase
						GROUP BY X1.TransId, X1.TransRowId) T2
					ON T0.TransId = T2.TransId AND T0.Line_ID = T2.TransRowId left join OINV a on a.DocEntry = t1.BaseRef
				WHERE T0.ShortName IN (SELECT CardCode FROM OCRD WHERE CardType = 'C') AND T1.RefDate <= @DataBase) CR_View 
			WHERE Saldo_Dia <> 0 GROUP BY DueDate,BPLName,ShortName, TransId, Line_ID, RefDate, BaseRef, TransType, Ref2, SourceID,U_pdd,U_juros,U_UltimaData, U_NovaDataPgto,CAST(U_Observacao_1 as Varchar(8000)), BaseAmnt) BaseR6View) R6CreditManagmentView
	INNER JOIN OCRD T0 ON R6CreditManagmentView.ShortName = T0.CardCode
	LEFT JOIN CRD7 T1 ON T0.[CardCode] = T1.[CardCode] AND T1.Address = ''
	ORDER BY ShortName
	END