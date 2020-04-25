/*
1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:
Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
Пример
Дата продажи Нарастающий итог по месяцу
2015-01-29 4801725.31
2015-01-30 4801725.31
2015-01-31 4801725.31
2015-02-01 9626342.98
2015-02-02 9626342.98
2015-02-03 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time on;

DECLARE @RunningMonthTotal TABLE
(
	iYear INT,
	iMonth INT,
	dRunningTotal DECIMAL( 18,2 )
)

;WITH MonthTotalCTE( iYear, iMonth, dRunningTotal, dtDate ) AS
(
	SELECT
		YEAR( I.InvoiceDate ) AS Year,
		MONTH( I.InvoiceDate ) AS Month,
		SUM( IL.Quantity * IL.UnitPrice ) AS MonthTotal,
		DATEFROMPARTS( YEAR( I.InvoiceDate ), MONTH( I.InvoiceDate ), 1 )
	FROM Sales.InvoiceLines IL
	INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
	WHERE ( YEAR( I.InvoiceDate ) >= 2015 )
	GROUP BY YEAR( I.InvoiceDate ), MONTH( I.InvoiceDate )
)
INSERT INTO @RunningMonthTotal( iYear, iMonth, dRunningTotal )
SELECT
	MT.iYear,
	MT.iMonth,
	(
		SELECT SUM( MTI.dRunningTotal )
		FROM MonthTotalCTE MTI
		WHERE ( MTI.dtDate <= MT.dtDate )
	)
FROM MonthTotalCTE MT

SELECT
	I.InvoiceDate,
	MT.dRunningTotal
FROM Sales.InvoiceLines IL
INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
INNER JOIN @RunningMonthTotal MT ON ( MT.iYear = YEAR( I.InvoiceDate ) AND ( MT.iMonth = MONTH( I.InvoiceDate ) ) )
WHERE ( YEAR( I.InvoiceDate ) >= 2015 )
ORDER BY I.InvoiceDate

---------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS #RunningMonthTotal

CREATE TABLE #RunningMonthTotal
(
	iYear INT,
	iMonth INT,
	dRunningTotal DECIMAL( 18,2 )
)

;WITH MonthTotalCTE( iYear, iMonth, dMonthTotal, dtDate ) AS
(
	SELECT
		YEAR( I.InvoiceDate ) AS Year,
		MONTH( I.InvoiceDate ) AS Month,
		SUM( IL.Quantity * IL.UnitPrice ) AS MonthTotal,
		DATEFROMPARTS( YEAR( I.InvoiceDate ), MONTH( I.InvoiceDate ), 1 )
	FROM Sales.InvoiceLines IL
	INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
	WHERE ( YEAR( I.InvoiceDate ) >= 2015 )
	GROUP BY YEAR( I.InvoiceDate ), MONTH( I.InvoiceDate )
)
INSERT INTO #RunningMonthTotal( iYear, iMonth, dRunningTotal )
SELECT
	MT.iYear,
	MT.iMonth,
	(
		SELECT SUM( MTI.dMonthTotal )
		FROM MonthTotalCTE MTI
		WHERE ( MTI.dtDate <= MT.dtDate )
	)
FROM MonthTotalCTE MT

SELECT
	I.InvoiceDate,
	MT.dRunningTotal
FROM Sales.InvoiceLines IL
INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
INNER JOIN #RunningMonthTotal MT ON ( MT.iYear = YEAR( I.InvoiceDate ) AND ( MT.iMonth = MONTH( I.InvoiceDate ) ) )
WHERE ( YEAR( I.InvoiceDate ) >= 2015 )
ORDER BY I.InvoiceDate

/*
сделайте расчет суммы нарастающим итогом с помощью оконной функции.
Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;
*/

SELECT
	I.InvoiceDate,
	SUM( IL.Quantity * IL.UnitPrice ) OVER ( ORDER BY DATEFROMPARTS( YEAR( I.InvoiceDate ), MONTH( I.InvoiceDate ), 1 ) ) AS RunningTotal
FROM Sales.InvoiceLines IL
INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
WHERE ( YEAR( I.InvoiceDate ) >= 2015 )
ORDER BY I.InvoiceDate

--Вариант с оконной функцией намного быстрее ~235 мс против ~4100 мс

/*
2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)
*/

;WITH ItemMonthQuantityCTE( StockItemID, Month, TotalQuantity ) AS
(
	SELECT
		IL.StockItemID,
		MONTH( I.InvoiceDate ) AS Month,
		SUM( IL.Quantity ) AS TotalQuantity
	FROM Sales.InvoiceLines IL
	INNER JOIN Sales.Invoices I ON ( I.InvoiceID = IL.InvoiceID )
	WHERE ( YEAR( I.InvoiceDate ) = 2016 )
	GROUP BY IL.StockItemID, MONTH( I.InvoiceDate )
),
ItemMonthQuantityWithPositionCTE( StockItemID, Month, TopPosition, TotalQuantity ) AS
(
	SELECT
		IMQ.StockItemID,
		IMQ.Month,
		ROW_NUMBER() OVER( PARTITION BY IMQ.Month ORDER BY IMQ.TotalQuantity DESC ) AS TopPosition,
		IMQ.TotalQuantity
	FROM ItemMonthQuantityCTE IMQ
)
SELECT
	IMP.Month,
	IMP.StockItemID,
	SI.StockItemName,
	IMP.TotalQuantity
FROM ItemMonthQuantityWithPositionCTE IMP
INNER JOIN Warehouse.StockItems SI ON ( SI.StockItemID = IMP.StockItemID )
WHERE( IMP.TopPosition <= 2 )
ORDER BY IMP.Month

/*
3. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
- пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
- посчитайте общее количество товаров и выведете полем в этом же запросе
- посчитайте общее количество товаров в зависимости от первой буквы названия товара
- отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
- предыдущий ид товара с тем же порядком отображения (по имени)
- названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
*/

SELECT
	StockItemID,
	StockItemName,
	Brand,
	UnitPrice,
	ROW_NUMBER() OVER( PARTITION BY LEFT( StockItemName, 1 ) ORDER BY StockItemID ) AS FirstSymbolRowNumber,
	COUNT(1) OVER() AS TotalItemsCount,
	COUNT(1) OVER( PARTITION BY LEFT( StockItemName, 1 ) ),
	LEAD( StockItemID ) OVER( ORDER BY StockItemName ) AS NextStockItemIdByName,
	LAG( StockItemID ) OVER( ORDER BY StockItemName ) AS PreviousStockItemIdByName,
	LAG( StockItemName, 2, 'No items' ) OVER( ORDER BY StockItemName ) AS Previous2StockItemIdByName,
	NTILE(30) OVER( ORDER BY TypicalWeightPerUnit ) TypicalWeightPerUnitNumber
FROM Warehouse.StockItems
ORDER BY TypicalWeightPerUnitNumber

/*
4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
*/

;WITH SalesInvoiceWithNumberCTE( InvoiceID, CustomerID, SalespersonPersonID, InvoiceDate, SalesPersonInvoiceNumber ) AS
(
	SELECT
		InvoiceID,
		CustomerID,
		SalespersonPersonID,
		InvoiceDate,
		ROW_NUMBER() OVER( PARTITION BY SalespersonPersonID ORDER BY InvoiceDate DESC ) SalesPersonInvoiceNumber
	FROM Sales.Invoices
),
InvoiceTotalCTE( InvoiceID, Total ) AS
(
	SELECT
		I.InvoiceID,
		SUM( IL.Quantity * IL.UnitPrice )
	FROM Sales.Invoices I
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = I.InvoiceID )
	GROUP BY I.InvoiceID
)
SELECT
	SI.InvoiceID,
	SI.CustomerID,
	C.CustomerName,
	SI.SalespersonPersonID,
	P.FullName AS SalesPersonName,
	SI.InvoiceDate,
	IT.Total
FROM SalesInvoiceWithNumberCTE SI
INNER JOIN InvoiceTotalCTE IT ON ( IT.InvoiceID = SI.InvoiceID )
INNER JOIN Application.People P ON ( P.PersonID = SI.SalespersonPersonID )
INNER JOIN Sales.Customers C ON ( C.CustomerID = SI.CustomerID )
WHERE ( SI.SalesPersonInvoiceNumber = 1 )

/*
5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки
*/

;WITH InvoiceLinePriceRankCTE( CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate, UnitPriceRank ) AS
(
	SELECT
		I.CustomerID,
		C.CustomerName,
		IL.StockItemID,
		IL.UnitPrice,
		I.InvoiceDate,
		DENSE_RANK() OVER( PARTITION BY I.CustomerID ORDER BY IL.UnitPrice DESC ) AS UnitPriceRank
	FROM Sales.Invoices I
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = I.InvoiceID )
	INNER JOIN Sales.Customers C ON ( C.CustomerID = I.CustomerID )
),
StockItemRankCTE( CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate, ItemRank, ItemRowNumber ) AS
(
	SELECT
		IL.CustomerID,
		IL.CustomerName,
		IL.StockItemID,
		IL.UnitPrice,
		IL.InvoiceDate,
		DENSE_RANK() OVER( PARTITION BY IL.CustomerID ORDER BY IL.StockItemID DESC ) AS ItemRank,
		ROW_NUMBER() OVER( PARTITION BY IL.CustomerID, IL.StockItemID ORDER BY IL.InvoiceDate DESC ) AS ItemRowNumber
	FROM InvoiceLinePriceRankCTE IL
	WHERE ( IL.UnitPriceRank <= 2 )
)
SELECT
	SIR.CustomerID,
	SIR.CustomerName,
	SIR.StockItemID,
	SIR.UnitPrice,
	SIR.InvoiceDate
FROM StockItemRankCTE SIR
WHERE ( SIR.ItemRank <= 2 )
  AND ( SIR.ItemRowNumber = 1 )
ORDER BY SIR.CustomerID, SIR.UnitPrice DESC