
use SBODemoBR 
 
go 
 

 --Balancete por grupo de parceiro de negócios
SELECT 
	T1.[GROUPNAME],
    SUM(T0.[BALANCE])
FROM 
	OCRD T0
	INNER JOIN OCRG T1 ON T0.GROUPCODE = T1.GROUPCODE
GROUP BY 
	T1.[GROUPNAME]