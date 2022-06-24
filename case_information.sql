SELECT  a.CaseNumber AS case_number, 
		surname, 
		a.GivenNames AS given_names,
		
		CASE
			WHEN Gender.ItemText = 'male' THEN 1
			WHEN Gender.ItemText = 'female' THEN 2
			WHEN Gender.ItemText = 'indeterminate' THEN 3
			WHEN Gender.ItemText = 'uncertain' THEN 0
			ELSE ''		
		END AS sex, 

		CASE
			WHEN StatusAtEvent.ItemText = 'seriously injured' THEN 1
			ELSE 0
		END AS exclude_case,
		CASE
			WHEN StatusAtEvent.ItemText = 'seriously injured' THEN '5'
			ELSE ''
		END AS reason_for_exclusion,

	    res.Address1 AS "address", res.City AS suburb, CAST(res.Postcode AS varchar) as postcode, res."State" AS "state",
		AddressStatus.ItemText AS "residential_status",
	    a.PlaceOfBirth AS "place_of_birth",
	    Causes.PlaceOfEvent AS "place_of_event", Causes.PlaceOfDeath AS "place_of_death",
	    res.LivingArrangements AS living_arrangements,

		CAST(DATEPART(yyyy, d.DateOfDeath) AS varchar) as year_of_death, FORMAT(a.DateOfBirth, 'dd/MM/yyyy') as dob, 
		FORMAT(d.DateOfEvent, 'dd/MM/yyyy') AS date_of_event,
		FORMAT(d.DateOfDeath, 'dd/MM/yyyy') AS dod,

		CASE
			WHEN "age_years" < 18 AND "age_years" > 14 THEN '15 to 17 years'
			WHEN "age_years" < 15 AND "age_years" > 9 THEN '10 to 14 years'
			WHEN "age_years" < 10 AND "age_years" > 4 THEN '5 to 9 years'
			WHEN "age_years" < 5 AND "age_years" >= 1 THEN '1 to 4 years'
			WHEN "age_months" < 12 AND "age_days" >= 28 THEN '1 to 11 months'
			WHEN "age_days" < 28 THEN '< 28 days'
		END AS "age_group",

		CASE
			WHEN Causes.LifeDuration = 0 THEN ''
			ELSE CAST(Causes.LifeDuration AS nvarchar)
		END AS "life_duration_minutes", 

		CASE
			WHEN Causes.Gestation = 0 THEN ''
			ELSE CAST(Causes.Gestation AS nvarchar)
		END AS gestation, 
		CASE
			WHEN Causes.BirthWeight = 0 THEN ''
			ELSE CAST(Causes.BirthWeight AS nvarchar)
		END AS birthweight, 

		CASE
			WHEN cb.ItemText = 'Other' THEN '1'
			WHEN cb.ItemText = 'ATSI' THEN '2'
		END AS "cultural_background"
		

FROM CDRCase a
LEFT JOIN StatusAtEvent ON a.StatusAtEventID = StatusAtEvent.ID
LEFT JOIN Gender ON a.GenderID = Gender.ID
LEFT JOIN Circumstances circ ON a.ID = circ.CaseID
LEFT JOIN CauseOfDeathCategories c ON circ.CauseOfDeathCategoryID = c.ID
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
LEFT JOIN Causes 
ON a.ID = Causes.CaseID
LEFT JOIN ContactHistory cp
ON a.ID = cp.CaseID
LEFT JOIN Residence res
ON a.ID = res.CaseID 
LEFT JOIN CulturalBackground cb 
ON res.CulturalBackgroundID = cb.ID
LEFT JOIN AddressStatus 
ON res.AddressStatusID = AddressStatus.ID

WHERE (StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18) OR (StatusAtEvent.ItemText = 'seriously injured')
ORDER BY a.CaseNumber
;