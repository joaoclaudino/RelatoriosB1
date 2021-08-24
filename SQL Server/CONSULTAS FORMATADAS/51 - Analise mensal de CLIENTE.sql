use SBODemoBR_31_10_2020 
 
go 
 
 --Análise Mensal de CLIENTE
 IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pcdJBC_AnaliseMensalDoCliente]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[pcdJBC_AnaliseMensalDoCliente]
GO

USE SBODemoBR_31_10_2020
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc  [dbo].[pcdJBC_AnaliseMensalDoCliente]
  @CardCode varchar(200)
as

  select case MONTH(docdate)
           when 1 then 'Janeiro'
           when 2 then 'Fevereiro'
           when 3 then 'Março'
           when 4 then 'Abril'
           when 5 then 'Maio'
           when 6 then 'Junho'
           when 7 then 'Julho'
           when 8 then 'Agosto'
           when 9 then 'Setembro'
           when 10 then 'Outubro'
           when 11 then 'Novembro'
           when 12 then 'Dezembro' end + '/' + RTRIM(year(docdate)) as 'Período'
       , SUM(oinv.doctotal) as 'Valor'
    from OINV
   where CANCELED = 'N'
     and CardCode = @CardCode
   group by case MONTH(docdate)
           when 1 then 'Janeiro'
           when 2 then 'Fevereiro'
           when 3 then 'Março'
           when 4 then 'Abril'
           when 5 then 'Maio'
           when 6 then 'Junho'
           when 7 then 'Julho'
           when 8 then 'Agosto'
           when 9 then 'Setembro'
           when 10 then 'Outubro'
           when 11 then 'Novembro'
           when 12 then 'Dezembro' end + '/' + RTRIM(year(docdate))
		   ,MONTH(docdate),year(docdate)
order by MONTH(docdate),year(docdate)

go


/*Select  1  From OCRD T0 Where T0.CardCode =[%0]*/
DECLARE @Cliente AS VARCHAR(50)
SET @Cliente = '[%0]'

select @Cliente 

execute pcdJBC_AnaliseMensalDoCliente @Cliente 
   

