SELECT  a.CaseNumber AS case_number,

		MAX(CASE 
			WHEN cp.FSAContact IS NULL THEN ''
			WHEN cp.FSAContact = 0 THEN '1' --None
			WHEN cp.FSAContact = 1 THEN '3' --In scope
		END) AS "cp_history",

		MAX(CASE
			WHEN cp.ContactHistorySummary IS NULL THEN ''
			WHEN cp.FSAContact = 0 THEN ''
			ELSE cp.ContactHistorySummary
		END) AS "cp_summary",

		MAX(CASE
			WHEN cp.FSAContact = 0 AND LTRIM(UPPER(cp.ContactHistorySummary)) NOT LIKE 'NO MATCH%' THEN cp.ContactHistorySummary
			ELSE ''
		END) AS "child_protection_notes",
		
		--Internal review
		MAX(CASE 
			WHEN cp.FSAContact = 1 THEN
				CASE 
					WHEN ae.ItemText = 'Not a CYFS case' THEN '0' --Unknown (this is the default category in CDR)
					WHEN ae.ItemText = 'Not referred to AEC' THEN '0' --Unknown (technically we don't know; they could end up being referred)
					WHEN ae.ItemText = 'Listed for review' THEN '2' --Referred for review
					WHEN ae.ItemText = 'Decision pending' THEN '2' --Referred for review (unsure if will undergo review; could be rejected)
					WHEN ae.ItemText = 'Referred - not reviewed' THEN '3' --Rejected
					WHEN ae.ItemText = 'Reviewed' THEN '4' --Reviewed
					WHEN ae.ItemText = 'Report received' THEN '6' --Review received
				END
			ELSE ''
		END) AS internal_cp_review,

		--GOM
		MAX(CASE WHEN CYFS.ItemText = 'GOM' OR ei.ItemText = 'GOM/VCA for child or siblings' THEN 1 ELSE 0 END) AS "gom_status_cdr",
		--Criminal activity
		MAX(CASE WHEN ii.ItemText = 'Criminal activities' THEN 1 ELSE 0 END) AS "youth_justice_contact",
		MAX(CASE WHEN ei.ItemText = 'Carers involved in criminal activity' THEN 1 ELSE 0 END) AS "criminal_activity_family",
		--Drugs and alcohol
		MAX(CASE WHEN ii.ItemText = 'Drug/alcohol issues' THEN 1 ELSE 0 END) AS "drugs_alcohol_child",
		MAX(CASE WHEN ei.ItemText = 'Drug, alcohol life-style' OR ii.ItemText = 'Child born substance dependent' THEN 1 ELSE 0 END) AS "drugs_alcohol_family",
		--Family and living circumstances
		MAX(CASE WHEN ei.ItemText = 'Domestic violence issues' THEN 1 ELSE 0 END) AS "domestic_family_violence",
		MAX(CASE WHEN ei.ItemText = 'Homelessness, accomodation difficulties' THEN 1 ELSE 0 END) AS "housing_insecurity",
		--Abuse/neglect
		MAX(CASE WHEN ii.ItemText = 'Incidents of abuse/neglect' THEN 1 ELSE 0 END) AS "cdr_abuse_neglect",
		--Carers
		MAX(CASE WHEN ei.ItemText = 'Carers unable to meet child''s special needs' THEN 1 ELSE 0 END) AS "carers_capacity",
		MAX(CASE WHEN ei.ItemText = 'Carers'' history of mental, physical, intellectual,' THEN 1 ELSE 0 END) AS "carers_disability"		


FROM CDRCase a
LEFT JOIN ContactHistory cp ON a.ID = cp.CaseID
LEFT JOIN AECReferral ae ON cp.AECReferralID = ae.ID
LEFT JOIN CaseCYFS ON cp.CaseID = CaseCYFS.CaseID
LEFT JOIN CYFS ON CaseCYFS.CYFSID = CYFS.ID
LEFT JOIN CYFSCategory ON CYFS.CYFSCategoryID = CYFSCategory.ID
LEFT JOIN IntFactors intf  ON a.ID = intf.CaseID
LEFT JOIN IntFactorsIssues ifi ON intf.CaseID = ifi.CaseID
LEFT JOIN IntIssues ii ON ifi.IntIssuesID = ii.ID
LEFT JOIN ExtFactors e ON a.ID = e.CaseID
LEFT JOIN ExtFactorsIssues efi ON e.CaseID = efi.CaseID
LEFT JOIN ExtIssues ei ON efi.ExtIssuesID = ei.ID
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