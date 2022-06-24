SELECT  a.CaseNumber AS case_number,

		-- Cause of death
		CASE 
			WHEN Causes.CauseOfDeath IS NULL THEN ''
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Causes.CauseOfDeath, 
								 CHAR(13), '\r'), 
										 CHAR(10), '\r'), 
												 '•', '\u2022'),
														 '–', '\u2013'),
																 '&', '\u0026'),
																		 '''', '\u0027'),
																				 '’', '\u0027'),
																						 '‘', '\u0027') --Replace special characters with unicode representations
		END AS "cause_of_death",

		-- Category of death
		CASE 
			WHEN circ.HarmDescription IS NULL THEN ''
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(circ.HarmDescription, 
								 CHAR(13), '\r'), 
										 CHAR(10), '\r'), 
												 '•', '\u2022'),
														 '–', '\u2013'),
																 '&', '\u0026'),
																		 '''', '\u0027'),
																				 '’', '\u0027'),
																							'‘', '\u0027') --Replace special characters with unicode representations
		END AS "circumstances_of_harm"

FROM CDRCase a
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN Circumstances circ ON a.ID = circ.CaseID
LEFT JOIN CauseOfDeathCategories c
ON circ.CauseOfDeathCategoryID = c.ID
LEFT JOIN AgeSiblings d
ON a.ID = d.CaseID
OUTER APPLY 
	(
	SELECT 
	DATEDIFF(year, DateOfBirth, DateOfDeath) -
		CASE
			WHEN DATEADD(year, DATEDIFF(year, DateOfBirth, DateOfDeath), DateOfBirth)
				> DateOfDeath THEN 1
			ELSE 0
		END AS "age_years") 
		AS age

LEFT JOIN Causes 
ON a.ID = Causes.CaseID

WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18) OR (StatusAtEvent.ItemText = 'seriously injured')
