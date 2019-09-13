USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasAReceberPorVencimento]    Script Date: 06/09/2015 09:17:23 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcJBCContasAReceberPorVencimento]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcJBCContasAReceberPorVencimento]
GO

USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCContasAReceberPorVencimento]    Script Date: 06/09/2015 09:17:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[spcJBCContasAReceberPorVencimento] (
	@CardCode varchar(15),
	@dateini date,
	@datefim date,
	@tpData varchar(2)
	,@BankCode	nvarchar(60)
)
with encryption
as 

Begin

--execute spcJBCContasAReceberPorVencimento '*','2010-01-01 00:00:00','2020-01-01 00:00:00','V','*'


--select @refDateIni = convert(date, '2000-01-01')
--      , @refDateFim = convert(date, '2015-01-01')
--      , @DueDateIni = convert(date, '2000-01-02')
--      , @DueDateFim = convert(date, '2015-01-02')
--      , @CardCode = 'C000215'


--select @refDateIni = convert(date, {?RefDateIni})
--        , @refDateFim = convert(date, {?RefDateFim})
--        , @DueDateIni = convert(date, {?DueDateIni})
--        , @DueDateFim = convert(date, {?DueDateFim})
--        , @CardCode = '{?CardCode}'

if rtrim(ltrim(isnull(@CardCode, ''))) in ('', '*', '*Todos')
set @CardCode = null 

Create table #NF_Fiscal( 
     [TransId]      int
	,[Line_ID]		int
	,[Account]      nvarchar(300)
	,[ShortName]    nvarchar(300)
	,[TransType]    nvarchar(400)
	,[CreatedBy]    int
	,[BaseRef]      nvarchar(220)
	,[SourceLine]   smallint
	,[RefDate]      datetime
	,[DueDate]      datetime
	,[BalDueCred]	numeric (16, 9) 
	,[BalDueDeb]	numeric (16, 9) 
	,[BalDueCred_BalDueDeb] numeric (16, 9) 
    ,[Saldo]		numeric (16, 9) 
	,[LineMemo]	    nvarchar(1000)
	,[CardName]	    nvarchar(300)
	,[CardCode]	    nvarchar(300)
	,[Balance]	    numeric (19, 6)
	,[SlpCode]	    int
	,[DebitMAthCredit]numeric (19, 6) 
	,[IsSales]		nvarchar(20)
	,[Currency]		nvarchar(60)
	,[BPLName]	    nvarchar(200)
	)

insert into #NF_Fiscal

SELECT 
	T0.[TransId], 
	T0.[Line_ID], 
	MAX(T0.[Account]) as 'Account' ,
	MAX(T0.[ShortName])  as 'ShortName', 
	MAX(T0.[TransType]) as 'TransType', 
	MAX(T0.[CreatedBy]) as 'CreatedBy',
	MAX(T0.[BaseRef]) as 'BaseRef',
	MAX(T0.[SourceLine]) as 'SourceLine', 
	MAX(T0.[RefDate]) as 'RefDate', 
	MAX(T0.[DueDate]) as 'DueDate', 
	
    MAX(T0.[BalDueCred]) AS'BalDueCred',
    SUM(T1.[ReconSum]) AS 'BalDueDeb',
    MAX(T0.[BalDueCred]) + SUM(T1.[ReconSum]) AS 'BalDueCred - BalDueDeb',
    ( MAX(T0.[BalDueCred]) + SUM(T1.[ReconSum]) ) * (-1) AS 'Saldo',    


	--MAX(T0.[BalDueCred]) + SUM(T1.[ReconSum]), 
	--MAX(T0.[BalFcCred]) + SUM(T1.[ReconSumFC]), 
	--MAX(T0.[BalScCred]) + SUM(T1.[ReconSumSC]), 
	MAX(T0.[LineMemo])as 'LineMemo', 
	MAX(T4.[CardName]) as 'CardName', 
	MAX(T5.[CardCode])as 'CardCode', 

	MAX(T4.[Balance])as 'Balance', 
	MAX(T5.[SlpCode])as 'SlpCode', 

	MAX(T0.[Debit]) + MAX(T0.[Credit]) as 'Debit + Credit', 
	MAX(T5.[IsSales]) as 'IsSales', 
	MAX(T4.[Currency]) as 'Currency', 
	T0.[BPLName] as 'BPLName'
	
FROM  
	[dbo].[JDT1] T0  
	INNER  JOIN [dbo].[ITR1] T1  ON  T1.[TransId] = T0.[TransId]  
		AND  T1.[TransRowId] = T0.[Line_ID]   
	INNER  JOIN [dbo].[OITR] T2  ON  T2.[ReconNum] = T1.[ReconNum]   
	INNER  JOIN [dbo].[OJDT] T3  ON  T3.[TransId] = T0.[TransId]   
	INNER  JOIN [dbo].[OCRD] T4  ON  T4.[CardCode] = T0.[ShortName]    
	LEFT OUTER  JOIN [dbo].[B1_JournalTransSourceView] T5  ON  T5.[ObjType] = T0.[TransType]  
		AND  T5.[DocEntry] = T0.[CreatedBy]  
		AND  (T5.[TransType] <> 'I'  OR  (T5.[TransType] = 'I'  
		AND  T5.[InstlmntID] = T0.[SourceLine] ))  
WHERE 
	(
		((T0.[RefDate] <= (@DateFim)  AND  T0.[RefDate] >= (@DateIni)  AND  T0.[RefDate] <= (@DateFim)  
		AND  T2.[ReconDate] > (@DateFim)  )  and @tpData='LC')

		or (
				((T0.[DueDate] >= (@DateIni)  AND  T0.[DueDate] <= (@DateFim)  )  and @tpData='V' )
				and
				(
					((T0.[RefDate] <= (SELECT CAST(CAST(GETDATE() AS DATE) AS DATETIME))  /*AND  T0.[RefDate] >= (@DateIni) */ AND  T0.[RefDate] <= (SELECT CAST(CAST(GETDATE() AS DATE) AS DATETIME))  
					AND  T2.[ReconDate] > (SELECT CAST(CAST(GETDATE() AS DATE) AS DATETIME))  )  and @tpData='V')--JBC
				)
			)
	)
	
	AND  T4.[CardType] = ('C')  AND  T4.[Balance] <> (0)  
	
	

	AND  T1.[IsCredit] = ('C')   

	AND  ((T4.[CardCode] = (@CardCode)  ) OR (ISNULL(@CardCode,'0')='0')  ) 
	



GROUP BY 
	T0.[TransId], T0.[Line_ID], T0.[BPLName] 
HAVING 
	MAX(T0.[BalFcCred]) <>- SUM(T1.[ReconSumFC])  OR  MAX(T0.[BalDueCred]) <>- SUM(T1.[ReconSum])   
UNION ALL 
SELECT 
	T0.[TransId], 
	T0.[Line_ID], 
	MAX(T0.[Account]), 
	MAX(T0.[ShortName]), 
	MAX(T0.[TransType]), 
	MAX(T0.[CreatedBy]), 
	MAX(T0.[BaseRef]), 
	MAX(T0.[SourceLine]), 
	MAX(T0.[RefDate]), 
	MAX(T0.[DueDate]), 
	
    MAX(T0.[BalDueCred]) AS'BalDueCred',
    SUM(T1.[ReconSum]) AS 'BalDueDeb',
    MAX(T0.[BalDueCred]) + SUM(T1.[ReconSum]) AS 'BalDueCred - BalDueDeb',
    ( MAX(T0.[BalDueCred]) + SUM(T1.[ReconSum]) ) * (-1) AS 'Saldo',
    	
	--- MAX(T0.[BalDueDeb]) - SUM(T1.[ReconSum]),  
	--- MAX(T0.[BalFcDeb]) - SUM(T1.[ReconSumFC]),  
	--- MAX(T0.[BalScDeb]) - SUM(T1.[ReconSumSC]), 
	MAX(T0.[LineMemo]), 
	MAX(T4.[CardName]), 
	MAX(T5.[CardCode]), 

	MAX(T4.[Balance]), 
	MAX(T5.[SlpCode]), 
	MAX(T0.[Debit]) + MAX(T0.[Credit]), 
	MAX(T5.[IsSales]), 
	MAX(T4.[Currency]), 
	T0.[BPLName] 
FROM  
	[dbo].[JDT1] T0  
	INNER  JOIN [dbo].[ITR1] T1  ON  T1.[TransId] = T0.[TransId]  AND  T1.[TransRowId] = T0.[Line_ID]   
	INNER  JOIN [dbo].[OITR] T2  ON  T2.[ReconNum] = T1.[ReconNum]   
	INNER  JOIN [dbo].[OJDT] T3  ON  T3.[TransId] = T0.[TransId]   
	INNER  JOIN [dbo].[OCRD] T4  ON  T4.[CardCode] = T0.[ShortName]    
	LEFT OUTER  JOIN [dbo].[B1_JournalTransSourceView] T5  ON  T5.[ObjType] = T0.[TransType]  
		AND  T5.[DocEntry] = T0.[CreatedBy]  
		AND  (T5.[TransType] <> 'I'  OR  (T5.[TransType] = 'I'  AND  T5.[InstlmntID] = T0.[SourceLine] ))  
WHERE 
	(
		((T0.[RefDate] <= (@DateFim)  AND  T0.[RefDate] >= (@DateIni)  AND  T0.[RefDate] <= (@DateFim)  
		AND  T2.[ReconDate] > (@DateFim)  ) and @tpData='LC' )

		or (
			((T0.[DueDate] >= (@DateIni)  AND  T0.[DueDate] <= (@DateFim)  ) and @tpData='V') 
			and
			(
				((T0.[RefDate] <= (CAST(CAST(GETDATE() AS DATE) AS DATETIME))  /*AND  T0.[RefDate] >= (@DateIni)*/  AND  T0.[RefDate] <= (CAST(CAST(GETDATE() AS DATE) AS DATETIME))  
				AND  T2.[ReconDate] > (CAST(CAST(GETDATE() AS DATE) AS DATETIME))  ) and @tpData='V' )
			)
		)
	)

	AND  T4.[CardType] = ('C')  AND  T4.[Balance] <> (0)  
	AND  ( (T4.[CardCode] = (@CardCode)  ) OR (ISNULL(@CardCode,'0')='0') )
	AND  T1.[IsCredit] = ('D')   
GROUP BY
	T0.[TransId], T0.[Line_ID], T0.[BPLName] 
HAVING 
	MAX(T0.[BalFcDeb]) <>- SUM(T1.[ReconSumFC])  OR  MAX(T0.[BalDueDeb]) <>- SUM(T1.[ReconSum])   
UNION ALL 
SELECT --1 as Query
	T0.[TransId], 
	T0.[Line_ID], 
	MAX(T0.[Account]), 
	MAX(T0.[ShortName]), 
	MAX(T0.[TransType]), 
	MAX(T0.[CreatedBy]), 
	MAX(T0.[BaseRef]), 
	MAX(T0.[SourceLine]), 
	MAX(T0.[RefDate]), 
	MAX(T0.[DueDate]), 
	
    MAX(t0.balduecred) as 'BalDueCred',
    MAX(t0.BalDueDeb)  as 'BalDueDeb',
    MAX(T0.[BalDueCred]) - MAX(T0.[BalDueDeb]) as 'BalDueCred - BalDueDeb',
   ( MAX(T0.[BalDueCred]) - MAX(T0.[BalDueDeb]) ) * -1 as 'Saldo'	,
	
	--MAX(T0.[BalDueCred]) - MAX(T0.[BalDueDeb]), 
	--MAX(T0.[BalFcCred]) - MAX(T0.[BalFcDeb]), 
	--MAX(T0.[BalScCred]) - MAX(T0.[BalScDeb]), 
	
	MAX(T0.[LineMemo]), 
	MAX(T2.[CardName]), 
	MAX(T2.[CardCode]), 
	MAX(T2.[Balance]), 
	MAX(T3.[SlpCode]), 
	MAX(T0.[Debit]) + MAX(T0.[Credit]), 
	MAX(T3.[IsSales]), 
	MAX(T2.[Currency]), 
	T0.[BPLName] 
FROM  
	[dbo].[JDT1] T0  
	INNER  JOIN [dbo].[OJDT] T1  ON  T1.[TransId] = T0.[TransId]   
	INNER  JOIN [dbo].[OCRD] T2  ON  T2.[CardCode] = T0.[ShortName]    
	LEFT OUTER  JOIN [dbo].[B1_JournalTransSourceView] T3  ON  T3.[ObjType] = T0.[TransType]  
		AND  T3.[DocEntry] = T0.[CreatedBy]  AND  (T3.[TransType] <> 'I'  
		OR  (T3.[TransType] = 'I'  AND  T3.[InstlmntID] = T0.[SourceLine] ))  
WHERE
	( 
		((T0.[RefDate] <= (@DateFim)  AND  T0.[RefDate] >= (@DateIni)  AND  T0.[RefDate] <= (@DateFim)  

		AND   
			NOT EXISTS (
				SELECT U0.[TransId], U0.[TransRowId] 
				FROM  [dbo].[ITR1] U0  
					INNER  JOIN [dbo].[OITR] U1  ON  U1.[ReconNum] = U0.[ReconNum]   
				WHERE 
					T0.[TransId] = U0.[TransId]  AND  T0.[Line_ID] = U0.[TransRowId]  AND  U1.[ReconDate] > (@DateFim)   
				GROUP BY 
					U0.[TransId], U0.[TransRowId])

		) and @tpData='LC')


		or 
			(
				(T0.[DueDate] >= (@DateIni)  AND  T0.[DueDate] <= (@DateFim)  and @tpData='V' 	)
				and
				(
					((T0.[RefDate] <= (CAST(CAST(GETDATE() AS DATE) AS DATETIME))  /*AND  T0.[RefDate] >= (@DateIni)*/  AND  T0.[RefDate] <= (CAST(CAST(GETDATE() AS DATE) AS DATETIME))  

					AND   
						NOT EXISTS (
							SELECT U0.[TransId], U0.[TransRowId] 
							FROM  [dbo].[ITR1] U0  
								INNER  JOIN [dbo].[OITR] U1  ON  U1.[ReconNum] = U0.[ReconNum]   
							WHERE 
								T0.[TransId] = U0.[TransId]  AND  T0.[Line_ID] = U0.[TransRowId]  AND  U1.[ReconDate] > (CAST(CAST(GETDATE() AS DATE) AS DATETIME))   
							GROUP BY 
								U0.[TransId], U0.[TransRowId])

					) and @tpData='V')
				)
			)


			--CAST(CAST(GETDATE() AS DATE) AS DATETIME)
	)
	AND  T2.[CardType] = ('C')  AND  T2.[Balance] <> (0)  
	AND  ((T2.[CardCode] = (@CardCode)  ) OR (ISNULL(@CardCode,'0')='0'))
	AND  (T0.[BalDueCred] <> T0.[BalDueDeb]  
	OR  T0.[BalFcCred] <> T0.[BalFcDeb] ) 
GROUP BY 
	T0.[TransId], T0.[Line_ID], T0.[BPLName]
	
end 

--select distinct TransType from #NF_Fiscal
--203 ODPI
--182 OBOE
--13  OINV
--24  ORCT
--14  IRIN
--30  OJDT
select 
	TransId     
	,Line_ID     
	,Account                                                                                                                                                                                                                                                          
	,ShortName                                                                                                                                                                                                                                                        
	,TransType                                                                                                                                                                                                                                                        
	,CreatedBy   
	,BaseRef                                                                                                                                                                                                                      
	,SourceLine 
	,RefDate                 
	,DueDate                 
	,BalDueCred                              
	,BalDueDeb                               
	,BalDueCred_BalDueDeb                    
	,Saldo                                   
	,LineMemo                                                                                                                                                                                                                                                         
	,CardName                                                                                                                                                                                                                                                         
	,CardCode                                                                                                                                                                                                                                                         
	,Balance                                 
	,SlpCode     
	,DebitMAthCredit                         
	,IsSales              
	,Currency                                                     
	,BPLName                                                                                                                                                                                                  
	,Serial      

	,case when FormaPagamento='' then PeyMethodNF else FormaPagamento end 'FormaPagamento'
	,PeyMethodNF   		

	,case 
		when coalesce(ODSC.BankName,'')<>'' then ODSC.BankCode --ODSC.BankName
		else case  when TransType='24' and  FormaPagamento='Boleto'  then TB.BankCode else (select top 1 BnkDflt  from OPYM where PayMethCod=PeyMethodNF )  end 
		
	end	'BancoNF'


	--select * from OPYM
	,Installmnt	
	,OrctComments
	--,ODSC.BankName
	,case 
		when coalesce(ODSC.BankCode,'')<>'' then cast(ODSC.BankCode AS nvarchar(30))
		--ODSC.BankCode
		else case  when TransType='24' and  FormaPagamento='Boleto'  then TB.BankCode else (select top 1 BnkDflt  from OPYM where PayMethCod=PeyMethodNF )  end 
		
	end	'BankName'
	,DocEntryNFS
	--,TB.bank
	--,CntrlBnkNF
from (
	 select 
		#NF_Fiscal.[TransId]
		,#NF_Fiscal.[Line_ID]
		,#NF_Fiscal.[Account]
		,#NF_Fiscal.[ShortName]
		,#NF_Fiscal.[TransType]
		,#NF_Fiscal.[CreatedBy]
		,#NF_Fiscal.[BaseRef]
		, case when #NF_Fiscal.[SourceLine]<0 then 0 else #NF_Fiscal.[SourceLine] end SourceLine
		,#NF_Fiscal.[RefDate]
		,#NF_Fiscal.[DueDate]
		,#NF_Fiscal.[BalDueCred]
		,#NF_Fiscal.[BalDueDeb]
		,#NF_Fiscal.[BalDueCred_BalDueDeb]
		,#NF_Fiscal.[Saldo]
		,#NF_Fiscal.[LineMemo]
		,#NF_Fiscal.[CardName]
		,#NF_Fiscal.[CardCode]
		,#NF_Fiscal.[Balance]
		,#NF_Fiscal.[SlpCode]
		,#NF_Fiscal.[DebitMAthCredit]
		,#NF_Fiscal.[IsSales]
		,#NF_Fiscal.[Currency]
		,#NF_Fiscal.[BPLName]
	
		,case when #NF_Fiscal.TransType = '13'  then  OINV.Serial
			  when #NF_Fiscal.TransType = '30'  then  OJDT.Serial
			  when #NF_Fiscal.TransType = '14'  then  ORIN.Serial
			  --when #NF_Fiscal.TransType = '24'  then  ORCT.Serial
			  when #NF_Fiscal.TransType = '203' then  ODPI.Serial
			  when #NF_Fiscal.TransType = '24'  then  (select top 1 serial from OINV where OINV.docentry in (select top 1 RCT2.baseAbs  from RCT2 where RCT2.invtype='13' and RCT2.DocNum=#NF_Fiscal.[BaseRef]))

			  --select top RCT2.baseAbs  from RCT2 where RCT2.invtype='13' and RCT2.DocNum=#NF_Fiscal.[BaseRef]
			  --else 321
			  --else 'N/A'
		end 'Serial' 
		, case when #NF_Fiscal.TransType = '24'  then  
				case 
					when orct.CashSum   > 0 then 'dinheiro'
					when orct.BoeSum    > 0 then 'Boleto'
					when orct.CheckSum  > 0 then 'Cheque'
					when orct.CreditSum > 0 then 'Cartão de Crédito'
					when orct.TrsfrSum  > 0 then 'Tranferência Bancária'
					else ''
				end
			else ''
		end 'FormaPagamento'
	
		,case 
			  when #NF_Fiscal.TransType = '13'  then  OINV.PeyMethod
			  when #NF_Fiscal.TransType = '14'  then  ORIN.PeyMethod	  
			  when #NF_Fiscal.TransType = '203' then  ODPI.PeyMethod
			  else ''
		end 'PeyMethodNF' 
		--OINV.Installmnt 
		,case 
			  when #NF_Fiscal.TransType = '13'  then  OINV.Installmnt
			  when #NF_Fiscal.TransType = '14'  then  ORIN.Installmnt
			  when #NF_Fiscal.TransType = '203' then  ODPI.Installmnt
			  else null
		end 'Installmnt '
		--,(
		--	case when #NF_Fiscal.TransType = '24'  then  
		--		case 
		--			when orct.BoeSum    > 0 then orct.Comments
		--			else ''
		--		end
		--	end
		--) 
		,orct.Comments 'OrctComments'
		,ODSC.BankName
		,ODSC.BankCode
		,case
			when #NF_Fiscal.TransType = '24'  then  (select top 1 RCT2.baseAbs  from RCT2 where RCT2.invtype='13' and RCT2.DocNum=#NF_Fiscal.[BaseRef])
			else 0
		end 'DocEntryNFS'
	  from 
		#NF_Fiscal
		left join OINV on OINV.DocEntry = #NF_Fiscal.BaseRef and #NF_Fiscal.TransType='13'  
		left join OJDT on OJDT.TransId  = #NF_Fiscal.BaseRef and #NF_Fiscal.TransType='30'  
		left join ORIN on ORIN.Docentry = #NF_Fiscal.BaseRef and #NF_Fiscal.TransType='14' 	 
		
		left join ORCT on ORCT.DocEntry = #NF_Fiscal.BaseRef and #NF_Fiscal.TransType='24' 
		left join OBOE on OBOE.boenum =ORCT.boenum 
		left join ODSC on ODSC.BankCode=OBOE.BPBankCod 

		left join ODPI on ODPI.DocEntry = #NF_Fiscal.BaseRef and #NF_Fiscal.TransType='203'		

		--select 
		--	ORCT.boenum
		--	,OBOE.BPBankCod 
		--	,ODSC.BankName
		--from 
		--	ORCT 
		--	inner join OBOE on OBOE.boenum =ORCT.boenum 
		--	inner join ODSC on ODSC.BankCode=OBOE.BPBankCod 
		--select BankCode,BankName from ODSC
) TB	
	left join ODSC on ODSC.BankCode=(select top 1 BnkDflt  from OPYM where PayMethCod=PeyMethodNF ) 
	where (@BankCode=(select top 1 BnkDflt  from OPYM where PayMethCod=PeyMethodNF )) or isnull(@BankCode, '*')='*'
order by 1	  
	--and TransId=13227
	--where (ISNULL(@CardCode,'0')='0'))
	--(select top 1 BnkDflt  from OPYM where PayMethCod=PeyMethodNF )

	--select * from ODPI

drop table #NF_Fiscal




GO


--execute spcJBCContasAReceberPorVencimento '*','2015-01-01','2017-01-01','V','*'