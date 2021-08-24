
use SBODemoBR 
 
go 
 


 --Linhas Abertas de pedido de venda por cliente

SELECT T0.[CARDCODE],
       T0.[CARDNAME],
       T0.[DOCNUM],
       T0.[DOCDATE],
       T1.[ITEMCODE],
       T1.[DSCRIPTION],
       T1.[QUANTITY],
       T1.[OPENQTY],
       T1.[PRICE],
       T1.[LINETOTAL]
FROM ORDR T0
INNER JOIN RDR1 T1 ON T0.DOCENTRY = T1.DOCENTRY
WHERE T0.[DOCSTATUS] = 'O'
  AND T1.[LINESTATUS] ='O'
  AND T0.[CARDCODE]  = '[%0]'
  AND T0.[DOCDATE] between [%1] and [%2] 