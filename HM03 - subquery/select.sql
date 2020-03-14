--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--1.1
SELECT
	P.PersonID,
	P.FullName
FROM Application.People P
WHERE ( P.IsSalesperson = 1 )
  AND ( P.PersonID NOT IN ( SELECT DISTINCT O.SalespersonPersonID FROM Sales.Orders O ) )

--1.2
;WITH SalesPersonCTE( PersonID, FullName ) AS
(
	SELECT
		P.PersonID,
		P.FullName
	FROM Application.People P
	WHERE ( P.IsSalesperson = 1 ) 
)
SELECT
	SP.PersonID,
	SP.FullName
FROM SalesPersonCTE SP
WHERE ( SP.PersonID NOT IN ( SELECT DISTINCT O.SalespersonPersonID FROM Sales.Orders O ) )

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.
--2.1
SELECT
	SI.StockItemID,
	SI.StockItemName
FROM Warehouse.StockItems SI
WHERE ( SI.UnitPrice = ( SELECT MIN( SIM.UnitPrice ) FROM Warehouse.StockItems SIM ) )

--2.2
SELECT
	SI.StockItemID,
	SI.StockItemName
FROM Warehouse.StockItems SI
WHERE ( SI.UnitPrice = ( SELECT TOP 1 SIM.UnitPrice
						 FROM Warehouse.StockItems SIM
						 ORDER BY SIM.UnitPrice ) )

--2.3 - CTE
;WITH MinItemUnitPriceCTE( MinItemUnitPrice ) AS
(
	SELECT MIN( SIM.UnitPrice )
	FROM Warehouse.StockItems SIM
)
SELECT
	SI.StockItemID,
	SI.StockItemName
FROM Warehouse.StockItems SI
WHERE ( SI.UnitPrice = ( SELECT MUP.MinItemUnitPrice FROM MinItemUnitPriceCTE MUP ) )

--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--3.1
SELECT DISTINCT
	C.CustomerID,
	C.CustomerName
FROM Sales.Customers C
WHERE ( C.CustomerID IN ( SELECT TOP 5 CT.CustomerID
						  FROM Sales.CustomerTransactions CT
						  ORDER BY CT.TransactionAmount DESC ) )

--3.2
;WITH TopCustomerCTE( CustomerID ) AS
(
	SELECT TOP 5 CT.CustomerID
	FROM Sales.CustomerTransactions CT
	ORDER BY CT.TransactionAmount DESC
)
SELECT
	C.CustomerID,
	C.CustomerName
FROM Sales.Customers C
WHERE ( C.CustomerID IN ( SELECT DISTINCT TC.CustomerID FROM TopCustomerCTE TC ) )

--3.3
SELECT DISTINCT
	C.CustomerID,
	C.CustomerName
FROM Sales.Customers C
INNER JOIN Sales.CustomerTransactions CT ON ( CT.CustomerID = C.CustomerID )
WHERE ( CT.CustomerTransactionID IN ( SELECT TOP 5 CT.CustomerTransactionID
									  FROM Sales.CustomerTransactions CT
									  ORDER BY CT.TransactionAmount DESC ) )

--4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов
--4.1
SELECT DISTINCT
	CI.CityID,
	CI.CityName,
	P.FullName
FROM Application.Cities CI
INNER JOIN Sales.Customers C ON ( C.DeliveryCityID = CI.CityID )
INNER JOIN Sales.Invoices I ON ( I.CustomerID = C.CustomerID )
INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = I.InvoiceID )
INNER JOIN Application.People P ON ( P.PersonID = I.PackedByPersonID )
WHERE ( IL.StockItemID IN ( SELECT TOP 3 SI.StockItemID
							FROM Warehouse.StockItems SI
							ORDER BY SI.UnitPrice DESC ) )

--4.2
;WITH TopInvoicesCTE( InvoiceID, CustomerID, PackedByPersonID ) AS
(
	SELECT
		I.InvoiceID,
		I.CustomerID,
		I.PackedByPersonID
	FROM Sales.Invoices I
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = I.InvoiceID )
	WHERE ( IL.StockItemID IN ( SELECT TOP 3 SI.StockItemID
								FROM Warehouse.StockItems SI
								ORDER BY SI.UnitPrice DESC ) )
)
SELECT DISTINCT
	CI.CityID,
	CI.CityName,
	P.FullName
FROM Application.Cities CI
INNER JOIN Sales.Customers C ON ( C.DeliveryCityID = CI.CityID )
INNER JOIN TopInvoicesCTE TI ON ( TI.CustomerID = C.CustomerID )
INNER JOIN Application.People P ON ( P.PersonID = TI.PackedByPersonID )

--5. Объясните, что делает и оптимизируйте запрос:

/*
5.1 Загружаются данные всех инвойсов с общей стомостью больше 27000, и сортировкой по общей сумме по убыванию:
 - идентификатор инвойса
 - дата инвойса
 - имя сотрудника оформившего заказ
 - общая сумма инвойса
 - общая сумма забранных товаров
 - 
*/

SELECT
	Invoices.InvoiceID,
	Invoices.InvoiceDate,
	(	SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice,
	(	SELECT SUM( OrderLines.PickedQuantity * OrderLines.UnitPrice )
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = ( SELECT Orders.OrderId
									 FROM Sales.Orders
									 WHERE ( ( Orders.PickingCompletedWhen IS NOT NULL )
									   AND ( Orders.OrderId = Invoices.OrderId ) ) )
	) AS TotalSummForPickedItems
	FROM Sales.Invoices
	JOIN
	(	SELECT InvoiceId, SUM( Quantity * UnitPrice ) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM( Quantity * UnitPrice ) > 27000
	) AS SalesTotals
	ON ( Invoices.InvoiceID = SalesTotals.InvoiceID )
ORDER BY TotalSumm DESC

--5.2
;WITH InvoiceTotalCTE( InvoiceId, TotalSumm ) AS
(
	SELECT
		IL.InvoiceId,
		SUM( IL.Quantity * IL.UnitPrice ) AS TotalSumm
	FROM Sales.InvoiceLines IL
	GROUP BY InvoiceId
),
PickingCompleteOrderCTE( OrderID, TotalSumm ) AS
(
	SELECT
		O.OrderID,
		SUM( OL.PickedQuantity * OL.UnitPrice ) AS TotalSumm
	FROM Sales.Orders O
	INNER JOIN Sales.OrderLines OL ON ( OL.OrderID = O.OrderID )
	WHERE ( O.PickingCompletedWhen IS NOT NULL )
	GROUP BY O.OrderID
)
SELECT
	I.InvoiceID,
	I.InvoiceDate,
	P.FullName AS SalesPersonName,
	IT.TotalSumm AS TotalSummByInvoice,
	PCO.TotalSumm AS TotalSummForPickedItems
	FROM Sales.Invoices I
	INNER JOIN Application.People P ON ( P.PersonID = I.SalespersonPersonID )
	INNER JOIN InvoiceTotalCTE IT ON ( IT.InvoiceId = I.InvoiceID )
	LEFT JOIN PickingCompleteOrderCTE PCO ON ( PCO.OrderID = I.OrderID )
WHERE ( IT.TotalSumm > 27000 )
ORDER BY IT.TotalSumm DESC