/*
1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
имя клиента нужно поменять так чтобы осталось только уточнение
например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
дата должна иметь формат dd.mm.yyyy например 25.12.2019

Например, как должны выглядеть результаты:
InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
01.01.2013 3 1 4 2 2
01.02.2013 7 3 4 2 1
*/

;WITH CustomerCTE( CustomerID, CustomerName, InvoiceDate ) AS
(
	SELECT
		C.CustomerID,
		SUBSTRING( C.CustomerName, CHARINDEX( '(', CustomerName ) + 1, CHARINDEX( ')', CustomerName ) - CHARINDEX( '(', CustomerName ) - 1 ) AS CustomerName,
		DATEADD( mm, DATEDIFF( mm, 0, SI.InvoiceDate ), 0 ) AS InvoiceDate
	FROM Sales.Invoices SI
	INNER JOIN Sales.Customers C ON ( C.CustomerID = SI.CustomerID )
	WHERE C.CustomerID BETWEEN 2 AND 6
)
SELECT *
FROM CustomerCTE
PIVOT( COUNT( CustomerID )
	   FOR CustomerName IN ( [Gasport, NY], [Jessie, ND], [Medicine Lodge, KS], [Peeples Valley, AZ], [Sylvanite, MT] ) ) AS DatePivot
ORDER BY InvoiceDate

/*
2. Для всех клиентов с именем, в котором есть Tailspin Toys
вывести все адреса, которые есть в таблице, в одной колонке
*/

;WITH CustomerAddressCTE( CustomerName, CustomerAddress1, CustomerAddress2, CustomerAddress3, CustomerAddress4 ) AS
(
	SELECT
		CustomerName,
		DeliveryAddressLine1 AS CustomerAddress1,
		DeliveryAddressLine2 AS CustomerAddress2,
		PostalAddressLine1 AS CustomerAddress3,
		PostalAddressLine2 AS CustomerAddress4
	FROM Sales.Customers
	WHERE CustomerName LIKE '%Tailspin Toys%'
)
SELECT
	CustomerName,
	CustomerAddress
FROM CustomerAddressCTE
UNPIVOT( CustomerAddress FOR Address IN ( CustomerAddress1, CustomerAddress2, CustomerAddress3, CustomerAddress4 ) ) AS CustomerAddressPivot;

/*
3. В таблице стран есть поля с кодом страны цифровым и буквенным
сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
Пример выдачи

CountryId CountryName Code
1 Afghanistan AFG
1 Afghanistan 4
3 Albania ALB
3 Albania 8

*/

SELECT
	CountryID,
	CountryName,
	CountryCode
FROM ( SELECT
		 CountryID,
		 CountryName,
		 IsoAlpha3Code AS CountryCode1,
		 CAST( IsoNumericCode AS NVARCHAR( 3 ) ) AS CountryCode2
	   FROM Application.Countries ) AS Data
UNPIVOT( CountryCode FOR Code IN ( CountryCode1, CountryCode2 ) ) AS CountryCodePivot

/*
4. Перепишите ДЗ из оконных функций через CROSS APPLY
Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки
*/

SELECT
	C.CustomerID,
	C.CustomerName,
	TIL.StockItemID,
	TIL.UnitPrice,
	TIL.InvoiceDate
FROM Sales.Customers AS C
CROSS APPLY (
	SELECT DISTINCT TOP 2 IL.StockItemID,
						  IL.UnitPrice,
						  SI.InvoiceDate
	FROM Sales.Invoices SI
	INNER JOIN Sales.InvoiceLines IL ON ( IL.InvoiceID = SI.InvoiceID )
	WHERE ( SI.CustomerID = C.CustomerID )
	ORDER BY IL.UnitPrice DESC ) AS TIL