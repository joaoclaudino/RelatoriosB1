
use SBODemoBR 
 
go 
 
 --Pedidos de compra abertos por fornecedor
SELECT 
	T0.[CARDCODE],
	T0.[CARDNAME],
	T0.[DocEntry],
	T0.[DOCNUM],
	T0.[DOCDATE],
	T0.[DOCDUEDATE],
	T0.[DOCTOTAL]
FROM 
	OPOR T0
WHERE 
	T0.[DOCSTATUS] ='O'
ORDER BY 
	T0.[CARDNAME] 