SELECT  a.CaseNumber AS case_number

	,MAX(CYFS.ItemText) AS cp_category	

FROM CDRCase a
LEFT JOIN ContactHistory cp ON a.ID = cp.CaseID
LEFT JOIN AECReferral ae ON cp.AECReferralID = ae.ID
LEFT JOIN CaseCYFS ON cp.CaseID = CaseCYFS.CaseID
LEFT JOIN CYFS ON CaseCYFS.CYFSID = CYFS.ID
LEFT JOIN CYFSCategory ON CYFS.CYFSCategoryID = CYFSCategory.ID
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN AgeSiblings d ON a.ID = d.CaseID
OUTER APPLY 
	(
	SELECT 
	DATEDIFF(year, DateOfBirth, DateOfDeath) -
		CASE
			WHEN DATEADD(year, DATEDIFF(year, DateOfBirth, DateOfDeath), DateOfBirth)
				> DateOfDeath THEN 1
			ELSE 0
		END AS "age_years",
	DATEDIFF(month, DateOfBirth, DateOfDeath) -
		CASE
			WHEN DATEADD(month, DATEDIFF(month, DateOfBirth, DateOfDeath), DateOfBirth)
				> DateOfDeath THEN 1
			ELSE 0
		END AS "age_months",
	DATEDIFF(day, DateOfBirth, DateOfDeath) -
		CASE
			WHEN DATEADD(day, DATEDIFF(day, DateOfBirth, DateOfDeath), DateOfBirth)
				> DateOfDeath THEN 1
			ELSE 0
		END AS "age_days") 
		AS age
WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18) OR (StatusAtEvent.ItemText = 'seriously injured') 
GROUP BY a.CaseNumber
ORDER BY a.CaseNumber