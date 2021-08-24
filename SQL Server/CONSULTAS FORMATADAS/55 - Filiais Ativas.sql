use SBODemoBR 
 
go 
 

--Filiais Ativas
SELECT
   CAST(T0.BPLId AS NVARCHAR(30)) AS Codigo,
   T0.BPLName Nome 
FROM
   OBPL T0 
WHERE
   T0.Disabled <> 'Y' 
ORDER BY
   2