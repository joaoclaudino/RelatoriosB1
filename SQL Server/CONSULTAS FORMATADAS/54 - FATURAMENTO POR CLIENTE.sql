use SBODemoBR 
 
go 
 
 --FATURAMENTO POR CLIENTE

SELECT DISTINCT
   'Nota de Venda' as Tipo,
   T0.DocEntry,
   T0.DocNum,
   T0.Serial,
   T0.DocDate,
   T0.CardCode,
   T0.CardName,
   T0.DocTotal
FROM
   OINV T0
WHERE
   T0.ObjType = 13 
   AND T0.CANCELED = 'N' 
   AND T0.DocDate BETWEEN [%0] AND [%1]
UNION ALL
SELECT DISTINCT
   'Devolução de Venda' as Tipo,
   T0.DocEntry,
   T0.DocNum,
   T0.Serial,
   T0.DocDate,
   T0.CardCode,
   T0.CardName,
   T0.DocTotal *-1
FROM
   ORIN T0
WHERE
   T0.ObjType = 14 
   AND T0.CANCELED = 'N' 
   AND T0.DocDate BETWEEN [%0] AND [%1]
ORDER BY
   6,
   1