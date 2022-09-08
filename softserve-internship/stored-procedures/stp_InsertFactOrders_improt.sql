CREATE OR ALTER PROCEDURE dbo.stp_InsertFactOrder_improt
AS
BEGIN TRY

	DROP TABLE IF EXISTS dbo.FactOrders_import
	IF OBJECT_ID('dbo.FactOrders_import') IS NULL
		CREATE TABLE dbo.FactOrders_import (
			ID int identity not null,
			OrderID int,
			DateID int,
			CustomerID int,
			EmployeeID int,
			StoreID int,
			ProductID int,
			Quantity int,
			PricePerOne decimal (11,2),
			TotalSum decimal (11,2),
			DiscountPrice decimal (11,2)

			CONSTRAINT PK_FactOrders_import PRIMARY KEY (ID)
		);
		
	INSERT INTO dbo.FactOrders_import (OrderID, DateID, CustomerID, EmployeeID, StoreID,
										ProductID, Quantity, PricePerOne, TotalSum, DiscountPrice)
	SELECT  o.ID AS OrderID, dc.ID AS DateID, o.CustomerID, es.EmployeeID, es.StoreID,
			od.ProductID, od.Quantity, od.PricePerOne, o.TotalSum, o.DiscountPrice 
	FROM dbo.Orders AS o
	JOIN EmployeeStores AS es
	ON o.EmployeeStoreID = es.ID
	JOIN OrderDetails AS od
	ON o.ID = od.OrderID
	JOIN DW_AppleStore.dbo.Dim_Calendar AS dc
	ON dc.Date = CAST(o.DateTimeOfSale AS date)

END TRY
BEGIN CATCH
		
	SELECT 
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_MESSAGE() AS ErrorMessage,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_LINE() AS ErrorLine

END CATCH