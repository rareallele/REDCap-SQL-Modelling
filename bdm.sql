SELECT  MAX(a.CaseNumber) AS case_number,
		
		MAX(
		CASE
			WHEN Agency.ItemText = 'BDM' THEN LTRIM(RTRIM(oa.InternalCode))
			ELSE ''
		END) AS bdm_id,

		MAX(
		CASE
			WHEN Agency.ItemText = 'BDM' AND oa.InternalCode IS NOT NULL AND ISNUMERIC(SUBSTRING(LTRIM(oa.Comments), 1, 1)) = 1 THEN LTRIM(RTRIM(oa.Comments))
			ELSE ''
		END) AS bdm_date_of_registration
		

FROM CDRCase a
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID

LEFT JOIN OtherAgencies oa ON a.ID = oa.CaseID
LEFT JOIN Agency ON oa.AgencyID = Agency.ID

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

WHERE StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18

GROUP BY a.CaseNumber

ORDER BY "case_number"
;