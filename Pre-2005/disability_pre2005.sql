SELECT a.CaseNumber AS "case_number",

 MAX(CASE WHEN cct.ItemText = 'Disability Register 11' THEN 2 ELSE 1 END) AS "disability_register",

 MAX(CASE WHEN "age_years" < 1 AND cct.ItemText = 'Disability Register 11' THEN 1 ELSE 0 END) AS "disability_categories___1", --Infant with disability

 MAX(CASE WHEN cct.ItemText = '12 Neurodegen, genetic, birth defect 12' THEN 1 ELSE 0 END) AS "disability_categories___2", --Neurodegenerative

 MAX(CASE WHEN cct.ItemText = '13 Cerebral palsy 13' THEN 1 ELSE 0 END) AS "disability_categories___3", --Cerebral palsy

 MAX(CASE WHEN cct.ItemText = '14 Epilepsy 14' THEN 1 ELSE 0 END) AS "disability_categories___4", --Epilepsy

 MAX(CASE WHEN cct.ItemText = '15 Heart and circ 15' THEN 1 ELSE 0 END) AS "disability_categories___5", --Heart and circulatory

 MAX(CASE WHEN cct.ItemText = '16 Intellectual disability (primary) 16' THEN 1 ELSE 0 END) AS "disability_categories___6", --Intellectual disability

 MAX(CASE WHEN cct.ItemText = '18 Autism 18' THEN 1 ELSE 0 END) AS "disability_categories___7", --Autism
 

 MAX(CASE WHEN cct.ItemText = '17 Other disability 17' THEN 1 ELSE 0 END) AS "disability_categories___9" --Other disability


FROM CDRCase a
LEFT JOIN Circumstances circ
ON a.ID = circ.CaseID
LEFT JOIN ICD10Causes icd
ON circ.CaseID = icd.CaseID
LEFT JOIN CauseCodeType cct
ON icd.CauseCodeTypeID = cct.ID
LEFT JOIN StatusAtEvent 
ON a.StatusAtEventID = StatusAtEvent.ID
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
WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) < 2005 AND "age_years" < 18)
GROUP BY a.CaseNumber
;
