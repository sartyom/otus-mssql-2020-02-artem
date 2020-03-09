--1. Все товары, в которых в название есть пометка urgent или название начинается с Animal

SELECT 
	StockItemID,
	StockItemName
FROM Warehouse.StockItems
WHERE ( StockItemName LIKE '%urgent%' )
   OR ( StockItemName LIKE 'Animal%' )

--2. Поставщиков, у которых не было сделано ни одного заказа

SELECT
	S.SupplierID,
	S.SupplierName
FROM Purchasing.Suppliers S
LEFT JOIN Purchasing.PurchaseOrders PO ON ( PO.SupplierID = S.SupplierID )
WHERE ( PO.SupplierID IS NULL )

--3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа,
--   включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20.

SELECT
	SO.OrderID,
	SO.OrderDate,
	DATENAME( month, SO.OrderDate ) AS OrderMonth,
	DATENAME( quarter, SO.OrderDate ) AS Quarter,
	CASE
		WHEN Month( SO.OrderDate ) >= 1 AND Month( SO.OrderDate ) <= 4 THEN 1
		WHEN Month( SO.OrderDate ) >= 4 AND Month( SO.OrderDate ) <= 8 THEN 2
		ELSE 3
	END YearThird
FROM Sales.Orders SO
INNER JOIN Sales.OrderLines OL ON ( OL.OrderID = SO.OrderID )
WHERE ( SO.PickingCompletedWhen IS NOT NULL )
GROUP BY SO.OrderID, SO.OrderDate
HAVING ( SUM( OL.Quantity ) > 20 OR ( SUM( OL.UnitPrice ) > 100 ) )

--3. --Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по номеру квартала, трети года, дате продажи.

SELECT
	SO.OrderID,
	SO.OrderDate,
	DATENAME( month, SO.OrderDate ) AS OrderMonth,
	DATENAME( quarter, SO.OrderDate ) AS Quarter,
	CASE
		WHEN Month( SO.OrderDate ) >= 1 AND Month( SO.OrderDate ) <= 4 THEN 1
		WHEN Month( SO.OrderDate ) >= 4 AND Month( SO.OrderDate ) <= 8 THEN 2
		ELSE 3
	END YearThird
FROM Sales.Orders SO
INNER JOIN Sales.OrderLines OL ON ( OL.OrderID = SO.OrderID )
WHERE ( SO.PickingCompletedWhen IS NOT NULL )
GROUP BY SO.OrderID, SO.OrderDate
HAVING ( SUM( OL.Quantity ) > 20 OR ( SUM( OL.UnitPrice ) > 100 ) )
ORDER BY Quarter, YearThird, SO.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

--4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ

SELECT
	PO.PurchaseOrderID,
	PO.OrderDate,
	D.DeliveryMethodName,
	S.SupplierName,
	P.FullName AS ContactPersonName
FROM Purchasing.PurchaseOrders PO
INNER JOIN Purchasing.Suppliers S ON ( S.SupplierID = PO.SupplierID )
INNER JOIN Application.DeliveryMethods D ON ( PO.DeliveryMethodID = D.DeliveryMethodID )
INNER JOIN Application.People P ON ( P.PersonID = PO.ContactPersonID )
WHERE ( YEAR( PO.OrderDate ) = 2014 )
  AND ( D.DeliveryMethodName IN ( 'Post', 'Road Freight' ) )

--5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ

SELECT TOP 10
	SO.OrderID,
	P.FullName AS SalesPersonName,
	C.CustomerName
FROM Sales.Orders SO
INNER JOIN Application.People P ON ( P.PersonID = SO.SalespersonPersonID )
INNER JOIN Sales.Customers C ON ( C.CustomerID = SO.CustomerID )
ORDER BY SO.OrderDate DESC

--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g

SELECT DISTINCT
	C.CustomerID,
	C.CustomerName,
	C.PhoneNumber
FROM Sales.Orders SO
INNER JOIN Sales.OrderLines OL ON ( OL.OrderID = SO.OrderID )
INNER JOIN Warehouse.StockItems SI ON ( SI.StockItemID = OL.StockItemID )
INNER JOIN Sales.Customers C ON ( C.CustomerID = SO.CustomerID )
WHERE ( SI.StockItemName = 'Chocolate frogs 250g' )