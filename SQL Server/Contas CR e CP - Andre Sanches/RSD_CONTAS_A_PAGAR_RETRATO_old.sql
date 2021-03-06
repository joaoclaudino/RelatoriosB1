USE [SBO_OPERSAN_PROD]
GO
/****** Object:  StoredProcedure [dbo].[RSD_CONTAS_A_PAGAR_RETRATO]    Script Date: 05/06/2016 10:06:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[RSD_CONTAS_A_PAGAR_RETRATO] (
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
	,Serial
	,BoeStatus
	,RECDATE
	--, SUM(N_Vencido) AS [Receivable not due] 
	--, SUM(Vencido_30) AS [Late payment : 0 to 30 days]
	--, SUM(Vencido_60) AS [Late payment : 31 to 60 days]
	--, SUM(Vencido_90) AS [Late payment : 61 to 90 days]
	--, SUM(Vencido_180) AS [Late payment : 91 to 180 days]
	--, SUM(Vencido_360) AS [Late payment : 181 to 360 days]
	--, SUM(Vencido_361Mais) AS [Late payment : > 361 days]
	--, SUM(Total_AR) AS [Total AR]
	--, T0.CreditLine AS [CFC]
	FROM (
	SELECT BPLName, ShortName, Saldo_Dia AS Total_AR
		, REFDATE
		, DueDate
		, BaseRef
		, case TransType 
			when 13 then 'NF'
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
		,Serial
		,'Em Aberto' as BoeStatus
		,RECDATE
		--, CASE WHEN Base_Dias > 0 THEN Saldo_Dia ELSE 0 END AS N_Vencido
		--, CASE WHEN Base_Dias BETWEEN -30 AND 0 THEN Saldo_Dia ELSE 0 END AS Vencido_30
		--, CASE WHEN Base_Dias BETWEEN -60 AND -31 THEN Saldo_Dia ELSE 0 END AS Vencido_60
		--, CASE WHEN Base_Dias BETWEEN -90 AND -61 THEN Saldo_Dia ELSE 0 END AS Vencido_90
		--, CASE WHEN Base_Dias BETWEEN -180 AND -91 THEN Saldo_Dia ELSE 0 END AS Vencido_180
		--, CASE WHEN Base_Dias BETWEEN -360 AND -181 THEN Saldo_Dia ELSE 0 END AS Vencido_360
		--, CASE WHEN Base_Dias < -361 THEN Saldo_Dia ELSE 0 END AS Vencido_361Mais
		FROM (
			SELECT DATEDIFF(dd,@DataBase,DueDate) AS Base_Dias,BPLName,ShortName, SUM(Saldo_Dia) AS Saldo_Dia, TransId, Line_ID, RefDate, DueDate, BaseRef, TransType, Ref2, SourceID,Serial,RECDATE
				FROM (
					SELECT T0.DueDate, T0.BPLName, T0.ShortName, (T0.Debit-COALESCE(T2.ReconDebit,0))-(T0.Credit-COALESCE(T2.ReconCredit,0)) AS Saldo_Dia, 
						T0.TransId, T0.Line_ID, T0.RefDate, t0.BaseRef, t1.TransType, t0.Ref2, t0.SourceID 
						,CASE t1.TransType 
								when 18 then (select a.Serial from OPCH a where a.TransId = T1.number)
								--when 46 then (select a.Serial from OPCH a where a.DocEntry = (SELECT d.DocEntry FROM VPM2 d  INNER JOIN OVPM f ON d.[DocNum] = f.[DocEntry] WHERE f.TransId = t1.TransId and d.InvType = 18)) 
						 END as Serial
						 , (select top 1 x.ReconDate from OITR x inner join ITR1 c on x.[ReconNum] = c.[ReconNum] and t0.TransId = c.TransId and T0.Line_ID = c.TransRowId) as RECDATE
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
					ON T0.TransId = T2.TransId AND T0.Line_ID = T2.TransRowId left join OINV a on a.docentry = t1.BaseRef --and a.objtype = t1.transtype
				WHERE T0.ShortName IN (SELECT CardCode FROM OCRD WHERE CardType = 'S') AND T1.RefDate <= @DataBase) CR_View 
			WHERE Saldo_Dia <> 0 GROUP BY DueDate,BPLName,ShortName, TransId, Line_ID, RefDate, BaseRef, TransType, Ref2, SourceID,Serial,RECDATE) BaseR6View) R6CreditManagmentView
	INNER JOIN OCRD T0 ON R6CreditManagmentView.ShortName = T0.CardCode
	LEFT JOIN CRD7 T1 ON T0.[CardCode] = T1.[CardCode] AND T1.Address = ''
	--GROUP BY ShortName, T0.CardName, T1.TaxId0, T1.TaxId4, BPLName,T0.CreditLine 
	ORDER BY ShortName
	end