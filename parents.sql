SELECT 
	a.CaseNumber AS "case_number",

	MAX(CASE WHEN r.ItemText = 'Mother' THEN c.Surname END) AS "mother_surname",
	MAX(CASE WHEN r.ItemText = 'Mother' THEN c.GivenNames END) AS "mother_givenname",
	MAX(CASE WHEN r.ItemText = 'Mother' THEN c.CarerAlias END) AS "mother_alias",
	MAX(CASE WHEN r.ItemText = 'Mother' THEN FORMAT(c.DateOfBirth, 'dd/MM/yyyy') END) AS "mother_dob",

	MAX(CASE WHEN r.ItemText = 'Father' THEN c.Surname END) AS "father_surname",
	MAX(CASE WHEN r.ItemText = 'Father' THEN c.GivenNames END) AS "father_givenname",
	MAX(CASE WHEN r.ItemText = 'Father' THEN c.CarerAlias END) AS "father_alias",
	MAX(CASE WHEN r.ItemText = 'Father' THEN FORMAT(c.DateOfBirth, 'dd/MM/yyyy') END) AS "father_dob"

FROM CDRCase a
LEFT JOIN Carers c
ON a.ID = c.CaseID
LEFT JOIN Relationship r
ON c.RelationshipID = r.ID
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
WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "Age (years)" < 18) OR StatusAtEvent.ItemText = 'seriously injured'
GROUP BY a.CaseNumber;
