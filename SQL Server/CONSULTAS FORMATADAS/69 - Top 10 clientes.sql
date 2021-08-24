use SBODemoBR 
 
go 
 
  --Top 10 clientes

SELECT
   TOP 10 
   T0.CardCode,
   MAX(T0.Cardname) AS Customer,
   SUM(T0.doctotal) AS 'Valor Total' 
FROM
   dbo.OINV T0 
WHERE   
	t0.docdate BETWEEN [%0] AND [%1] 
GROUP BY
   T0.CardCode 
ORDER BY
   SUM(T0.doctotal) DESC