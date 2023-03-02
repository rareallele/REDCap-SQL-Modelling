SELECT  
	a.CaseNumber AS case_number, 
	LinkedCaseID AS linked_case,
	ls.ItemText AS link_status,
	BasisForLink AS basis_for_link


FROM Linkages l LEFT JOIN CDRCase a ON a.ID = l.CaseID
LEFT JOIN LinkedStatus ls ON l.LinkedStatusID = ls.ID

WHERE ls.ItemText = 'Case Linked' AND BasisForLink LIKE '%NFL%'
ORDER BY a.CaseNumber, LinkedCaseID