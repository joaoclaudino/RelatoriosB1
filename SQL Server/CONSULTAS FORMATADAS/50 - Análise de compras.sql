use SBODemoBR 
 
go 
 
  
  --Análise de compras

SELECT
   T0.[DocEntry],
   T0.[CardCode],
   T0.[CardName],
   T0.[DocDate],
   T0.[DocTotal] 
FROM
   OPCH T0 
WHERE
   T0.[DocDate] BETWEEN [%0] AND [%1] 
   AND 
   (
		T0.[CardCode] = '[%2]'
		or ''= '[%2]'
	)