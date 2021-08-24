
use SBODemoBR 
 
go 
 

--Pedidos de venda abertos por cliente

SELECT 
	T0.[CARDCODE],
	T0.[CARDNAME],
	T0.DocEntry,
	T0.[DOCNUM],
	T0.[DOCDATE],
	T0.[DOCTOTAL]
FROM 
	ORDR T0
WHERE 
	T0.[DOCSTATUS] ='O'
	and T0.CardCode= '[%0]'
ORDER BY 
	T0.[CARDCODE] 
