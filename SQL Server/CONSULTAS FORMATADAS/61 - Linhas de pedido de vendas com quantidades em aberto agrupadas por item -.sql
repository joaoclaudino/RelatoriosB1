
use SBODemoBR 
 
go 
 

 --Linhas de pedido de vendas com quantidades em aberto agrupadas por item

SELECT 
	T0.[ITEMCODE],
	T0.[DSCRIPTION],
	SUM(T0.[OPENQTY]) AS 'Quantidade em Aberto',
	SUM(T0.[LINETOTAL]) AS 'Total'
FROM 
	RDR1 T0
	INNER JOIN ORDR T1 ON T0.DOCENTRY = T1.DOCENTRY
where
	T1.[DOCSTATUS] = 'O'
	AND T0.[LINESTATUS] ='O'
	and T0.[OPENQTY]>0
GROUP BY 
	T0.[ITEMCODE],
	T0.[DSCRIPTION] 
		 