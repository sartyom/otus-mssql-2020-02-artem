--1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers

INSERT INTO Sales.Customers(
	CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy )
VALUES
	( NEXT VALUE FOR Sequences.CustomerID, 'New customer 11', 1061, 4, NULL, 3258, 1316, 3, 22090, 19881, 1600, GETDATE(), 0, 0, 0, 7, '(206) 1555-0100', '(206) 1555-0101', 'http://www.microsoft.com/',           'Shop 110', '11235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 1804', 'Ganeshville1', 90669, 1 ),
	( NEXT VALUE FOR Sequences.CustomerID, 'New customer 22', 1060, 6,    1, 3254, NULL, 3, 10483, 25608, 1100, GETDATE(), 0, 0, 0, 7, '(206) 2555-0100', '(206) 2555-0101', 'http://www.microsoft.com/',           'Shop 210', '21235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 2804', 'Ganeshville2', 90669, 1 ),
	( NEXT VALUE FOR Sequences.CustomerID, 'New customer 33', 1059, 7, NULL, 3252, 1320, 3, 31564, 19881, 1200, GETDATE(), 0, 0, 0, 7, '(206) 3555-0100', '(206) 3555-0101', 'http://www.microsoft.com/',           'Shop 310', '31235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 3804', 'Ganeshville3', 90669, 1 ),
	( NEXT VALUE FOR Sequences.CustomerID, 'New customer 44', 1058, 3,    2, 3251, NULL, 3, 19881, 29391, 1300, GETDATE(), 0, 0, 0, 7, '(206) 4555-0100', '(206) 4555-0101', 'http://www.microsoft.com/',           'Shop 410', '41235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 4804', 'Ganeshville4', 90669, 1 ),
	( NEXT VALUE FOR Sequences.CustomerID, 'New customer 55', 1057, 5, NULL, 3261, NULL, 3, 29391, 19881, 1600, GETDATE(), 0, 0, 0, 7, '(206) 5555-0100', '(206) 5555-0101', 'http://www.tailspintoys.com/Hedrick', 'Shop 510', '51235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 5804', 'Ganeshville5', 90669, 1 )

--2. удалите 1 запись из Customers, которая была вами добавлена

DELETE 
FROM Sales.Customers
WHERE ( CustomerName = 'New customer 55' )

--3. изменить одну запись, из добавленных через UPDATE

UPDATE Sales.Customers
SET
	CustomerName = 'New customer 44+',
	CustomerCategoryID = 4,
	LastEditedBy = 15,
	CreditLimit = 1000
WHERE ( CustomerName = 'New customer 44' )

--4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть

;WITH UpdateCustomerCTE( CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy ) AS
(
	SELECT 'New customer 112', 1057, 5, NULL, 3261, NULL, 3, 29391, 19881, 1600, GETDATE(), 0, 0, 0, 7, '(206) 5555-0100', '(206) 5555-0101', 'http://www.tailspintoys.com/Hedrick', 'Shop 510', '51235 Lana Lane', 90669, 0xE6100000010C87BFCBB161954740A15E3AF7E8995EC0, 'PO Box 5804', 'Ganeshville5', 90669, 1
)
MERGE Sales.Customers AS Target
USING UpdateCustomerCTE AS X
    ON ( Target.CustomerName = X.CustomerName )
WHEN MATCHED 
    THEN UPDATE SET Target.CustomerCategoryID = 7
WHEN NOT MATCHED 
    THEN INSERT( CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy )
         VALUES( X.CustomerName, X.BillToCustomerID, X.CustomerCategoryID, X.BuyingGroupID, X.PrimaryContactPersonID, X.AlternateContactPersonID, X.DeliveryMethodID, X.DeliveryCityID, X.PostalCityID, X.CreditLimit, X.AccountOpenedDate, X.StandardDiscountPercentage, X.IsStatementSent, X.IsOnCreditHold, X.PaymentDays, X.PhoneNumber, X.FaxNumber, X.WebsiteURL, X.DeliveryAddressLine1, X.DeliveryAddressLine2, X.DeliveryPostalCode, X.DeliveryLocation, X.PostalAddressLine1, X.PostalAddressLine2, X.PostalPostalCode, X.LastEditedBy );

--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

--export

DECLARE
	@vcCustomersExportQuery VARCHAR(8000),
	@vcSeparator VARCHAR(100)
 
SET @vcSeparator = 'x1$@'
SET @vcCustomersExportQuery = 'bcp "[WideWorldImporters].Sales.Customers" out  "C:\Customers\CustomerExport.csv" -T -w -t' + @vcSeparator + ' -S ' + @@SERVERNAME

exec master..xp_cmdshell @vcCustomersExportQuery

--import

CREATE VIEW Sales.vwImportCustomer AS
SELECT CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,  PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM [WideWorldImporters].Sales.Customers

GO

BULK INSERT [WideWorldImporters].Sales.vwImportCustomer
   FROM "C:\Customers\CustomerImport.csv"
   WITH 
	 (
		BATCHSIZE = 1000, 
		DATAFILETYPE = 'widechar',
		FIELDTERMINATOR = ';',
		ROWTERMINATOR ='\n',
		KEEPNULLS,
		TABLOCK        
	  );

DROP VIEW Sales.vwImportCustomer

/*file content is:
New customer 117;1061;5;;3261;;3;19881;19881;1600.00;2020-03-28;0.000;0;0;7;(206) 555-0100;(206) 555-0101;http://www.microsoft.com/;Shop 10;1235 Lana Lane;90669;PO Box 804;Ganeshville;90669;1
New customer 118;1061;5;;3261;;3;19881;19881;1600.00;2020-03-28;0.000;0;0;7;(206) 555-0100;(206) 555-0101;http://www.microsoft.com/;Shop 10;1235 Lana Lane;90669;PO Box 804;Ganeshville;90669;1
New customer 119;1061;5;;3261;;3;19881;19881;1600.00;2020-03-28;0.000;0;0;7;(206) 555-0100;(206) 555-0101;http://www.microsoft.com/;Shop 10;1235 Lana Lane;90669;PO Box 804;Ganeshville;90669;1
*/
