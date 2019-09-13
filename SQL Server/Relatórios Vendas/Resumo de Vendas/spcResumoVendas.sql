use SDO_DESENV
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcResumoVendas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcResumoVendas]
GO

CREATE procedure [dbo].[spcResumoVendas]
	@CardCode nvarchar(30),
	@DataInicio DateTime,
	@DataFim DateTime
WITH ENCRYPTION  
as

select 
	OINV.ObjType,
	OINV.CardCode,
	OINV.CardName,
	OINV.DocDate,
	OINV.DocDueDate 'VENCIMENTO',
	--DATEPART(DAY,OINV.DocDate) 'DIA',
	DATEPART(MONTH,OINV.DocDate) 'MES',
	DATEPART(YEAR,OINV.DocDate) 'ANO',	
	OINV.DocEntry,
	OINV.Serial,
	OINV.Installmnt 'PRESTACOES',
	INV1.ItemCode,
	INV1.Dscription,
	INV1.Quantity,
	INV1.Price,
	(INV1.Quantity *  INV1.Price) 'TOTAL'
	--,*
from 
	OINV 
	inner join INV1 INV1 on INV1.DocEntry=OINV.DocEntry
where 
	CANCELED='N'
	and (@CardCode='*'  or OINV.CardCode=@CardCode )
	and OINV.DocDate between @DataInicio  and @DataFim 
	--and OINV.DocEntry=2337
union all
select 
	ORIN.ObjType,
	ORIN.CardCode,
	ORIN.CardName,
	ORIN.DocDate,
	ORIN.DocDueDate 'VENCIMENTO',
	--DATEPART(DAY,OINV.DocDate) 'DIA',
	DATEPART(MONTH,ORIN.DocDate) 'MES',
	DATEPART(YEAR,ORIN.DocDate) 'ANO',	
	ORIN.DocEntry,
	ORIN.Serial,
	ORIN.Installmnt,
	RIN1.ItemCode,
	RIN1.Dscription,
	RIN1.Quantity *-1,
	RIN1.Price,
	((RIN1.Quantity *  RIN1.Price) *-1)  'TOTAL'
	--,*
from 
	ORIN
	inner join RIN1 RIN1 on RIN1.DocEntry=ORIN.DocEntry
where 
	CANCELED='N'
	and (@CardCode='*'  or ORIN.CardCode=@CardCode )
	and rin1.BaseEntry in (
		select 
			OINV .DocEntry
		from
			OINV 
			inner join INV1 INV1 on INV1.DocEntry=OINV.DocEntry
		where 
			CANCELED='N'
			and (@CardCode='*'  or OINV.CardCode=@CardCode )
			and OINV.DocDate between @DataInicio  and @DataFim 	
	)
	--and ORIN.DocDate between @DataInicio  and @DataFim 	
order by
	OINV.CardCode,
	OINV.DocDate
go

--execute spcResumoVendas '*','2000-01-01 00:00:00','2020-01-01 00:00:00'
--C000030
--select * from INV1


--select * from inv6