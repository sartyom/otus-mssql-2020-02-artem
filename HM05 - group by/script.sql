DECLARE @MonthList TABLE
(
	Month INT PRIMARY KEY
)

INSERT INTO @MonthList( Month ) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)

--Опционально: Написать все эти же запросы, но, если за какой-то месяц не было продаж, то этот месяц тоже должен быть в результате и там должны быть нули.
--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам

SELECT
	DATEPART( yyyy, O.OrderDate ) AS Year,
	DATEPART( MM, O.OrderDate ) AS Month,
	AVG( OL.UnitPrice ) AS AverageUnitPrice,
	SUM( OL.Quantity * OL.UnitPrice ) AS MonthTotal
FROM Sales.Orders O
INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
GROUP BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate )
ORDER BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate )

;WITH OrderDataCTE( Year, Month, AverageUnitPrice, MonthTotal ) AS
(
	SELECT
		DATEPART( yyyy, O.OrderDate ) AS Year,
		DATEPART( MM, O.OrderDate ) AS Month,
		AVG( OL.UnitPrice ) AS AverageUnitPrice,
		SUM( OL.Quantity * OL.UnitPrice ) AS MonthTotal
	FROM Sales.Orders O
	INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
	GROUP BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate )
),
YearMonthCTE( Year, Month ) AS
(
	SELECT DISTINCT OD.Year, ML.Month
	FROM OrderDataCTE OD
	CROSS JOIN @MonthList ML
)
SELECT
	YM.Year,
	YM.Month,
	ISNULL( OD.AverageUnitPrice, 0 ) AS AverageUnitPrice,
	ISNULL( OD.MonthTotal, 0 ) AS MonthTotal
FROM YearMonthCTE YM
LEFT JOIN OrderDataCTE OD ON ( ( YM.Year = OD.Year ) AND ( YM.Month = OD.Month ) )
ORDER BY YM.Year, YM.Month

;WITH OrderDataCTE2( Year, Month, AverageUnitPrice, MonthTotal ) AS
(
	SELECT
		DATEPART( yyyy, O.OrderDate ) AS Year,
		DATEPART( MM, O.OrderDate ) AS Month,
		AVG( OL.UnitPrice ) AS AverageUnitPrice,
		SUM( OL.Quantity * OL.UnitPrice ) AS MonthTotal
	FROM Sales.Orders O
	INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
	GROUP BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate )
),
MaxMonthCTE( Year, Month ) AS
(
	SELECT
		Year,
		MAX( Month )
	FROM OrderDataCTE2
	GROUP BY Year
),
FullOrderDataCTE( Year, Month, AverageUnitPrice, MonthTotal ) AS
(
	SELECT
		Year,
		Month,
		AverageUnitPrice,
		MonthTotal
	FROM OrderDataCTE2 O

	UNION ALL

	SELECT
		O.Year,
		O.Month,
		0 AS AverageUnitPrice,
		0 AS MonthTotal
	FROM FullOrderDataCTE O
	INNER JOIN MaxMonthCTE MM ON ( O.Year = MM.Year )
	WHERE (  )

)


SELECT
	OD.Year,
	OD.Month,
	OD.AverageUnitPrice,
	OD.MonthTotal
FROM OrderDataCTE2 OD
ORDER BY OD.Year, OD.Month

--2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

SELECT
	YEAR( O.OrderDate ) AS Year,
	MONTH( O.OrderDate ) AS Month,
	SUM( OL.Quantity * OL.UnitPrice ) AS MonthTotal
FROM Sales.Orders O
INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
GROUP BY YEAR( O.OrderDate ), MONTH( O.OrderDate )
HAVING ( SUM( OL.Quantity * OL.UnitPrice ) > 10000 )
ORDER BY YEAR( O.OrderDate ), MONTH( O.OrderDate )

;WITH OrderDataCTE( Year, Month, MonthTotal ) AS
(
	SELECT
		YEAR( O.OrderDate ) AS Year,
		MONTH( O.OrderDate ) AS Month,
		SUM( OL.Quantity * OL.UnitPrice ) AS MonthTotal
	FROM Sales.Orders O
	INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
	GROUP BY YEAR( O.OrderDate ), MONTH( O.OrderDate )
	HAVING ( SUM( OL.Quantity * OL.UnitPrice ) > 10000 )
),
YearMonthCTE( Year, Month ) AS
(
	SELECT DISTINCT OD.Year, ML.Month
	FROM OrderDataCTE OD
	CROSS JOIN @MonthList ML
)
SELECT
	YM.Year,
	YM.Month,
	ISNULL( OD.MonthTotal, 0 ) AS MonthTotal
FROM YearMonthCTE YM
LEFT JOIN OrderDataCTE OD ON ( ( YM.Year = OD.Year ) AND ( YM.Month = OD.Month ) )
ORDER BY YM.Year, YM.Month

--3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.
--Группировка должна быть по году и месяцу.

SELECT
	DATEPART( yyyy, O.OrderDate ) AS Year,
	DATEPART( MM, O.OrderDate ) AS Month,
	OL.StockItemID,
	SUM( OL.Quantity * OL.UnitPrice ) AS PriceTotal,
	MIN( O.OrderDate ) AS FirstSalesDate,
	SUM( OL.Quantity ) AS QuantityTotal
FROM Sales.Orders O
INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
GROUP BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate ), OL.StockItemID
HAVING ( SUM( OL.Quantity ) < 50 )
ORDER BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate )

;WITH OrderDataCTE( Year, Month, StockItemID, PriceTotal, FirstSalesDate, QuantityTotal ) AS
(
	SELECT
		DATEPART( yyyy, O.OrderDate ) AS Year,
		DATEPART( MM, O.OrderDate ) AS Month,
		OL.StockItemID,
		SUM( OL.Quantity * OL.UnitPrice ) AS PriceTotal,
		MIN( O.OrderDate ) AS FirstSalesDate,
		SUM( OL.Quantity ) AS QuantityTotal
	FROM Sales.Orders O
	INNER JOIN Sales.OrderLines OL ON ( O.OrderID = OL.OrderID )
	GROUP BY DATEPART( yyyy, O.OrderDate ), DATEPART( MM, O.OrderDate ), OL.StockItemID
	HAVING ( SUM( OL.Quantity ) < 50 )
),
YearMonthCTE( Year, Month ) AS
(
	SELECT DISTINCT OD.Year, ML.Month
	FROM OrderDataCTE OD
	CROSS JOIN @MonthList ML
)
SELECT
	YM.Year,
	YM.Month,
	OD.StockItemID,
	ISNULL( OD.PriceTotal, 0 ) AS PriceTotal,
	OD.FirstSalesDate,
	ISNULL( OD.QuantityTotal, 0 ) AS QuantityTotal
FROM YearMonthCTE YM
LEFT JOIN OrderDataCTE OD ON ( ( YM.Year = OD.Year ) AND ( YM.Month = OD.Month ) )
ORDER BY YM.Year, YM.Month

--4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
/*Результат вывода рекурсивного CTE:
EmployeeID Name Title EmployeeLevel
1   Ken Sánchez Chief Executive Officer            1
273 | Brian Welcker Vice President of Sales        2
16  | | David Bradley Marketing Manager            3
23  | | | Mary Gibson Marketing Specialist         4
274 | | Stephen Jiang North American Sales Manager 3
276 | | | Linda Mitchell Sales Representative      4
275 | | | Michael Blythe Sales Representative      4
285 | | Syed Abbas Pacific Sales Manager           3
286 | | | Lynn Tsoflias Sales Representative       4*/

DROP TABLE IF EXISTS dbo.MyEmployees

CREATE TABLE dbo.MyEmployees
(
	EmployeeID smallint NOT NULL,
	FirstName nvarchar(30) NOT NULL,
	LastName nvarchar(40) NOT NULL,
	Title nvarchar(50) NOT NULL,
	DeptID smallint NOT NULL,
	ManagerID int NULL,
	CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED ( EmployeeID ASC )
);

INSERT INTO dbo.MyEmployees VALUES
( 1, N'Ken', N'Sánchez', N'Chief Executive Officer', 16, NULL ),
( 273, N'Brian', N'Welcker', N'Vice President of Sales', 3, 1 ),
( 274, N'Stephen', N'Jiang', N'North American Sales Manager', 3, 273 ),
( 275, N'Michael', N'Blythe', N'Sales Representative', 3, 274 ),
( 276, N'Linda', N'Mitchell', N'Sales Representative', 3, 274 ),
( 285, N'Syed', N'Abbas', N'Pacific Sales Manager', 3, 273 ),
( 286, N'Lynn', N'Tsoflias', N'Sales Representative', 3, 285 ),
( 16, N'David',N'Bradley', N'Marketing Manager', 4, 273 ),
( 23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16 );

DROP TABLE IF EXISTS #TmpEmployees
CREATE TABLE #TmpEmployees
(
	EmployeeID INT, 
	Name NVARCHAR( 100 ),
	Title NVARCHAR( 50 ),
	EmployeeLevel INT
)

DECLARE @VariableEmployees TABLE
(
	EmployeeID INT, 
	Name NVARCHAR( 100 ),
	Title NVARCHAR( 50 ),
	EmployeeLevel INT
)

;WITH EmployeesCTE( EmployeeID, FirstName, LastName, Title, ManagerID, EmployeeLevel, LevelCode, NamePrefix ) AS
(
	SELECT
		EmployeeID,
		FirstName,
		LastName,
		Title,
		ManagerID,
		1 AS EmployeeLevel,
		CAST( 'Root' AS NVARCHAR( MAX ) )  AS LevelCode,
		CAST( '' AS NVARCHAR( MAX ) ) AS NamePrefix
	FROM MyEmployees
	WHERE ( ManagerID IS NULL )

	UNION ALL

	SELECT
		ME.EmployeeID,
		ME.FirstName,
		ME.LastName,
		ME.Title,
		ME.ManagerID,
		ECTE.EmployeeLevel + 1 AS EmployeeLevel,
		CONCAT( ECTE.LevelCode, '\', ME.FirstName, ' ', ME.LastName, '(', CAST( ME.EmployeeID AS NVARCHAR( MAX ) ) ,')' ) AS LevelCode,
		CONCAT( ECTE.NamePrefix, '| ' ) AS NamePrefix
	FROM MyEmployees ME
	INNER JOIN EmployeesCTE ECTE ON ( ME.ManagerID = ECTE.EmployeeID )
)
INSERT INTO #TmpEmployees( EmployeeID, Name, Title, EmployeeLevel )
SELECT
	EmployeeID,
	CONCAT( NamePrefix, FirstName, ' ', LastName ) AS Name,
	Title,
	EmployeeLevel
FROM EmployeesCTE
ORDER BY LevelCode

INSERT INTO @VariableEmployees( EmployeeID, Name, Title, EmployeeLevel )
SELECT
	EmployeeID,
	Name,
	Title,
	EmployeeLevel
FROM #TmpEmployees

--JUST FOR TEST

SELECT *
FROM #TmpEmployees

SELECT *
FROM @VariableEmployees
