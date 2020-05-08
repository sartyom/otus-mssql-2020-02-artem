/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE OR ALTER FUNCTION WebSite.fnGetTopPurchaseCustomer()
RETURNS TABLE  
AS
RETURN
(
	SELECT TOP 1
		SI.CustomerID,
		SUM( IL.Quantity * IL.UnitPrice ) InvoiceTotal
	FROM Sales.Invoices SI
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = SI.InvoiceID )
	GROUP BY SI.OrderID, SI.CustomerID
	ORDER BY InvoiceTotal DESC
);

GO

SELECT CustomerID, InvoiceTotal
FROM WebSite.fnGetTopPurchaseCustomer()


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE OR ALTER PROCEDURE WebSite.LoadCustomerPurchaseTotal
(
	@CustomerID INT
)
AS
BEGIN
	SELECT
		SI.CustomerID,
		SUM( IL.Quantity * IL.UnitPrice ) PurchaseTotal
	FROM Sales.Invoices SI
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = SI.InvoiceID )
	WHERE ( SI.CustomerID = @CustomerID )
	GROUP BY SI.CustomerID
END

GO

WebSite.LoadCustomerPurchaseTotal @CustomerID=1

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

CREATE OR ALTER FUNCTION WebSite.fnLoadCustomerInvoices
(
	@CustomerID INT
)
RETURNS TABLE  
AS
RETURN
(
	SELECT
		C.CustomerID,
		C.CustomerName,
		C.DeliveryCityID,
		SI.InvoiceID,
		SI.InvoiceDate
	FROM Sales.Invoices SI
	INNER JOIN Sales.Customers C ON ( C.CustomerID = SI.CustomerID )
	WHERE ( SI.CustomerID = @CustomerID )
)

GO

CREATE OR ALTER PROCEDURE WebSite.LoadCustomerInvoices
(
	@CustomerID INT
)
AS
BEGIN

	SELECT
		C.CustomerID,
		C.CustomerName,
		C.DeliveryCityID,
		SI.InvoiceID,
		SI.InvoiceDate
	FROM Sales.Invoices SI
	INNER JOIN Sales.Customers C ON ( C.CustomerID = SI.CustomerID )
	WHERE ( SI.CustomerID = @CustomerID )

END

SET STATISTICS TIME, IO ON

SELECT * FROM WebSite.fnLoadCustomerInvoices( 1 )

WebSite.LoadCustomerInvoices @CustomerID = 1

--я не вижу особых различий в производительности возможно будет необольшое расхождение при компиляции запроса и поиска оптимального плана выполнения

/*

Function result:

SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.

SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 9 ms.

(123 rows affected)
Table 'Invoices'. Scan count 1, logical reads 387, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Customers'. Scan count 0, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 99 ms.
SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.

SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-05-08T03:27:00.6224686-07:00
*/

/*
Procedure result:

SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.

SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.
SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 9 ms.

(123 rows affected)
Table 'Invoices'. Scan count 1, logical reads 387, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Customers'. Scan count 0, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

SQL Server Execution Times: CPU time = 16 ms,  elapsed time = 129 ms.
SQL Server Execution Times: CPU time = 16 ms,  elapsed time = 137 ms.
SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.

SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-05-08T03:29:01.7319035-07:00
*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
*/

--будет использована функция из предыдущего примера WebSite.fnLoadCustomerInvoices

SELECT
	CI.CustomerID,
	CI.InvoiceDate,
	CI.InvoiceID,
	C.WebsiteURL
FROM Sales.Customers C
CROSS APPLY WebSite.fnLoadCustomerInvoices( C.CustomerID ) CI
ORDER BY C.CustomerID, CI.InvoiceDate