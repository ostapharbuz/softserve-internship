CREATE OR ALTER PROCEDURE dbo.stp_AddNewOrder 
@EmployeeStoreID int,  -- SOME VARIABLES TO INPUT
@CustomerID int,
@DeliveryTypeID tinyint,
@DeliveryAdress varchar(100),
@GuaranteeID tinyint,
@ProductID varchar(50),
@Debug bit = 0
AS
BEGIN TRY

    BEGIN TRANSACTION

        SET NOCOUNT ON

        -- SOME ERROR CHECKS FOR STORED PROCEDURE EXECUTING PARAMETERS BY USING A FUNCTION

        DECLARE @MSG nvarchar(512),
				@Text nvarchar(50),
				@Format nvarchar(150)
			
        IF NOT EXISTS (SELECT EmployeeStoresID FROM dbo.vw_EmployeesWhoSell
                       WHERE EmployeeStoresID = @EmployeeStoreID)
			    SET @MSG = dbo.fn_GetErrorMessagesByID (28)

        IF NOT EXISTS (SELECT ID FROM dbo.Customers
                       WHERE ID = @CustomerID)
            BEGIN 
                SET @text = 'CustomerID like this!'
			    SET @MSG = dbo.fn_GetErrorMessagesByID (4)
				SET @Format = FORMATMESSAGE(@MSG, @Text)
            END

        IF NOT EXISTS (SELECT ID FROM dbo.DeliveryTypes
                       WHERE ID = @DeliveryTypeID)
            BEGIN 
                SET @text = 'DeliveryTypeID like this!'
			    SET @MSG = dbo.fn_GetErrorMessagesByID (4)
				SET @Format = FORMATMESSAGE(@MSG, @Text)
            END

        IF NOT EXISTS (SELECT ID FROM dbo.Guarantees
                       WHERE ID = @GuaranteeID)
            BEGIN 
                SET @text = 'GuaranteeID like this!'
			    SET @MSG = dbo.fn_GetErrorMessagesByID (4)
				SET @Format = FORMATMESSAGE(@MSG, @Text)
            END

        IF @Debug = 1
            SELECT @MSG = dbo.fn_GetErrorMessagesByID (18)

        IF @Format IS NOT NULL
            BEGIN
                RAISERROR(@Format, 16, 1)
                RETURN
            END

		IF @MSG IS NOT NULL
            BEGIN
                RAISERROR(@MSG, 16, 1)
                RETURN
            END

        DECLARE @DateTimeOfSale datetime,
                @EndDayGuaratee datetime,
                @TotalSum decimal(10,2),
                @DiscountPrice decimal(10,2),
                @BonusDetailsID int,
                @LastCustomerID int,
                @Percent decimal(10,2),
                @Limit decimal(7,2)

        -- DATE AND TIME OF SALE

        SET @DateTimeOfSale = GETDATE()

        -- CALCULATING THE LAST DAY OF GUARANTEE BY USING SCALAR VALUED FUNCTION dbo.fn_EndDayGuaratee

        SET @EndDayGuaratee = (SELECT dbo.fn_EndDayGuaratee (@GuaranteeID))

        INSERT INTO dbo.Orders (EmployeeStoreID, CustomerID, DateTimeOfSale, DeliveryTypeID, DeliveryAddress, 
                                GuaranteeID, EndDayGuarantee, TotalSum, DiscountPrice)
                        VALUES (@EmployeeStoreID, @CustomerID, @DateTimeOfSale, @DeliveryTypeID, @DeliveryAdress,
                                @GuaranteeID, @EndDayGuaratee, @TotalSum, @DiscountPrice)


        -- SCRIPT FOR TABLE dbo.OrderDetails

        DECLARE @PricePerOne decimal(11,2),
                @PriceW decimal(11,2),
                @OrderID int,
                @Quantity int = 1,
                @TaxPercent decimal(7,2)

        SET @OrderID = (SELECT IDENT_CURRENT('dbo.Orders'))

        -- CALCULATE TaxPercent FROM TABLE SaleInfos

        SET @TaxPercent = (SELECT ([Value]/100.0 + 1) AS [Value] FROM dbo.SaleInfos
                        WHERE ID = 1)

        -- CREATING LOCAL TEMPORARY TABLE LIKE COPY OF OrderDetails

        DROP TABLE IF EXISTS #GroupOD;
        CREATE TABLE #GroupOD (
            OrderID int,
            ProductID int,
            Quantity int,
            PricePerOne decimal (11,2)
        )

        INSERT INTO #GroupOD (OrderID, PricePerOne, Quantity, ProductID)
        SELECT @OrderID, w.PriceW * @TaxPercent, @Quantity, LTRIM(RTRIM(value)) AS value from string_split(@ProductID, ',') AS v
                                                            JOIN dbo.Warehouses as w
                                                            ON w.ProductID = v.value

        INSERT INTO dbo.OrderDetails (OrderID, PricePerOne, Quantity, ProductID)
        SELECT g.OrderID, g.PricePerOne, COUNT(g.Quantity) AS Quantity, g.ProductID FROM #GroupOD AS g
        GROUP BY g.OrderID, g.ProductID, g.PricePerOne

        -- SUBTRACTION THE NUMBER OF PRODUCTS FROM THE WAREHOUSE

        DECLARE @tempOrderID int = (SELECT IDENT_CURRENT('dbo.Orders'))

        DROP TABLE IF EXISTS #WarehouseQ
        SELECT od.OrderID, od.ProductID, SUM(od.Quantity) AS Quantity
        INTO #WarehouseQ
        FROM dbo.Warehouses as w
        JOIN dbo.Products AS p
        ON w.ProductID = p.ID
        JOIN dbo.OrderDetails AS od
        ON p.ID = od.ProductID
        WHERE w.ProductID = od.ProductID
        GROUP BY od.OrderID, od.ProductID
        HAVING od.OrderID = @tempOrderID

        IF (SELECT MIN(w.Quantity - wq.Quantity) FROM dbo.Warehouses AS w
            JOIN #WarehouseQ AS wq
            ON w.ProductID = wq.ProductID
            WHERE wq.OrderID = @OrderID) >= 0
                BEGIN
                    UPDATE w 
                    SET Quantity = w.Quantity - wq.Quantity 
                    FROM dbo.Warehouses AS w 
                    JOIN #WarehouseQ AS wq
                    ON w.ProductID = wq.ProductID
                    WHERE wq.OrderID = @OrderID
                END
        ELSE
			BEGIN
				RAISERROR ('There are not enough products in stock. Please, check the Warehouse!', 16, 1)
				RETURN
			END

        -- CALCULATING THE TOTAL SUM OF THE PRICE OF ORDER

        SET @TotalSum = (SELECT SUM(PricePerOne * Quantity) AS TotalSum FROM dbo.OrderDetails 
                        GROUP BY OrderID
                        HAVING OrderID = IDENT_CURRENT('dbo.Orders')) 

        -- CALCULATING PRICE WITH DISCOUNT

        SET @LastCustomerID = (SELECT TOP 1 o.CustomerID FROM Orders AS o 
                            WHERE ID = IDENT_CURRENT('dbo.Orders'))  -- select the last inserted CustomerID using the Top 1 statement

        SET @BonusDetailsID = (SELECT TOP 1 bc.BonusDetailsID FROM Orders AS o -- select top 1 BonusDetailID from table BonusDetails
                            JOIN Customers AS c
                            ON o.CustomerID = c.ID
                            JOIN BonusCards AS bc
                            ON c.BonusCardID = bc.ID
                            JOIN BonusDetails AS bd
                            ON bc.BonusDetailsID = bd.ID
                            WHERE o.CustomerID = @LastCustomerID)  

        SET @Percent = (SELECT ([Percent]/100.0) AS [Percent] FROM dbo.BonusDetails  -- calculate the Percent of Discount
                        WHERE @BonusDetailsID = ID)

        SET @Limit = (SELECT [Limit] FROM dbo.BonusDetails                           -- calculate the Limit Price of Discount
                    WHERE @BonusDetailsID = ID)

        SET @DiscountPrice = IIF((@TotalSum * @Percent) > @Limit, @TotalSum - @Limit, @TotalSum - (@TotalSum * @Percent))

        UPDATE dbo.Orders 
        SET TotalSum = @TotalSum,
            DiscountPrice = @DiscountPrice
        WHERE ID = IDENT_CURRENT('dbo.Orders')

    IF @@TRANCOUNT > 0
    COMMIT TRANSACTION

END TRY

BEGIN CATCH
    ROLLBACK TRANSACTION
	SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_STATE() AS ErrorState,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_LINE() AS ErrorLine
END CATCH;