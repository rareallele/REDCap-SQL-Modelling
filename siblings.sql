SELECT
	a.CaseNumber AS "case_number",

	c.GivenNames AS sibling_givenname,
	c.Surname AS sibling_surname,
	FORMAT(c.DateOfBirth, 'dd/MM/yyyy') AS sibling_dob,
	r.ItemText AS sibling_rel,

	-- Count each case's siblings
	ROW_NUMBER() OVER (
		PARTITION BY a.CaseNumber, r.ItemText
		ORDER BY a.CaseNumber) AS sibling_num

FROM CDRCase a
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN AgeSiblings d ON a.ID = d.CaseID
LEFT JOIN Siblings s ON a.ID = s.CaseID
LEFT JOIN Carers c ON a.ID = c.CaseID
LEFT JOIN Relationship r ON c.RelationshipID = r.ID
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
WHERE r.ItemText IN ('Brother', 'Sister', 'Half sibling') AND ((StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "Age (years)" < 18) OR StatusAtEvent.ItemText = 'seriously injured')
GROUP BY a.CaseNumber, c.GivenNames, c.Surname, FORMAT(c.DateOfBirth, 'dd/MM/yyyy'), r.ItemText;
