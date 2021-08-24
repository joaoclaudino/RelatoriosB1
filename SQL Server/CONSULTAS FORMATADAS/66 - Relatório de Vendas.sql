use SBODemoBR 
 
go 
 

--Relatório de Vendas
SELECT
   'Nota de Venda' as Tipo,
   OINV.CardCode,
   OINV.CardName,
   OINV.DocDate,
   OINV.DocDueDate 'VENCIMENTO',
   DATEPART(MONTH, OINV.DocDate) 'MES',
   DATEPART(YEAR, OINV.DocDate) 'ANO',
   OINV.DocEntry,
   OINV.Serial,
   OINV.Installmnt 'PRESTACOES',
   INV1.ItemCode,
   INV1.Dscription,
   INV1.Quantity,
   INV1.Price,
   (
      INV1.Quantity * INV1.Price
   )
   'TOTAL' 
FROM
   OINV 
   INNER JOIN
      INV1 INV1 
      ON INV1.DocEntry = OINV.DocEntry 
WHERE
   CANCELED = 'N' 
UNION ALL
SELECT
   'Devolução' as Tipo,
   ORIN.CardCode,
   ORIN.CardName,
   ORIN.DocDate,
   ORIN.DocDueDate 'VENCIMENTO',
   DATEPART(MONTH, ORIN.DocDate) 'MES',
   DATEPART(YEAR, ORIN.DocDate) 'ANO',
   ORIN.DocEntry,
   ORIN.Serial,
   ORIN.Installmnt,
   RIN1.ItemCode,
   RIN1.Dscription,
   RIN1.Quantity * - 1,
   RIN1.Price,
   (
		(RIN1.Quantity * RIN1.Price) * - 1
   )
   'TOTAL' 
FROM
   ORIN 
   INNER JOIN
      RIN1 RIN1 
      ON RIN1.DocEntry = ORIN.DocEntry 
WHERE
   CANCELED = 'N' 
   AND rin1.BaseEntry IN 
   (
      SELECT
         OINV .DocEntry 
      FROM
         OINV 
         INNER JOIN
            INV1 INV1 
            ON INV1.DocEntry = OINV.DocEntry 
      WHERE
         CANCELED = 'N' 
   )
ORDER BY 4,8