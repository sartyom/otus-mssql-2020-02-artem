/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

--Read Committed будет достаточно, если использовать Read Uncommitted, то запрос может вернуть кастомера, у которого нет покупок,
--хотя он действительно пытался купить самый дорогой товар, но по каким то причинам был откат транзакции

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

--Read Committed будет достаточно, но если необходимо выводить сумму всех покупок в карточке кастомера, то можно использовать WITH(NOLOCK) в запросе

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

--Read Committed

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

--Read Committed, потому что запрос должен вернуть только подтвержденные инвойсы

SELECT
	CI.CustomerID,
	CI.InvoiceDate,
	CI.InvoiceID,
	C.WebsiteURL
FROM Sales.Customers C
CROSS APPLY WebSite.fnLoadCustomerInvoices( C.CustomerID ) CI
ORDER BY C.CustomerID, CI.InvoiceDate


/*
5) Во всех процедурах, в описании укажите для преподавателям
какой уровень изоляции нужен и почему.
*/

--в описании указал

/*
7) Напишите запрос в транзакции где есть выборка, вставка\добавление\удаление данных и параллельно запускаем выборку данных в разных
уровнях изоляции, нужно предоставить мини отчет, что на каком уровне было видно со скриншотами и ваши выводы (1-2 предложение)

8) Сделайте параллельно в 2х окнах добавление данных в одну таблицу с разным уровнем изоляции, изменение данных в одной таблице,
изменение одной и той же строки. Что в итоге получилось, что нового узнали.

Эксперименты:

1 - TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

В разных окнах добаляются разные кастомеры.
В первом окне удаляется кастомер добавленный во втором окне - удаление "грязных данных". Удалить не получается - подвисание.
Во втором окне удаляется кастомер из первого окна. Тут происходит дед лок, который автоматически откатывается сервером. С ошибкой:

Transaction (Process ID 67) was deadlocked on lock resources with another process and has been chosen as the deadlock victim. Rerun the transaction.

Во втором окне транзакция автоматически откатывается, в первом нет!!!

2 - TRANSACTION ISOLATION LEVEL READ COMMITTED

- До тех пор, пока в разных окнах не делались изменения данных, можно делать селекты.
После изменеия данных  строка(таблица) будет залочена и селект работать не будет:

SELECT * FROM Sales.Customers ORDER BY CustomerID DESC

- НО, если сделать селелект конкретной не изменённой строки, то всё ок:

SELECT * FROM Sales.Customers WHERE CustomerID = 1

- Если удалить кастомера в первом окне а затем попробовать удалить ДРУГОГО кастомера во втором окне,
то операция "подвиснет" и будет ждать закрытия транзакции в первом окне

НО, вставка новых катомеров будет работать в обоих окнах без блокировок!!!

Апдейт кастомеров - если строки разные, то возможен апдейт в разных окнах, если строки одинаковые
то происходит блокировка!!!

Вывод: при различных операциях происходит блокировка либо на уровне строк, либо на уровне таблицы.

3 - измененияв разных окнах с разным уровнем изоляции

Как я уже писал, данные блокируютсяна на уровне строк, поэтому блокировки возможны в обоих окнах.

Например, если в левом окне REPEATABLE READ, то при обновлении данных в правом будет блокировка. Но для этого
данные в левом окне должны быть прочитаны.

Или если в левом окне ISOLATION LEVEL SERIALIZABLE, и прочитана вся таблица:

SELECT * FROM Sales.Customers ORDER BY CustomerID DESC

то в правом окне никакие операции с таблицей Sales.Customers не будут доступны.

*/

