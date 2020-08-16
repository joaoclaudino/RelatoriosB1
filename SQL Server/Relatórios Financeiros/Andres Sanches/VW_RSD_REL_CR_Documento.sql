
/****** Object:  View [dbo].[RSD_REL_CR_Documento]    Script Date: 11/14/2012 12:19:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO










create VIEW [dbo].[RSD_REL_CR_Documento] AS 
Select Distinct T2.DocNum,--T2.Invtype,T2.Docentry,
Case T3.QtdDocBase when '1' then T2.DocEntry Else T2.DocNum end as 'DocBase',
Case T3.QtdDocBase when '1' then T2.InvType Else '24' end as 'DocType',
Case T3.QtdParcelas when '1' then T2.InstId Else '0' end as 'Parcela'

From RCT2 T2
INNER JOIN
	RSD_REL_CR_Parcelas T3 on T3.DocNum=T2.DocNum










GO


