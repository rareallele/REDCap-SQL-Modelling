SELECT MAX(a.CaseNumber) AS "case_number", 
	
	MAX(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sal.StatusActivityDetails, 
								 CHAR(13), '\r'), 
										 CHAR(10), '\r'), 
												 '•', '\u2022'),
														 '–', '\u2013'),
																 '&', '\u0026'),
																		 '''', '\u0027'),
																				 '’', '\u0027'),
																						'‘', '\u0027')) AS screening_outcomes

	 	
FROM CDRCase a
LEFT JOIN StatusActivityList sal ON a.ID = sal.CaseID
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
WHERE (UPPER(sal.StatusActivityDetails) LIKE '%PRESENTED THIS CASE%' OR UPPER(sal.StatusActivityDetails) LIKE '%SCREENED BY%') AND (UPPER(sal.StatusActivityDetails) NOT LIKE '%BY THE DISAB%' AND UPPER(sal.StatusActivityDetails) NOT LIKE '%BY DISAB%') AND ((StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "Age (years)" < 18) OR (StatusAtEvent.ItemText = 'seriously injured')) --AND a.CaseNumber<150
GROUP BY a.CaseNumber
ORDER BY a.CaseNumber
;