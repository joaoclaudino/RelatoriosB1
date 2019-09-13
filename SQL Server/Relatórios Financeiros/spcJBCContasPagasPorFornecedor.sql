USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasPagasPorFornecedor]    Script Date: 06/09/2015 09:17:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcJBCContasPagasPorFornecedor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcJBCContasPagasPorFornecedor]
GO

USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasPagasPorFornecedor]    Script Date: 06/09/2015 09:17:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--select  'V' 'Tipo','Dt. Vencimento' 'Desc' union all select  'L','Dt. Liquidação'

CREATE PROC [dbo].[spcJBCContasPagasPorFornecedor] (
	@CarCode nvarchar(15),
	@dataIni date,
	@dataFim date,
	@tpdata  varchar(2)
	--@VencimentoIni datetime2,
	--@VencimentoFim datetime2,
	--@LiquidacaoIni datetime2,
	--@LiquidacaoFim datetime2
	--@serial int
)
with encryption
as
begin

	--JOÃO BORGES CLAUDINO JUNIOR
	
	if @CarCode='*' begin
		set @CarCode=null
	end
	
	--if @serial   = 0  set @serial = null
	
select * from	(
	select 
		CASE  
		  WHEN OVPM.CashSum >0 THEN 'Dinheiro' 
		  when OVPM.TrsfrSum > 0 then 'Transferência Bancária'
		  when OVPM.CheckSum > 0 then 'cheque'
		  when OVPM.BoeSum > 0 then 'Boleto bancário'--inner join OBOE on orct.BoeNum = oboe.BoeNum and oboe.BoeStatus = 'P' and orct.BoeSum > 0
		  ELSE '?1' 
		END as FormaPagamento,
		OVPM.DocEntry as 'CP',
		OVPM.CardCode,
		OVPM.CardName,
		OVPM.TransId,
		OJDT.Memo,
		VPM2.InvType,
		CASE 
			when VPM2.InvType='30' then 'LC'
			when VPM2.InvType='18' then 'NE'
			when VPM2.InvType='19' then 'DE'
			when VPM2.InvType='204' then 'AD'
			else '?2'
		end as 'TPDoc',
		CASE
			when VPM2.InvType='30' then OJDT1.TransId
			when VPM2.InvType='18' then opch.DocEntry
			when VPM2.InvType='19' then ORPC.DocEntry
			when VPM2.InvType='204' then ODPO.DocEntry		
			
			else 0
		end as 'NºDoc'
		, VPM2.InstId as 'Parcela'
		, 
		CASE
			when VPM2.InvType='30' then VPM2.InstId
			when VPM2.InvType='18' then opch.Installmnt
			when VPM2.InvType='19' then ORPC.Installmnt
			else 0
		end as 'ParcelaTotal'
		
		
		, VPM2.SumApplied as 'ValorParcela'
		, CASE
			when VPM2.InvType='30' then OVPM.DocDueDate
			when VPM2.InvType='18' then 
				CASE
					when OVPM.TrsfrSum > 0 then --'Transferência Bancária'
					(select pch6.DueDate from pch6 where pch6.DocEntry = opch.DocEntry and pch6.InstlmntID=VPM2.InstId )
					else
						OVPM.DocDueDate
				end
			when VPM2.InvType='19' then 
				CASE
					when OVPM.TrsfrSum > 0 then --'Transferência Bancária'
						(select RPC6.DueDate from RPC6 where RPC6.DocEntry = ORPC.DocEntry and RPC6.InstlmntID=VPM2.InstId )
					else
						OVPM.DocDueDate
				end		
		end as 'Vencimento',
		CASE
			when OVPM.TrsfrSum > 0 then --'Transferência Bancária'
				OVPM.TrsfrDate
			else
				OVPM.DocDate			
		end as 'Liquidacao'
		--ORPC.DocEntry
		--,VPM2.*
		
		,CASE  
		  WHEN OVPM.CashSum >0 THEN OVPM.CashSum --'Dinheiro' 
		  when OVPM.TrsfrSum > 0 then VPM2.SumApplied --'Transferência Bancária'
		  when OVPM.CheckSum > 0 then OVPM.CheckSum --'cheque'
		  --when OVPM.BoeSum > 0 then --'Boleto bancário'--inner join OBOE on orct.BoeNum = oboe.BoeNum and oboe.BoeStatus = 'P' and orct.BoeSum > 0
		  ELSE 0 
		END as 'ValorPago'
		
		,CASE
			when VPM2.InvType='30' then null
			when VPM2.InvType='18' then opch.Serial
			when VPM2.InvType='19' then ORPC.Serial
			else 0
		end as 'Serial'		
	from 
		OVPM
		inner join OJDT on OJDT.TransId=OVPM.TransId
		inner join VPM2 on VPM2.DocNum=OVPM.DocEntry	
		left join opch on opch.ObjType = VPM2.invType and opch.DocEntry = VPM2.DocEntry	
		left join ORPC on ORPC.ObjType = VPM2.invType and ORPC.DocEntry = VPM2.DocEntry	
		left join OJDT OJDT1 on OJDT1.ObjType = VPM2.InvType and OJDT1.TransId = VPM2.DocEntry
		
		left join ODPO on ODPO.ObjType = VPM2.invType   and ODPO.DocEntry = VPM2.DocEntry	 --ODPO.DocEntry=OrigemNr and Origem='204'
		
	where
		OVPM.Canceled = 'N'	
		--and OVPM.docentry=245
		--and OVPM.docnum=205
		--and OVPM.docnum=3493
		--and OVPM.docnum=3486
) as Tb		
where	
			
	(
	((tb.Vencimento between ISNULL(@dataIni, Vencimento) and ISNULL(@dataFim, Vencimento))  and @tpData='V')

	or
	((tb.liquidacao between ISNULL(@dataIni, liquidacao) and ISNULL(@dataFim 	, liquidacao))and @tpData='L' )

	or
	(ISNULL(@dataIni 	, liquidacao)<>ISNULL(@dataFim , liquidacao) and @tpData<>'L' and @tpData<>'V')--opção invalida não traz nada

	)

	AND
	tb.CardCode=ISNULL(@CarCode,tb.CardCode)
	
	


	--and tb.Vencimento >=@VencimentoIni and tb.Vencimento <=	@VencimentoFim
	--and tb.Liquidacao>=@LiquidacaoIni and tb.Liquidacao<=@LiquidacaoFim 	
	--and isnull(tb.Serial, 0) = ISNULL(@serial, isnull(tb.serial, 0))
--5266 linhas

end






GO


--execute spcJBCContasPagasPorFornecedor '*','2015-01-01','2017-01-01','V'