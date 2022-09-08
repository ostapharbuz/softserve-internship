SELECT * FROM dbo.Guarantees

; with cte_Guarantees as (
    SELECT * 
    FROM (
        VALUES
            (1, 3, 700),
            (2, 6, 1000),
            (3, 12, 1500),
            (4, 18, 2000)
    ) V (ID, MonthTerm, GuaranteePrice)
)

MERGE dbo.Guarantees as tgt
    USING cte_Guarantees as src on src.ID = tgt.ID 
WHEN MATCHED 
    AND tgt.MonthTerm != src.MonthTerm
    AND tgt.GuaranteePrice != src.GuaranteePrice
    THEN UPDATE SET
    MonthTerm = src.MonthTerm,
    GuaranteePrice = src.GuaranteePrice
WHEN NOT MATCHED 
    THEN INSERT (ID, MonthTerm, GuaranteePrice)
        VALUES (src.ID, src.MonthTerm, src.GuaranteePrice);




















; with cte_Guarantees as (
    SELECT *
    FROM (
        VALUES 
            (1, 3, 700)
    ) V (ID, MonthTerm, GuaranteePrice)
) 

MERGE dbo.Guarantees as tgt 
    USING cte_Guarantees as src on src.ID = tgt.ID
WHEN MATCHED 
    AND tgt.MonthTerm != src.MonthTerm
    AND tgt.GuaranteePrice != src.GuaranteePrice
    THEN UPDATE SET
    MonthTerm = src.MonthTerm,
    GuaranteePrice = src.GuaranteePrice
WHEN NOT MATCHED 
    THEN INSERT (ID, MonthTerm, GuaranteePrice)
    VALUES (src.ID, src.MonthTerm, src.GuaranteePrice) ;

