/*
Вариант 2. Оптимизируйте запрос по БД WorldWideImporters. Приложите текст запроса со статистиками по времени и операциям ввода вывода, опишите кратко ход рассуждений при оптимизации.

SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
 AND ( SELECT SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12
 AND ( SELECT SUM(Total.UnitPrice*Total.Quantity) FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
 AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID ORDER BY ord.CustomerID, det.StockItemID

*/

SET STATISTICS IO, TIME ON 

DBCC FREEPROCCACHE 
GO 
DBCC DROPCLEANBUFFERS 
Go 
DBCC FREESYSTEMCACHE ('ALL') 
GO 
DBCC FREESESSIONCACHE 
GO

Статистика первоначального запроса, время выполнения 406 ms:

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 62 ms, elapsed time = 101 ms.

(3619 rows affected)
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 5, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 849, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 76576, physical reads 2, read-ahead reads 11630, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 406 ms,  elapsed time = 715 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-06-21T13:48:53.9153242-07:00
*/


Оптимизация:

1) Необходимо проверить, чтобы для всех полей, которые учавствуют в JOIN были индексы

Индексы есть для Sales.OrderLines.OrderID, Sales.OrderLines.OrderID, Sales.CustomerTransactions.InvoiceID, Warehouse.StockItemTransactions.StockItemID итд

2) DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate), смысла в нём нет, так как InvoiceDate и OrderDate имеют тип Date, поэтому можно заменить
на простое сравнение

2) Подзапрос SELECT SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID лучше вынести в JOIN
это более читабельно

3) Поиск кастомера с суммой заказов более 250000 для наглядности лучше вынести в CTE

4) Получается вот такой запрос:

;WITH Customer_CTE( CustomerID )
AS
(
	SELECT ordTotal.CustomerID
    FROM Sales.OrderLines AS Total
	JOIN Sales.Orders AS ordTotal On ( ordTotal.OrderID = Total.OrderID )
	GROUP BY ordTotal.CustomerID
	HAVING SUM( Total.UnitPrice*Total.Quantity ) > 250000
)
SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Warehouse.StockItems It ON ( It.StockItemID = det.StockItemID )
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
WHERE Inv.BillToCustomerID != ord.CustomerID
  AND It.SupplierId = 12
  AND ( Inv.InvoiceDate = ord.OrderDate )
  AND EXISTS( SELECT 1 FROM Sales.CustomerTransactions CT WHERE CT.InvoiceID = Inv.InvoiceID )
  AND EXISTS( SELECT 1 FROM Warehouse.StockItemTransactions SIT WHERE SIT.StockItemID = det.StockItemID )
  AND EXISTS( SELECT 1 FROM Customer_CTE CCTE WHERE CCTE.CustomerID = ord.CustomerID )
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

Время запроса сократилось до 281 ms, но статистика не очень хорошая, очень много сканов таблицы Sales.Invoices:

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 172 ms, elapsed time = 198 ms.

(3619 rows affected)
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 4, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 54863, logical reads 174810, physical reads 31, read-ahead reads 11400, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 849, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 281 ms,  elapsed time = 562 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-06-21T13:53:21.3005923-07:00
*/

5) Так как в запросе учавствуют поля OrderID, BillToCustomerID, InvoiceDate, InvoiceID из таблицы Sales.Invoices создаю для них индекс:

CREATE INDEX IX_Sales_Invoices_OrderID_BillToCustomerID_InvoiceDate_InvoiceID ON Sales.Invoices( OrderID, BillToCustomerID, InvoiceDate, InvoiceID )

6) Проверяю результат. Количество сканов Sales.Invoices стало меньше, время запроса сократилось до 62 ms. План запроса стал более простым:

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 78 ms, elapsed time = 136 ms.

(3619 rows affected)
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 5, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 187, physical reads 0, read-ahead reads 181, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 849, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 62 ms,  elapsed time = 250 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-06-21T13:55:13.1696906-07:00

*/

