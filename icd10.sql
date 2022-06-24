SELECT a.CaseNumber AS "case_number",
	
	MAX(circ.ICD10_CauseCodeID) AS icd_10_chapter,
	MAX(icdcc.ItemText) AS "icd_10_chapter_description",

	MAX(CASE WHEN cct.ItemText = 'Underlying COD' THEN icd.CauseCode END) AS "underlying_cod",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1a - 1' THEN icd.CauseCode END) AS "mcod_1a_1",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1a - 2' THEN icd.CauseCode END) AS "mcod_1a_2",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1a - 3' THEN icd.CauseCode END) AS "mcod_1a_3",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1b - 1' THEN icd.CauseCode END) AS "mcod_1b_1",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1b - 2' THEN icd.CauseCode END) AS "mcod_1b_2",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1b - 3' THEN icd.CauseCode END) AS "mcod_1b_3",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1c - 1' THEN icd.CauseCode END) AS "mcod_1c",
	MAX(CASE WHEN cct.ItemText = 'Main COD 1d' THEN icd.CauseCode END) AS "mcod_1d",
	MAX(CASE WHEN cct.ItemText = 'Main COD 2' THEN icd.CauseCode END) AS "mcod_2",
	MAX(CASE WHEN cct.ItemText = 'Main fetal condition' THEN icd.CauseCode END) AS "main_fetal_condition_1",
	MIN(CASE WHEN cct.ItemText = 'Main fetal condition' THEN icd.CauseCode END) AS "main_fetal_condition_2",
	MAX(CASE WHEN cct.ItemText = 'Other fetal conditions - 1' THEN icd.CauseCode END) AS "other_fetal_conditions_1",
	MAX(CASE WHEN cct.ItemText = 'Other fetal conditions - 2' THEN icd.CauseCode END) AS "other_fetal_conditions_2",
	MAX(CASE WHEN cct.ItemText = 'Main maternal condition' THEN icd.CauseCode END) AS "main_maternal_condition",
	MAX(CASE WHEN cct.ItemText = 'Other maternal conditions - 1' THEN icd.CauseCode END) AS "other_maternal_conditions_1",
	MAX(CASE WHEN cct.ItemText = 'Other maternal conditions - 2' THEN icd.CauseCode END) AS "other_maternal_conditions_2",
	MAX(CASE WHEN cct.ItemText = 'Other relevant circumstances' THEN icd.CauseCode END) AS "other_rel_circumstances",
	MAX(CASE WHEN cct.ItemText = 'Activity code' THEN icd.CauseCode END) AS "activity_code",
	MAX(CASE WHEN cct.ItemText = 'Place of occurrence code' THEN icd.CauseCode END) AS "place_code"

FROM CDRCase a
LEFT JOIN Circumstances circ
ON a.ID = circ.CaseID
LEFT JOIN ICD10Causes icd
ON circ.CaseID = icd.CaseID
LEFT JOIN CauseCodeType cct
ON icd.CauseCodeTypeID = cct.ID
LEFT JOIN ICD10CauseCode icdcc
ON circ.ICD10_CauseCodeID = icdcc.ID
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
WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18)
GROUP BY a.CaseNumber
;