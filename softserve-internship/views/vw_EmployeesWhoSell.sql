CREATE OR ALTER VIEW dbo.vw_EmployeesWhoSell
AS
SELECT es.ID AS EmployeeStoresID, e.FirstName, e.LastName, ep.PhoneNumber, p.Name AS PositionName, c.Name AS City, s.Name AS Store 
FROM dbo.EmployeeStores AS es
JOIN dbo.Employees AS e
ON es.EmployeeID = e.ID
JOIN dbo.Positions AS p
ON e.PositionID = p.ID
JOIN dbo.Departments AS d
ON p.DepartmentID = d.ID
JOIN dbo.EmployeeDetails AS ed
ON e.ID = ed.ID
JOIN dbo.Cities AS c
ON ed.CityID = c.ID
JOIN dbo.EmployeePhones AS ep
ON ed.ID = ep.EmployeeDetailID
JOIN dbo.Stores AS s
ON es.StoreID = s.ID
WHERE d.ID = 5 AND p.ID IN (25, 26, 27, 32)


SELECT * FROM dbo.vw_EmployeesWhoSell