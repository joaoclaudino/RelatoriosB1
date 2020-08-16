
/****** Object:  View [dbo].[CPPagos_DevolucoesClientes]    Script Date: 11/14/2012 12:18:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[CPPagos_DevolucoesClientes]
AS
SELECT     T1.CardCode AS Codigo_PN, T1.CardName AS Razao_Social, T7.TaxId0 AS CNPJ, CAST(T3.Serial AS Varchar) AS Num_Docto, CAST(T2.InstId AS Varchar) AS Prest, 
                      T3.Installmnt AS Parcelas, T2.DocEntry AS Docto_Origem, 'NF ' AS Tipo_Docto, ISNULL(T3.DocDate, TJ2.DueDate) AS [Emissao NF], TJ2.DueDate AS Vencimento, 
                      TJ2.Debit - TJ2.Credit AS Valor_Original, T0.DocTotal AS Valor_Pago, 
                      CASE WHEN CheckSum > 0 THEN T0.TaxDate WHEN TrsfrSum > 0 THEN T0.TaxDate WHEN T0.BoeAbs IS NOT NULL THEN T6.TaxDate END AS Data_Pagamento, 
                      CAST(CAST(ISNULL(T6.PostDate, T0.DocDueDate) - TJ2.DueDate AS Decimal(6, 0)) AS Varchar) AS Dias_Atraso, T0.DocNum AS Docto_Baixa, ISNULL(T4.BoeNum, 
                      T2.DocNum) AS Num_Boleto, CASE WHEN T0.BoeAbs IS NOT NULL 
                      THEN 'Boleto' ELSE CASE WHEN [CheckSum] > 0 THEN 'Cheque' WHEN [TrsfrSum] > 0 THEN 'Transferencia' WHEN [CashSum] > 0 THEN 'Dinheiro' ELSE 'Cartao Credito'
                       END END AS Forma_Pagto,
                       T0.BPLId, T0.BPLName
FROM         dbo.OVPM AS T0 INNER JOIN
                      dbo.OCRD AS T1 ON T0.CardCode = T1.CardCode INNER JOIN
                      dbo.VPM2 AS T2 ON T2.DocNum = T0.DocNum LEFT OUTER JOIN
                      dbo.ORIN AS T3 ON T3.DocEntry = T2.DocEntry LEFT OUTER JOIN
                      dbo.OBOE AS T4 ON T4.BoeKey = T0.BoeAbs LEFT OUTER JOIN
                      dbo.BOT1 AS T5 ON T5.BOENumber = T4.BoeNum LEFT OUTER JOIN
                      dbo.OBOT AS T6 ON T6.AbsEntry = T5.AbsEntry INNER JOIN
                      dbo.OJDT AS TJ1 ON TJ1.BaseRef = T3.DocEntry AND TJ1.TransType = '14' INNER JOIN
                      dbo.JDT1 AS TJ2 ON TJ2.TransId = TJ1.TransId AND TJ2.ShortName = T1.CardCode AND TJ2.Ref3Line = T2.InstId AND TJ2.TransType = '14' INNER JOIN
                      dbo.CRD7 AS T7 ON T7.CardCode = T1.CardCode AND T7.Address = ''
WHERE     (T0.Canceled = 'N') AND (T4.BoeStatus = 'P') AND (CASE WHEN T5.BoeType IS NOT NULL THEN T5.BoeType ELSE 'O' END = 'O') AND 
                      (CASE WHEN T6.StatusTO IS NOT NULL THEN T6.StatusTO ELSE 'P' END = 'P') AND (T3.CardCode <> 'C99999') AND (T0.BoeAbs IS NULL) OR
                      (T0.Canceled = 'N') AND (CASE WHEN T5.BoeType IS NOT NULL THEN T5.BoeType ELSE 'O' END = 'O') AND (CASE WHEN T6.StatusTO IS NOT NULL 
                      THEN T6.StatusTO ELSE 'P' END = 'P') AND (T3.CardCode <> 'C99999') AND (T0.BoeAbs IS NULL) AND (T0.BoeAbs IS NULL)



GO


