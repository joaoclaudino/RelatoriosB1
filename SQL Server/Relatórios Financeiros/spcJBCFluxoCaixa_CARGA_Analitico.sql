USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCFluxoCaixa_CARGA_Analitico]    Script Date: 06/09/2015 09:18:03 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcJBCFluxoCaixa_CARGA_Analitico]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcJBCFluxoCaixa_CARGA_Analitico]
GO

USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCFluxoCaixa_CARGA_Analitico]    Script Date: 06/09/2015 09:18:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- 
CREATE proc [dbo].[spcJBCFluxoCaixa_CARGA_Analitico]
  @dt smalldatetime 
, @caixa char(1)
, @atrasos char(1)
with encryption
as 

  declare @vGroupNum      int
  declare @vDocNum        int
  declare @vCardCode      varchar(30)
  declare @vCardName      varchar(200)
  declare @vShipDate      smalldatetime
  declare @vLineTotal     money
  declare @vTipo          varchar(3)
  declare @saldo_inicial  decimal(19, 2)
  declare @vdt_vencimento smalldatetime
  declare @vvalor money
  declare @vlinha int

  create table #lancamentos (
    tipo char(4) null
  , DocNum int null
  , CardCode varchar(30) null
  , CardName varchar(200) null
  , dt_vencimento smalldatetime null
  , valor decimal(19, 2) null
  , saldo decimal(19, 2) null
  )

  declare cp1 cursor local fast_forward read_only for
    select 'PV' as tipo
         , ordr.docnum
         , ordr.cardcode
         , ordr.cardname
         , ordr.groupnum as forma
         , rdr1.ShipDate as data_base
         , SUM(rdr1.linetotal) as valor
      from RDR1
     inner join ORDR
        on ORDR.DocEntry = rdr1.DocEntry 
     where rdr1.InvntSttus = 'O'
       and ordr.DocStatus = 'O'
     group by ordr.docnum, ordr.cardcode, ordr.cardname, ordr.groupnum, rdr1.ShipDate 
     union all
    select 'PC' as tipo
         , opor.docnum
         , opor.cardcode
         , opor.cardname
         , oPOR.groupnum as forma
         , POR1.ShipDate as data_base
         , SUM(POR1.linetotal) as valor
      from POR1
     inner join OPOR 
        on oPOR.DocEntry = POR1.DocEntry 
     where POR1.InvntSttus = 'O'
       and oPOR.DocStatus = 'O'   
     group by opor.docnum, opor.cardcode, opor.cardname, oPOR.groupnum, POR1.ShipDate 
    order by 1, 3, 2
  open cp1

  while 1 = 1
  begin
    fetch next from cp1 into @vTipo, @vDocNum, @vCardCode, @vCardName, @vGroupNum, @vShipDate, @vLineTotal
    if @@FETCH_STATUS <> 0 break
    
    insert into #lancamentos (tipo, docnum, cardcode, cardname, dt_vencimento, valor)
      SELECT @vTipo, @vDocNum, @vCardCode, @vCardName
           , DATEADD(day, InstDays, @vShipDate)
           , case when @vTipo = 'PC' then ( ( @vLineTotal * InstPrcnt ) / 100 ) * -1 else (@vLineTotal * InstPrcnt) / 100 end
        from CTG1
       where CTGCode = @vGroupNum 
       
    if @@ROWCOUNT = 0
      insert into #lancamentos (tipo, docnum, cardcode, cardname, dt_vencimento, valor)
        select @vTipo, @vDocNum, @vCardCode, @vCardName, @vShipDate, case @vtipo when 'PC' then @vLineTotal * -1 else @vLineTotal end
    
  end
  close cp1
  deallocate cp1


CREATE TABLE #ContasAPagarPorVencimento (		
	ShortName nvarchar(30)
	, CardName nvarchar(200)
	, Lancamento datetime
	, Vencimento datetime
	, Origem nvarchar(40)
	, OrigemNr integer
	, Parcela smallint
	, ParcelaTotal smallint
	, Serial int
	, LineMemo nvarchar(100)
	, Debit decimal(19, 9)
	, Credit decimal(19, 9)
	, Saldo decimal(19, 9)
	, DueDate datetime
	, PeyMethodNF nvarchar(40)
)
-- execute spcJBCContasAPagarPorVencimento '*','01-01-2000 00:00:00','01-01-2050 00:00:00','V'

insert into #ContasAPagarPorVencimento
execute spcJBCContasAPagarPorVencimento 
   '*'
  ,'1900-11-16'
  ,@dt 
  ,'V'
  
CREATE TABLE #ContasAReceberPorVencimento (
	TransId int, 
	Line_ID int, 
	Account nvarchar(30),
	ShortName  nvarchar(30),
	TransType nvarchar(40),
	CreatedBy int,
	BaseRef nvarchar(22),
	SourceLine smallint,
	RefDate datetime,
	DueDate datetime,
	BalDueCred decimal(19, 9),
	BalDueDeb decimal(19, 9),
	BalDueCredBalDueDeb decimal(19, 9),
	Saldo decimal(19, 9),
	LineMemo nvarchar(100),
	CardName nvarchar(200),
	CardCode nvarchar(30),
	Balance  decimal(19, 9),
	SlpCode int,
	DebitCredit  decimal(19, 9),
	IsSales nvarchar(2),
	Currency nvarchar(6),
	BPLName nvarchar(200),
	Serial  int,
	FormaPagamento nvarchar(100),
	PeyMethodNF    nvarchar(100),
	BancoNF        nvarchar(100),
	Installmnt	   nvarchar(200),
	OrctComments   nvarchar(500),
	BankName	   nvarchar(100),
	Nf int
)
-- execute [spcJBCContasAReceberPorVencimento] '*','01-01-2000 00:00:00','01-01-2050 00:00:00','V','*'

insert  into #ContasAReceberPorVencimento
EXECUTE [spcJBCContasAReceberPorVencimento] 
   '*'
  ,'1900-11-20'
  --,'2050-11-20'
  --,'1900-11-16'
  ,@dt
  ,'LC'
  ,'*'

  insert into #lancamentos (tipo, docnum, cardcode, cardname, dt_vencimento, valor)
       SELECT tipo
          , docnum
          , CardCode
          , cardname
          , dt_vencimento 
          , sum(vl_saldo)* -1
    FROM (
		 select
			 CASE 
				when Origem='30' then 'OJDT'
				when Origem='18' then 'OPCH'
				else '????'
			 end AS 'tipo' 
			, OrigemNr as 'docnum'
			, ShortName as 'CardCode'
			, CardName as 'cardname'
			, Vencimento as 'dt_vencimento'
			, Saldo as 'vl_saldo'

		 from
			#ContasAPagarPorVencimento
     -- select   
     --  'OJDT' as tipo,
		   -- OCRD.CardCode,
		   -- OCRD.CardName 	AS cardname,
     --  ojdt.TransId as DocNum, 
		    
		   -- OJDT.ObjType							AS tp_doc,
		   -- dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		   -- 1										AS nr_parcela,
		   -- OJDT.RefDate							AS dt_lancamento,
		   -- JDT1.DueDate							AS dt_vencimento,
		   -- NULL									AS dt_liquidacao,
		   -- DATEDIFF(day, JDT1.DueDate, GETDATE())	AS dias,
		   -- SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		   -- (
			  --  SUM(JDT1.Debit) + SUM(JDT1.Credit)
		   -- ) - (
			  --  ABS(
				 --   sum(JDT1.BalDueCred) 
				 --   - sum(JDT1.BalDueDeb)
			  --  )
		   -- )										AS vl_recebido,
		   -- ABS(
			  --  sum(JDT1.BalDueCred) 
			  --  - sum(JDT1.BalDueDeb)
		   -- )	AS vl_saldo,		
		   -- '-51'							AS forma_pgto,
		   -- 'Não definido'										AS forma_pgto_nome,
		   -- 'A'										AS situacao,
		   -- JDT1.BaseRef							AS doc_origem,
		   -- JDT1.TransType							AS tp_origem,
		   -- dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		   -- NULL									AS nr_nota,
		   -- NULL									AS cd_vendedor,
		   -- OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		   -- 'A'										AS sit_geral
	    --FROM OADM, JDT1
		   -- INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		   -- INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
	    --WHERE JDT1.BalDueCred <> 0
		   -- AND JDT1.TransType = 30
	    --GROUP BY OCRD.CardName, OCRD.CardCode, OJDT.TransId, OJDT.ObjType, OJDT.RefDate, JDT1.DueDate, JDT1.BaseRef, JDT1.TransType, OADM.CompnyName, OADM.TaxIdNum, JDT1.ShortName

	    --UNION ALL

	    --/*********************************************************************
	    --NOTAS FISCAIS DE Entrada EM ABERTO
	    --**********************************************************************/
	    --SELECT 
	    -- 'OPCH' as tipo,
		   -- OCRD.CardCode,
		   -- OCRD.CardName 	AS cardname,
		   -- OJDT.TransId							AS docentry,
		   -- OJDT.ObjType							AS tp_doc,
		   -- dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		   -- PCH6.InstlmntID							AS nr_parcela,
		   -- OPCH.DocDate							AS dt_lancamento,
		   -- PCH6.DueDate							AS dt_vencimento,
		   -- NULL									AS dt_liquidacao,
		   -- DATEDIFF(day, PCH6.DueDate, GETDATE())	AS dias,
		   -- SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		   -- (
			  --  SUM(JDT1.Debit) + SUM(JDT1.Credit)
		   -- ) - (
			  --  ABS(
				 --   MAX(JDT1.BalDueCred) 
				 --   - MAX(JDT1.BalDueDeb)
			  --  )
		   -- )										AS vl_recebido,
		   -- ABS(
			  --  MAX(JDT1.BalDueCred) 
			  --  - MAX(JDT1.BalDueDeb)
		   -- )										AS vl_saldo,
		   -- '-52'							AS forma_pgto,
		   -- 'Não definido'										AS forma_pgto_nome,
		   -- 'A'										AS situacao,
		   -- JDT1.BaseRef							AS doc_origem,
		   -- JDT1.TransType							AS tp_origem,
		   -- dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		   -- OPCH.Serial								AS nr_nota,
		   -- OPCH.SlpCode							AS cd_vendedor,
		   -- OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		   -- 'A'										AS sit_geral
	    --FROM OADM, JDT1
		   -- INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		   -- INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		   -- INNER JOIN OPCH ON OPCH.DocNum = JDT1.BaseRef
		   -- INNER JOIN PCH6 ON PCH6.DocEntry = OPCH.DocEntry AND PCH6.InstlmntID = JDT1.Line_ID+1
	    --WHERE JDT1.BalDueCred <> 0
		   -- AND JDT1.TransType = 18
	    --GROUP BY OCRD.CardName, OCRD.CardCode, OJDT.TransId, OJDT.ObjType, PCH6.InstlmntID, OPCH.DocDate, PCH6.DueDate, JDT1.BaseRef, JDT1.TransType, OPCH.Serial, OPCH.SlpCode, OADM.CompnyName, OADM.TaxIdNum

	    --UNION ALL

	    --/*********************************************************************
	    --CONTAS A Pagar - BOLETOS EM ABERTO
	    --**********************************************************************/
	    --SELECT 
	    --'OBOE' as tipo,
		   -- OCRD.CardCode,
		   -- OCRD.CardName 	AS cardname,
		   -- OVPM.DocEntry							AS docentry,
		   -- OVPM.ObjType							AS tp_doc,
		   -- dbo.funcJBCNomeObjeto(OVPM.ObjType) as tp_doc_Nome,
		   -- VPM2.InstId								AS nr_parcela,
		   -- OVPM.DocDate							AS dt_lancamento,
		   -- OBOE.DueDate							AS dt_vencimento,
		   -- OBOE.PmntDate							AS dt_liquidacao,
		   -- DATEDIFF(day, OBOE.DueDate, GETDATE())	AS dias,
		   -- SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		   -- (
			  --  SUM(JDT1.Debit) + SUM(JDT1.Credit)
		   -- ) - (
			  --  ABS(
				 --   MAX(JDT1.BalDueCred) 
				 --   - MAX(JDT1.BalDueDeb)
			  --  )
		   -- )										AS vl_recebido,
		   -- ABS(
			  --  MAX(JDT1.BalDueCred) 
			  --  - MAX(JDT1.BalDueDeb)
		   -- )										AS vl_saldo,
		   -- OBOE.PayMethCod	AS forma_pgto,
		   -- OBOE.PymMethNam AS forma_pgto_nome,
		   -- 'A'										AS situacao,
		   -- JDT1.BaseRef							AS doc_origem,
		   -- JDT1.TransType							AS tp_origem,
		   -- dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		   -- NULL									AS nr_nota,
		   -- NULL									AS cd_vendedor,
		   -- OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		   -- 'A'										AS sit_geral
	    --FROM OADM, JDT1
		   -- INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		   -- INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		   -- INNER JOIN OVPM ON OVPM.DocEntry = JDT1.BaseRef
		   -- INNER JOIN VPM2 ON VPM2.DocNum = OVPM.DocEntry AND VPM2.InstId = JDT1.Line_ID+1
		   -- INNER JOIN OBOE ON OBOE.BoeKey = OVPM.BoeAbs
	    --WHERE JDT1.BalDueDeb <> 0
		   -- AND JDT1.TransType = 24
	    --GROUP BY OCRD.CardName, OCRD.CardCode, OVPM.DocEntry, OVPM.ObjType, VPM2.InstId, OVPM.DocDate, OBOE.DueDate, OBOE.PmntDate, OBOE.PayMethCod, OBOE.PymMethNam, JDT1.BaseRef, JDT1.TransType, OADM.CompnyName, OADM.TaxIdNum

	    --UNION ALL

	    --/*********************************************************************
	    --CONTAS A Pagar - CHEQUES EM ABERTO
	    --**********************************************************************/
	    --SELECT 
	    --'OCHH' as tipo,
		   -- OCRD.CardCode,
		   -- OCRD.CardName 	AS cardname,
		   -- OVPM.DocEntry							AS docentry,
		   -- OVPM.ObjType							AS tp_doc,
		   -- dbo.funcJBCNomeObjeto(OVPM.ObjType) as tp_doc_Nome,
		   -- VPM2.InstId								AS nr_parcela,
		   -- OCHH.RcptDate							AS dt_lancamento,
		   -- OCHH.CheckDate							AS dt_vencimento,
		   -- NULL									AS dt_liquidacao,
		   -- DATEDIFF(day, OCHH.CheckDate, GETDATE())AS dias,
		   -- SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		   -- (
			  --  SUM(JDT1.Debit) + SUM(JDT1.Credit)
		   -- ) - (
			  --  ABS(
				 --   MAX(JDT1.BalDueCred) 
				 --   - MAX(JDT1.BalDueDeb)
			  --  )
		   -- )										AS vl_recebido,
		   -- ABS(
			  --  MAX(JDT1.BalDueCred) 
			  --  - MAX(JDT1.BalDueDeb)
		   -- )										AS vl_saldo,
		   -- '-53'					AS forma_pgto,
		   -- 'Cheque - A Depositar'										AS forma_pgto_nome,
		   -- 'A'										AS situacao,
		   -- JDT1.BaseRef							AS doc_origem,
		   -- JDT1.TransType							AS tp_origem,
		   -- dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		   -- NULL									AS nr_nota,
		   -- NULL									AS cd_vendedor,
		   -- OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		   -- 'A'										AS sit_geral
	    --FROM OADM, JDT1
		   -- INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		   -- INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		   -- INNER JOIN OVPM ON OVPM.DocEntry = JDT1.BaseRef
		   -- INNER JOIN VPM2 ON VPM2.DocNum = OVPM.DocEntry AND VPM2.InstId = JDT1.Line_ID+1
		   -- INNER JOIN RCT1 ON RCT1.DocNum = OVPM.DocEntry
		   -- INNER JOIN OCHH ON OCHH.CheckKey = RCT1.CheckAbs

	    --WHERE JDT1.BalDueDeb <> 0
		   -- AND JDT1.TransType = 24
	    --GROUP BY OCRD.CardName, OCRD.CardCode, OVPM.DocEntry, OVPM.ObjType, VPM2.InstId, OVPM.DocDate, OCHH.RcptDate, 
	    --OCHH.CheckDate, JDT1.BaseRef, JDT1.TransType, OADM.CompnyName, OADM.TaxIdNum
  ) as completo
    where completo.dt_vencimento <= @dt 
    group by tipo, docnum, cardcode, cardname, dt_vencimento
  
  

  insert into #lancamentos (tipo, docnum, cardcode, cardname, dt_vencimento, valor)
       SELECT tipo
          , docnum
          , CardCode
          , cardname
          , dt_vencimento 
          , sum(vl_saldo)
    FROM (

		 select
			 CASE 
				when TransType='30' then 'OJDT'
				when TransType='13' then 'OINV'
				when TransType='14' then 'ORIN'
				when TransType='24' then 'ORCT'
				else '????'
			 end AS 'tipo' 
			, BaseRef as 'docnum'
			, ShortName as 'CardCode'
			, CardName as 'cardname'
			, DueDate as 'dt_vencimento'
			, Saldo as 'vl_saldo'


	--TransId int, 
	--Line_ID int, 
	--Account nvarchar(30),
	--ShortName  nvarchar(30),
	--TransType nvarchar(40),
	--CreatedBy int,
	--BaseRef nvarchar(22),
	--SourceLine smallint,
	--RefDate datetime,
	--DueDate datetime,
	--BalDueCred decimal(19, 9),
	--BalDueDeb decimal(19, 9),
	--BalDueCredBalDueDeb decimal(19, 9),
	--Saldo decimal(19, 9),
	--LineMemo nvarchar(100),
	--CardName nvarchar(200),
	--CardCode nvarchar(30),
	--Balance  decimal(19, 9),
	--SlpCode int,
	--DebitCredit  decimal(19, 9),
	--IsSales nvarchar(2),
	--Currency nvarchar(6),
	--BPLName nvarchar(20

		 from
			#ContasAReceberPorVencimento



  --  SELECT 
  --      'OJDT' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName 	AS cardname,
		--    OJDT.TransId							AS 'DocNum',
		--    OJDT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		--    1										AS nr_parcela,
		--    OJDT.RefDate							AS dt_lancamento,
		--    JDT1.DueDate							AS dt_vencimento,
		--    NULL									AS dt_liquidacao,
		--    DATEDIFF(day, JDT1.DueDate, GETDATE())	AS dias,
		--    JDT1.Debit + JDT1.Credit		AS vl_titulo,
		--    (
		--	    JDT1.Debit + JDT1.Credit
		--    ) - (
		--	    ABS(
		--		    JDT1.BalDueCred
		--		    - (JDT1.BalDueDeb)
		--	    )
		--    )										AS vl_recebido,
		--    ABS(
		--	    JDT1.BalDueCred
		--	    - JDT1.BalDueDeb
		--    )	AS vl_saldo,		
		--    '-51'							AS forma_pgto,
		--    'Não definido'										AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    NULL									AS nr_nota,
		--    NULL									AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
  --    from OADM, JDT1 
  --   inner join OJDT 
  --      on ojdt.TransId = jdt1.TransId 
  --   inner join OCRD
  --      on ocrd.CardCode = jdt1.ShortName 
  --   where 1 = 1 --jdt1.ShortName = 'C000262'
  --     and jdt1.BalDueDeb <> 0
  --     and jdt1.TransType = 30

	 --   UNION ALL

	 --   /*********************************************************************
	 --   NOTAS FISCAIS DE SAÍDA EM ABERTO
	 --   **********************************************************************/
	 --   SELECT 
	 --    'OINV' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName 	AS cardname,
		--    OJDT.TransId							AS docentry,
		--    OJDT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		--    INV6.InstlmntID							AS nr_parcela,
		--    OINV.DocDate							AS dt_lancamento,
		--    INV6.DueDate							AS dt_vencimento,
		--    NULL									AS dt_liquidacao,
		--    DATEDIFF(day, INV6.DueDate, GETDATE())	AS dias,
		--    SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		--    (
		--	    SUM(JDT1.Debit) + SUM(JDT1.Credit)
		--    ) - (
		--	    ABS(
		--		    MAX(JDT1.BalDueCred) 
		--		    - MAX(JDT1.BalDueDeb)
		--	    )
		--    )										AS vl_recebido,
		--    ABS(
		--	    MAX(JDT1.BalDueCred) 
		--	    - MAX(JDT1.BalDueDeb)
		--    )										AS vl_saldo,
		--    '-52'							AS forma_pgto,
		--    'Não definido'										AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    OINV.Serial								AS nr_nota,
		--    OINV.SlpCode							AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
	 --   FROM OADM, JDT1
		--    INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		--    INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		--    INNER JOIN OINV ON OINV.DocNum = JDT1.BaseRef
		--    INNER JOIN INV6 ON INV6.DocEntry = OINV.DocEntry AND INV6.InstlmntID = JDT1.Line_ID+1
	 --   WHERE JDT1.BalDueDeb <> 0
		--    AND JDT1.TransType = 13
	 --   GROUP BY OCRD.CardName, OCRD.CardCode, OJDT.TransId, OJDT.ObjType, INV6.InstlmntID, OINV.DocDate, INV6.DueDate, JDT1.BaseRef, JDT1.TransType, OINV.Serial, OINV.SlpCode, OADM.CompnyName, OADM.TaxIdNum

	 --   UNION ALL

	 --   /*********************************************************************
	 --   CONTAS A RECEBER - BOLETOS EM ABERTO
	 --   **********************************************************************/
    	
    	
	 --   SELECT 
	 --   'OBOE' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName	AS cardname,
		--    ORCT.DocEntry							AS docentry,
		--    ORCT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(ORCT.ObjType) as tp_doc_Nome,
		--    RCT2.InstId								AS nr_parcela,
		--    ORCT.DocDate							AS dt_lancamento,
		--    OBOE.DueDate							AS dt_vencimento,
		--    OBOE.PmntDate							AS dt_liquidacao,
		--    DATEDIFF(day, OBOE.DueDate, GETDATE())	AS dias,
		--    SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		--    --SUM(JDT1.Debit) 		AS vl_titulo,
		--    ( SUM(JDT1.Debit) + SUM(JDT1.Credit) ) - ( ABS ( MAX(JDT1.BalDueCred) - MAX(JDT1.BalDueDeb)	)	) AS vl_recebido,
		--    ABS(MAX(JDT1.BalDueCred) - MAX(JDT1.BalDueDeb)) AS vl_saldo,
		--    OBOE.PayMethCod	AS forma_pgto,
		--    OBOE.PymMethNam AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    NULL									AS nr_nota,
		--    NULL									AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
	 --   FROM OADM, JDT1
		--    INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		--    INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		--    INNER JOIN ORCT ON ORCT.DocEntry = JDT1.BaseRef
		--    INNER JOIN RCT2 ON RCT2.DocNum = ORCT.DocEntry 
		--      and jdt1.Line_ID = 0
		--    INNER JOIN OBOE ON OBOE.BoeKey = ORCT.BoeAbs
	 --   WHERE 1 = 1 and JDT1.BalDueDeb <> 0
		--    AND JDT1.TransType = 24
		--    and oboe.BoeStatus not in ('P', 'C') -- depositado, pago.
	 --   GROUP BY OCRD.CardName, OCRD.CardCode, ORCT.DocEntry, ORCT.ObjType, RCT2.InstId, ORCT.DocDate, OBOE.DueDate, OBOE.PmntDate, OBOE.PayMethCod, OBOE.PymMethNam, JDT1.BaseRef, JDT1.TransType, OADM.CompnyName, OADM.TaxIdNum

	 --   UNION ALL

	 --   /*********************************************************************
	 --   CONTAS A RECEBER - CHEQUES EM ABERTO
	 --   **********************************************************************/
	 --   SELECT 
	 --   'OCHH' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName 	AS cardname,
		--    ORCT.DocEntry							AS docentry,
		--    ORCT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(ORCT.ObjType) as tp_doc_Nome,
		--    RCT2.InstId								AS nr_parcela,
		--    OCHH.RcptDate							AS dt_lancamento,
		--    OCHH.CheckDate							AS dt_vencimento,
		--    NULL									AS dt_liquidacao,
		--    DATEDIFF(day, OCHH.CheckDate, GETDATE())AS dias,
		--    SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		--    (
		--	    SUM(JDT1.Debit) + SUM(JDT1.Credit)
		--    ) - (
		--	    ABS(
		--		    MAX(JDT1.BalDueCred) 
		--		    - MAX(JDT1.BalDueDeb)
		--	    )
		--    )										AS vl_recebido,
		--    ABS(
		--	    MAX(JDT1.BalDueCred) 
		--	    - MAX(JDT1.BalDueDeb)
		--    )										AS vl_saldo,
		--    '-53'					AS forma_pgto,
		--    'Cheque - A Depositar'										AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    NULL									AS nr_nota,
		--    NULL									AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
	 --   FROM OADM, JDT1
		--    INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		--    INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		--    INNER JOIN ORCT ON ORCT.DocEntry = JDT1.BaseRef
		--    INNER JOIN RCT2 ON RCT2.DocNum = ORCT.DocEntry AND RCT2.InstId = JDT1.Line_ID+1
		--    INNER JOIN RCT1 ON RCT1.DocNum = ORCT.DocEntry
		--    INNER JOIN OCHH ON OCHH.CheckKey = RCT1.CheckAbs

	 --   WHERE JDT1.BalDueDeb <> 0
		--    AND JDT1.TransType = 24
	 --   GROUP BY OCRD.CardName, OCRD.CardCode, ORCT.DocEntry, ORCT.ObjType, RCT2.InstId, ORCT.DocDate, OCHH.RcptDate, OCHH.CheckDate, JDT1.BaseRef, JDT1.TransType, OADM.CompnyName, OADM.TaxIdNum


  --  UNION ALL

	 --   /*********************************************************************
	 --   ADIANTAMENTOS DE CLIENTE PENDENTES
	 --   **********************************************************************/
    	
  --  SELECT 
  --  'ODPI' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName 	AS cardname,
		--    OJDT.TransId							AS docentry,
		--    OJDT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		--    dpi6.InstlmntID							AS nr_parcela,
		--    ODPI.DocDate							AS dt_lancamento,
		--    dpi6.DueDate							AS dt_vencimento,
		--    NULL									AS dt_liquidacao,
		--    DATEDIFF(day, dpi6.DueDate, GETDATE())	AS dias,
		--    SUM(JDT1.Debit) + SUM(JDT1.Credit)		AS vl_titulo,
		--    (
		--	    SUM(JDT1.Debit) + SUM(JDT1.Credit)
		--    ) - (
		--	    ABS(
		--		 MAX(JDT1.BalDueCred) 
		--		    - MAX(JDT1.BalDueDeb)
		--	    )
		--    )										AS vl_recebido,
		--    ABS(
		--	    MAX(JDT1.BalDueCred) 
		--	    - MAX(JDT1.BalDueDeb)
		--    )										AS vl_saldo,
		--    '-52'							AS forma_pgto,
		--    'Não definido'										AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    ODPI.Serial								AS nr_nota,
		--    ODPI.SlpCode							AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
	 --   FROM OADM, JDT1
		--    INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		--    INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		--    INNER JOIN ODPI ON ODPI.DocNum = JDT1.BaseRef
		--    INNER JOIN dpi6 ON dpi6.DocEntry = ODPI.DocEntry AND dpi6.InstlmntID = JDT1.Line_ID+1
	 --   WHERE JDT1.BalDueDeb <> 0
		--    AND JDT1.TransType = 203
	 --   GROUP BY OCRD.CardName, OCRD.CardCode, OJDT.TransId, OJDT.ObjType, dpi6.InstlmntID, ODPI.DocDate, dpi6.DueDate, JDT1.BaseRef, JDT1.TransType, ODPI.Serial, ODPI.SlpCode, OADM.CompnyName, OADM.TaxIdNum


  --  UNION ALL

  --  -- DEVOLUÇÕES DE VENDA PENDENTES

  --  SELECT 
  --  'ORIN' as tipo,
		--    OCRD.CardCode,
		--    OCRD.CardName 	AS cardname,
		--    OJDT.TransId							AS docentry,
		--    OJDT.ObjType							AS tp_doc,
		--    dbo.funcJBCNomeObjeto(OJDT.ObjType) as tp_doc_Nome,
		--    rin6.InstlmntID							AS nr_parcela,
		--    orin.DocDate							AS dt_lancamento,
		--    rin6.DueDate							AS dt_vencimento,
		--    NULL									AS dt_liquidacao,
		--    DATEDIFF(day, rin6.DueDate, GETDATE())	AS dias,
		--    (SUM(JDT1.Debit) + SUM(JDT1.Credit))	*(-1)	AS vl_titulo,
		--    ((
		--	    SUM(JDT1.Debit) + SUM(JDT1.Credit)
		--    ) - (
		--	    ABS(
		--		    MAX(JDT1.BalDueCred) 
		--		    - MAX(JDT1.BalDueDeb)
		--	    )
		--    )		) *(-1)								AS vl_recebido,
		--    (ABS(
		--	    MAX(JDT1.BalDueCred) 
		--	    - MAX(JDT1.BalDueDeb)
		--    )								)*(-1)		AS vl_saldo,
		--    '-52'							AS forma_pgto,
		--    'Não definido'										AS forma_pgto_nome,
		--    'A'										AS situacao,
		--    JDT1.BaseRef							AS doc_origem,
		--    JDT1.TransType							AS tp_origem,
		--    dbo.funcJBCNomeObjeto(JDT1.TransType) as tp_origem_Nome,
		--    orin.Serial								AS nr_nota,
		--    orin.SlpCode							AS cd_vendedor,
		--    OADM.CompnyName + '  ' + OADM.TaxIdNum	AS NomeEmpresa,
		--    'A'										AS sit_geral
	 --   FROM OADM, JDT1
		--    INNER JOIN OJDT ON OJDT.TransId = JDT1.TransId
		--    INNER JOIN OCRD ON OCRD.CardCode = JDT1.ShortName
		--    INNER JOIN orin ON orin.DocNum = JDT1.BaseRef
		--    INNER JOIN rin6 ON rin6.DocEntry = orin.DocEntry AND rin6.InstlmntID = JDT1.Line_ID+1
	 --   WHERE 1 = 1
	 --     and JDT1.BalDueCred <> 0
		--    AND JDT1.TransType = 14
	 --   GROUP BY OCRD.CardName, OCRD.CardCode, OJDT.TransId, OJDT.ObjType, rin6.InstlmntID, orin.DocDate, rin6.DueDate, 
	 --   JDT1.BaseRef, JDT1.TransType, orin.Serial, orin.SlpCode, OADM.CompnyName, OADM.TaxIdNum
  ) as completo
    where completo.dt_vencimento <= @dt 
    group by tipo, docnum, cardcode, cardname, dt_vencimento

  


  delete from #lancamentos
   where dt_vencimento > @dt
   
   
   
  if @atrasos = 'N'
    delete from #lancamentos
     where convert(char(10), dt_vencimento, 120) < convert(char(10), GETDATE(), 120)

  declare @saldo_final decimal(19, 2)
  
  create table #saldo (acctcode varchar(72) null, saldo money null)
  
  insert into #saldo
    exec spcJBCBalancete1 @caixa 
  
  select @saldo_inicial = SUM(saldo) from #saldo 
  

  select @saldo_inicial = ISNULL(@saldo_inicial, 0)  

---------------
  select dt_vencimento as 'Data'
       , tipo as 'Tipo'
       , CASE tipo
           when 'OJDT' then 'L.C.'
           when 'OINV' then 'NF Venda'
           when 'OPCH' then 'NF Compra'
           when 'OBOE' then 'Boleto'
           when 'PV' then 'P. Venda'
           when 'PC' then 'P. Compra'
           when 'OCHH' then 'Cheque'
           when 'ORCT' then 'Contas À Receber'
           else tipo end 'TP'
       , DocNum as 'Numero'
       , CardCode as 'Cliente'
       , CardName as 'Razão'
       , valor as 'Valor'
       , saldo as 'Saldo'
       , ROW_NUMBER() over (order by dt_vencimento, tipo, docnum, cardcode) as linha
     into #final
    from #lancamentos 
   order by dt_vencimento, tipo, docnum, cardcode

  declare cp1 cursor local fast_forward for
    select linha, valor
      from #final
     order by 1
     
  open cp1
  
  while 1 = 1
  begin
    fetch next from cp1 into @vlinha, @vvalor
    if @@FETCH_STATUS <> 0 break
        
    select @saldo_inicial = @saldo_inicial + isnull(@vvalor, 0)
    
    update #final 
       set saldo = @saldo_inicial
     where linha = @vlinha 

  end
  close cp1
  deallocate cp1

 select * from #final order by linha 





GO


--exec spcJBCFluxoCaixa_CARGA_Analitico '2050-01-01', 'S', 'N'