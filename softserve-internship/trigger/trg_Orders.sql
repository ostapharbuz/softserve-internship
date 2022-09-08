CREATE OR ALTER TRIGGER dbo.trg_Orders_After_I
ON dbo.Orders
AFTER INSERT 
AS 
BEGIN 
    if (@@ROWCOUNT = 0)
        RETURN
    DECLARE @OrderID int,
            @EmployeeID int

    SET @OrderID = (SELECT o.ID FROM Orders as o
                    JOIN inserted as i
                    ON o.ID = i.ID
                    )

    SET @EmployeeID = (SELECT es.EmployeeID FROM inserted AS i
                      JOIN EmployeeStores AS es
                      ON i.EmployeeStoreID = es.ID
                      JOIN Employees AS e
                      ON es.EmployeeID = e.ID
                      )

    INSERT INTO dbo.EmployeeReports 
    SELECT 'Employee with ID = ' + CAST(@EmployeeID as varchar(4)) + ' confirmed an order with ID = ' + CAST(@OrderID as varchar(4))
END

if OBJECT_ID ('dbo.EmployeeReports') is null 
    CREATE TABLE dbo.EmployeeReports (
        ID int IDENTITY not null,
        Report varchar (100)
    )