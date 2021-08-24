
use SBODemoBR 
 
go 
 
 --Itens em estoque classificados por grupo de itens

SELECT 
	T0.[ITEMCODE],
	T0.[ITEMNAME],
	T0.[ITMSGRPCOD],
	T1.[ITMSGRPNAM],
	T0.[ONHAND] 'Em Estoque',
	T0.[ONORDER] 'Pedidos',
	T3.[CARDCODE],
	T3.CardName
FROM 
	OITM T0
	INNER JOIN OITB T1 ON T0.ITMSGRPCOD = T1.ITMSGRPCOD
	INNER JOIN OITW T2 ON T0.ITEMCODE = T2.ITEMCODE
	left join OCRD T3 on T3.CardCode=T0.CardCode
ORDER BY 
	T1.[ITMSGRPNAM] 