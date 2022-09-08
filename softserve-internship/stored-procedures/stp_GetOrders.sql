CREATE OR ALTER PROCEDURE dbo.stp_GetOrders
@ID int, 
@Debug bit = 0
AS 
BEGIN

SET NOCOUNT ON

BEGIN TRY

    if @ID is null
        SELECT * FROM dbo.Orders
    ELSE
        SELECT * FROM dbo.Orders
        WHERE ID = @ID

   if @Debug = 1
    BEGIN
        RAISERROR('Something went wrong!', 16, 1)
        RETURN
    END

END TRY

BEGIN CATCH
    THROW;
END CATCH

END;

EXEC dbo.stp_GetOrders NULL