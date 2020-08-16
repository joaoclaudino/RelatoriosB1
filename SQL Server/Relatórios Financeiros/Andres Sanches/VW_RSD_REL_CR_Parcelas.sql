

/****** Object:  View [dbo].[RSD_REL_CR_Parcelas]    Script Date: 11/14/2012 12:20:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








create VIEW [dbo].[RSD_REL_CR_Parcelas] AS 
Select T2.DocNum,SUM(t2.Parcelas)as 'QtdParcelas', count(T2.DocBase) as 'QtdDocBase' from
		(select TI.DocNum,TI.DocEntry as 'DocBase',
		TI.InvType as 'BaseType',
		COUNT(TI.InvoiceId) as 'Parcelas'
		from RCT2 TI
		Group by TI.DocNum, TI.InvType, TI.DocEntry) T2
	Group by T2.DocNUm








GO


