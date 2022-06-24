SELECT 
	a.CaseNumber AS "case_number",

	CASE WHEN cc.PersonsName = '** New **' THEN '' ELSE cc.PersonsName END AS "subject_name", 
	FORMAT(cc.DateOfBirth, 'dd/MM/yyyy') AS "subject_dob", 
	cc.Relationship AS "subject_relationship", 
	cc.Charge AS "subject_charge", cc.Outcome AS "subject_outcome", 
	FORMAT(cc.DateOfOutcome, 'dd/MM/yyyy') AS "date_of_subj_outcome",

	-- Count each case's siblings
	ROW_NUMBER() OVER (
		PARTITION BY a.CaseNumber, cc.Relationship
		ORDER BY a.CaseNumber) AS subject_num

FROM CDRCase a
LEFT JOIN Investigations inv ON a.ID = inv.CaseID
LEFT JOIN CriminalCharges cc ON inv.CaseID = cc.CaseID
LEFT JOIN Carers c ON a.ID = c.CaseID
LEFT JOIN Relationship r ON c.RelationshipID = r.ID
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN AgeSiblings d ON a.ID = d.CaseID
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
WHERE (cc.Outcome IS NOT NULL AND cc.Outcome != 'NULL') AND ((StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "Age (years)" < 18) OR StatusAtEvent.ItemText = 'seriously injured')
GROUP BY a.CaseNumber, cc.PersonsName, cc.DateOfBirth, cc.Relationship, cc.Charge, cc.Outcome, FORMAT(cc.DateOfOutcome, 'dd/MM/yyyy');
