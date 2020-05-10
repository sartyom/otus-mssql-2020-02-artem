/*
8) Сделайте параллельно в 2х окнах добавление данных в одну таблицу с разным уровнем изоляции, изменение данных в одной таблице,
изменение одной и той же строки. Что в итоге получилось, что нового узнали.
*/

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRAN

	SELECT *
	FROM Sales.Customers
	order by CustomerID DESC

	SELECT *
	FROM Sales.Customers
	where CustomerID = 1

	INSERT INTO Sales.Customers(
		CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy )
	VALUES
		( NEXT VALUE FOR Sequences.CustomerID, 'New customer 120', 1061, 4, NULL, 3258, 1316, 3, 22090, 19881, 1600, GETDATE(), 0, 0, 0, 7, '(206) 1555-0100', '(206) 1555-0101', 'http://www.microsoft.com/',           'Shop 110', '11235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 1804', 'Ganeshville1', 90669, 1 )
	
	INSERT INTO Sales.Customers(
		CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy )
	VALUES
		( NEXT VALUE FOR Sequences.CustomerID, 'New customer 121', 1061, 4, NULL, 3258, 1316, 3, 22090, 19881, 1600, GETDATE(), 0, 0, 0, 7, '(206) 1555-0100', '(206) 1555-0101', 'http://www.microsoft.com/',           'Shop 110', '11235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 1804', 'Ganeshville1', 90669, 1 )

	--удаление в первом окне
	DELETE 
	FROM Sales.Customers
	WHERE ( CustomerName = 'New customer 120' )

	--удаление во втором окне
	DELETE 
	FROM Sales.Customers
	WHERE ( CustomerName = 'New customer 121' )

	UPDATE Sales.Customers
	SET
		CustomerName = 'New customer 120+',
		CustomerCategoryID = 4,
		LastEditedBy = 15,
		CreditLimit = 1000
	WHERE ( CustomerName = 'New customer 120' )
	
	UPDATE Sales.Customers
	SET
		CustomerName = 'New customer 121+',
		CustomerCategoryID = 4,
		LastEditedBy = 15,
		CreditLimit = 1000
	WHERE ( CustomerName = 'New customer 121' )

	UPDATE Sales.Customers
	SET
		CustomerCategoryID = 4,
		LastEditedBy = 15,
		CreditLimit = 1006
	WHERE ( CustomerID = 1 )

	UPDATE Sales.Customers
	SET
		CustomerCategoryID = 4,
		LastEditedBy = 15,
		CreditLimit = 1008
	WHERE ( CustomerID = 2 )

COMMIT
ROLLBACK



