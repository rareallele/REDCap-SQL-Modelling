SELECT a.CaseNumber AS case_number, 
	
		-- Screening status
		CASE
			WHEN DATEPART(yyyy, d.DateOfDeath) >= 2017 THEN --Recent cases (2017 and later)
				 CASE
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' AND c.ItemText IS NULL THEN '1' --Awaiting action
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' AND c.ItemText IS NOT NULL THEN '5' --Screened (newer cases screened but not updated - to be checked manually)
					WHEN css."Description" = 'Committee request more info prior to review decisi' THEN '5' --Screened, awaiting review decision
					WHEN css."Description" = 'Under review' THEN '5' --Under review
					WHEN css."Description" = 'Waiting outcome of SAPOL/coronial investigations' OR css."Description" = 'Waiting review ' THEN '5' --Pending review
					ELSE '6' --Complete
				END
			WHEN DATEPART(yyyy, d.DateOfDeath) < 2017 OR StatusAtEvent.ItemText = 'seriously injured' THEN --Older cases (pre-2017) and serious injuries
	   			CASE
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' AND c.ItemText IS NULL THEN '1' --Awaiting action
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' AND c.ItemText IS NOT NULL THEN '6' --Complete (old cases screened [having a COD] are marked as complete here)
					WHEN css."Description" = 'Committee request more info prior to review decisi' THEN '6' --Complete (old cases switched to complete as they should be)
					WHEN css."Description" = 'Under review' THEN '6' --Complete (old cases 'Under review' will have been completed)
					WHEN css."Description" = 'Waiting outcome of SAPOL/coronial investigations' OR css."Description" = 'Waiting review ' THEN '6' --Screened ('Pending review')
					ELSE '6' --Complete
				END
			ELSE ''
		END AS "screening_status", 


		-- Review status
		CASE
			WHEN DATEPART(yyyy, d.DateOfDeath) >= 2017 THEN --Recent cases (2017 and later)
				CASE
					WHEN css."Description" = 'Committee request more info prior to review decisi'
						 OR css."Description" = 'Coronial inquiry complete; recommendations made'
						 OR css."Description" = 'Waiting outcome of SAPOL/coronial investigations'
						 OR css."Description" = 'Waiting review ' THEN '1' --Pending
					WHEN css."Description" = 'Group review limited to consideration of specific '
						 OR css."Description" = 'Partial review completed: may be recommendations'
						 OR css."Description" = 'Screened, not for in-depth review ' THEN '2' --Not for in-depth review
					WHEN css."Description" = 'Under review' THEN '3' --Under review
					WHEN css."Description" = 'Full in-depth review; complete; recommendations im'
						 OR css."Description" = 'Recommendations being monitored'
						 OR css."Description" = 'Review/recommendations with Minister' THEN '4' --Review complete
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' THEN '1' --Pending
					ELSE ''
				END
			WHEN DATEPART(yyyy, d.DateOfDeath) < 2017 OR StatusAtEvent.ItemText = 'seriously injured' THEN --Older cases (pre-2017) and serious injuries
				CASE
					WHEN css."Description" = 'Committee request more info prior to review decisi'
						 OR css."Description" = 'Coronial inquiry complete; recommendations made'
						 OR css."Description" = 'Waiting outcome of SAPOL/coronial investigations'
						 OR css."Description" = 'Waiting review '
						 OR css."Description" = 'Group review limited to consideration of specific '
						 OR css."Description" = 'Partial review completed: may be recommendations'
						 OR css."Description" = 'Screened, not for in-depth review ' THEN '2' --Not for in-depth review (cases of this age should have a decision re review)
					WHEN css."Description" = 'Under review' THEN '4' --Reviewed cases of this age will be complete
					WHEN css."Description" = 'Full in-depth review; complete; recommendations im'
						 OR css."Description" = 'Recommendations being monitored'
						 OR css."Description" = 'Review/recommendations with Minister' THEN '4' --Review complete
					WHEN css."Description" = 'Information entered, waiting CIS/coroner records' AND c.ItemText IS NOT NULL THEN '4' --Cases with a COD have been screeened and completed; a review decision should have been made
					ELSE ''
				END
			ELSE ''
		END AS "review_status",

		-- Coronial
		CASE
			WHEN StatusAtEvent.ItemText = 'seriously injured' THEN '' --Injuries
			WHEN Investigations.CoronialItemsExist IS NULL AND StatusAtEvent.ItemText = 'deceased' THEN 0
			ELSE Investigations.CoronialItemsExist
		END AS "coronial",

		-- Category of death
		CASE 
			WHEN StatusAtEvent.ItemText = 'seriously injured' THEN '' --Injuries
			WHEN c.ItemText IS NULL AND StatusAtEvent.ItemText = 'deceased' THEN '0'
			WHEN c.ItemText = 'pending' THEN '0'
			WHEN c.ItemText = 'natural' THEN '1'
			WHEN c.ItemText = 'transport-related' THEN '2'
			WHEN c.ItemText = 'accidental' OR c.ItemText = 'accident' THEN '3'
			WHEN c.ItemText = 'suicide' THEN '4'
			WHEN c.ItemText = 'fatal assault' THEN '5'
			WHEN c.ItemText = 'neglect' THEN '6'
			WHEN c.ItemText = 'medical' THEN '7'
			WHEN c.ItemText = 'SIDS' THEN '8'
			WHEN c.ItemText = 'fire-related' THEN '9'
			WHEN c.ItemText = 'drowning' THEN '10'
			WHEN c.ItemText = 'undetermined' OR c.ItemText = 'unascertained' THEN '11'
		END AS category_of_death,

		--SUDI
		CASE
			WHEN circ.SUDI IS NULL THEN ''
			ELSE CAST(circ.SUDI AS varchar)
		END AS sudi


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
LEFT JOIN ContactHistory cp
ON a.ID = cp.CaseID
LEFT JOIN Residence res
ON a.ID = res.CaseID 
LEFT JOIN CulturalBackground cb 
ON res.CulturalBackgroundID = cb.ID
LEFT JOIN AddressStatus 
ON res.AddressStatusID = AddressStatus.ID
LEFT JOIN CommSystemStatus css
ON a.CommSystemStatusID = css.ID
LEFT JOIN Investigations
ON a.ID = Investigations.CaseID

WHERE ((StatusAtEvent.ItemText = 'deceased' AND DATEPART(yyyy, d.DateOfDeath) >= 2005 AND "age_years" < 18) OR (StatusAtEvent.ItemText = 'seriously injured'))

ORDER BY "case_number"
;