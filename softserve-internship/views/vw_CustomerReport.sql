CREATE OR ALTER VIEW dbo.vw_CustomerReport
AS
SELECT  o.CustomerID, CONCAT(c.FirstName, ' ', c.LastName) AS FullName, cd.Phone, 
		cd.Email, ct.Name AS City, SUM(o.TotalSum) AS TotalSum, COUNT(o.ID) AS OrdersSum
FROM dbo.Orders AS o
	JOIN dbo.Customers AS c
	ON o.CustomerID = c.ID
	JOIN dbo.CustomerDetails AS cd
	ON c.ID = cd.ID
	JOIN dbo.Cities AS ct
	ON cd.CityID = ct.ID
	GROUP BY o.CustomerID, CONCAT(c.FirstName, ' ', c.LastName), cd.Phone, cd.Email, ct.Name


SELECT * FROM dbo.vw_CustomerReport