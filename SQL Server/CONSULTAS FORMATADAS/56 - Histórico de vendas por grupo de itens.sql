use SBODemoBR 
 
go 
 

--Histórico de vendas por grupo de itens
SELECT
   T0.[DocEntry],
   T0.[DocNum],
   T0.[DocDate],
   T0.[CardName],
   T2.[ItmsGrpCod],
   T3.ItmsGrpNam,
   T2.[ItemCode],
   T2.[ItemName],
   T1.[Quantity] 
FROM
   ORDR T0 
   INNER JOIN
      RDR1 T1 
      ON T0.DocEntry = T1.DocEntry 
   INNER JOIN
      OITM T2 
      ON T1.ItemCode = T2.ItemCode 
	inner join OITB T3 on T3.ItmsGrpCod=T2.[ItmsGrpCod]
WHERE
   T2.[ItmsGrpCod] = [%0] 
   AND T0.[DocDate] BETWEEN [%1] AND [%2]