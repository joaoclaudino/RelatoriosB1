USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCBalancete1]    Script Date: 06/09/2015 09:17:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spcJBCBalancete1]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spcJBCBalancete1]
GO

USE SDO_DESENV
GO

/****** Object:  StoredProcedure [dbo].[spcJBCBalancete1]    Script Date: 06/09/2015 09:17:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



  
-- 
CREATE procedure [dbo].[spcJBCBalancete1]  
  @caixa char(1) = 'N'  
with encryption
as  

  if @caixa = 'S'  
    select OACT.AcctCode  + ' ' + upper(OACT.AcctName) 'AcctName'  
         , oact.CurrTotal as 'Saldo'  
      from OACT   
     where ( OACT.FINANSE = 'Y' )  
  else  
    select OACT.AcctCode  + ' ' + upper(OACT.AcctName) 'AcctName'  
         , oact.CurrTotal as 'Saldo'  
      from OACT   
     where ( OACT.FINANSE = 'Y'  )  
       and oact.AcctName not like 'Caixa%'  
  
  
  


GO


--exec spcJBCBalancete1 'N'  