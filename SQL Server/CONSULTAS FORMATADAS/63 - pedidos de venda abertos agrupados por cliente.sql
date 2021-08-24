
use SBODemoBR 
 
go 
 
 --pedidos de venda abertos agrupados por cliente

SELECT 
	T0.[CARDCODE],
	T0.[CARDNAME],
	SUM(T0.[DOCTOTAL])
FROM 
	ORDR T0
WHERE 
	T0.[DOCSTATUS] ='O'
GROUP BY 
	T0.[CARDCODE],
	T0.[CARDNAME] 