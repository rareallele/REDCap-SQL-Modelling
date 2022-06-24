SELECT distinct a.CaseNumber AS "case_number",
	STUFF((SELECT '\r\r' + (SELECT(CAST(FORMAT(sal.StatusActivityDate, 'dd-MM-yyyy') AS varchar) + ':   ')) + (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sal.StatusActivityDetails, 
								 CHAR(13), '\r'), 
										 CHAR(10), '\r'), 
												 '•', '\u2022'),
														 '–', '\u2013'),
																 '&', '\u0026'),
																		 '''', '\u0027'),
																				 '’', '\u0027'),
																						 '‘', '\u0027') AS [*] FOR XML Path('')) --Replace special characters with unicode representations
		   FROM StatusActivityList sal
		   WHERE sal.CaseID = MAX(a.ID)
		   FOR XML PATH(''), type).value('.', 'nvarchar(max)'), 1, 2, '') AS "cdr_status_entries"
	 	
FROM CDRCase a
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN AgeSiblings d
ON a.ID = d.CaseID
OUTER APPLY 
	(
	SELECT 
	DATEDIFF(year, a.DateOfBirth, d.DateOfDeath) -
		CASE
			WHEN DATEADD(year, DATEDIFF(year, a.DateOfBirth, d.DateOfDeath), a.DateOfBirth)
				> DateOfDeath THEN 1
			ELSE 0
		END AS "Age (years)")
	AS age
WHERE ((StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "Age (years)" < 18) OR (StatusAtEvent.ItemText = 'seriously injured')) 
GROUP BY a.CaseNumber
ORDER BY a.CaseNumber
;