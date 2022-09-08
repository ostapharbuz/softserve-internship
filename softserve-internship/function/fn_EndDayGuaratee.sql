CREATE OR ALTER FUNCTION dbo.fn_EndDayGuaratee (@GuaranteeID INT)
RETURNS DATE
AS
BEGIN

	DECLARE 
			@EndDayGuaratee DATE,
			@DateTimeOfSale DATETIME = GETDATE()
			

	SET @EndDayGuaratee = (SELECT
		CASE 
			WHEN @GuaranteeID = 1 THEN DATEADD(MONTH, 3, @DateTimeOfSale)
			WHEN @GuaranteeID = 2 THEN DATEADD(MONTH, 6, @DateTimeOfSale)
			WHEN @GuaranteeID = 3 THEN DATEADD(MONTH, 12, @DateTimeOfSale)
			WHEN @GuaranteeID = 4 THEN DATEADD(MONTH, 18, @DateTimeOfSale)
			WHEN @GuaranteeID = 5 THEN NULL
		END)

	RETURN @EndDayGuaratee

END 