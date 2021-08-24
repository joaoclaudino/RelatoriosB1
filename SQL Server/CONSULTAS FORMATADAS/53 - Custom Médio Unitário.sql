use SBODemoBR 
 
go 
 
 --Custom Médio Unitário


SELECT
   T1.ItemCode,
   T1.ItemName,
   OutQty as 'Quantidade Saída', 
   Price as 'Preço de Saída', 
   CogsVal as 'custo' ,
   CASE
      WHEN
         OutQty = 0 
      THEN
         0 
      ELSE
         round((CogsVal / OutQty), 2) 
   END
   AS 'Custo Médio Unitário'
FROM
   OINM T0
   INNER JOIN
      OITM T1
      ON T1.ItemCode = T0.ItemCode 
WHERE
   T0.CreateDate BETWEEN [%0] AND [%1] 
   and TransType IN 
   (
      13, 15 
   )