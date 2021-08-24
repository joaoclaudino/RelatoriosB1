
use SBODemoBR 
 
go 
 

 --Saldos de contas de parceiros de negócios e endereços de cobrança
SELECT T0.[CARDCODE],
       T0.[CARDNAME],
       T0.[GROUPCODE],
       T0.[CNTCTPRSN],
       T0.[BALANCE],
       T1.[STREET],
       T1.[BLOCK],
       T1.[CITY],
       T1.[STATE],
       T1.[ZIPCODE]
FROM OCRD T0
INNER JOIN CRD1 T1 ON T0.CARDCODE = T1.CARDCODE
WHERE T1.[ADRESTYPE] ='B'
  AND T0.[BALANCE] >0
ORDER BY T0.[GROUPCODE],
         T0.[CARDCODE]
		 