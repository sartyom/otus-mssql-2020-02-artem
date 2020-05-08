/*
1. Загрузить данные из файла StockItems.xml в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить сопоставлять записи по полю StockItemName).
Файл StockItems.xml в личном кабинете.
*/
DECLARE @StockItemsXml XML
DECLARE @docHandle INT

SET @StockItemsXml = ( 
					SELECT *
					FROM OPENROWSET ( BULK 'c:\Work\otus-mssql-2020-02-artem\HW09 - xml\StockItems.xml', SINGLE_BLOB ) AS Data )


EXEC sp_xml_preparedocument @docHandle OUTPUT, @StockItemsXml

;WITH StockItemUpdateCTE( StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice ) AS
(
	SELECT StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
	FROM OPENXML( @docHandle, '/StockItems/Item', 3 )
	WITH ( 
			[StockItemName] NVARCHAR(100)  '@Name',
			[SupplierID] INT 'SupplierID',
			[UnitPackageID] INT 'Package/UnitPackageID',
			[OuterPackageID] INT 'Package/OuterPackageID',
			[QuantityPerOuter] INT 'Package/QuantityPerOuter',
			[TypicalWeightPerUnit] DECIMAL(18,3) 'Package/TypicalWeightPerUnit',
			[LeadTimeDays] INT 'LeadTimeDays',
			[IsChillerStock] BIT 'IsChillerStock',
			[TaxRate] DECIMAL(18,3) 'TaxRate',
			[UnitPrice] DECIMAL(18,2) 'UnitPrice' )
)
MERGE Warehouse.StockItems AS T
USING StockItemUpdateCTE AS S ON ( S.StockItemName = T.StockItemName )
WHEN MATCHED
	THEN UPDATE SET T.SupplierID = S.SupplierID,
					T.UnitPackageID = S.UnitPackageID,
					T.OuterPackageID = S.OuterPackageID,
					T.QuantityPerOuter = S.QuantityPerOuter,
					T.TypicalWeightPerUnit = S.TypicalWeightPerUnit,
					T.LeadTimeDays = S.LeadTimeDays,
					T.IsChillerStock = S.IsChillerStock,
					T.TaxRate = S.TaxRate,
					T.UnitPrice = S.UnitPrice
WHEN NOT MATCHED
	THEN INSERT( StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy )
	VALUES ( S.StockItemName, S.SupplierID, S.UnitPackageID, S.OuterPackageID, S.QuantityPerOuter, S.TypicalWeightPerUnit, S.LeadTimeDays, S.IsChillerStock, S.TaxRate, S.UnitPrice, 1 );


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE

DECLARE
	@vcStockItemsXmlExportQuery VARCHAR(8000),
	@vcStockItemsXmlSelect VARCHAR(800)
 
SET @vcStockItemsXmlSelect = '\
	SELECT \
		StockItemName AS [@Name], \
		SupplierID AS [SupplierID], \
		UnitPackageID AS [Package/UnitPackageID], \
		OuterPackageID AS [Package/OuterPackageID], \
		QuantityPerOuter AS [Package/QuantityPerOuter], \
		TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit], \
		LeadTimeDays AS [LeadTimeDays], \
		IsChillerStock AS [IsChillerStock], \
		TaxRate AS [TaxRate], \
		UnitPrice AS [UnitPrice] \
	FROM Warehouse.StockItems \
	FOR XML PATH( ''Item'' ), ROOT( ''StockItems'' )';

SET @vcStockItemsXmlExportQuery = 'bcp "' + @vcStockItemsXmlSelect  + '" queryout  "c:\Work\otus-mssql-2020-02-artem\HW09 - xml\StockItemsOut.xml" -T -w -t, -S ' + @@SERVERNAME + ' -d ' + db_name()

EXEC master..xp_cmdshell @vcStockItemsXmlExportQuery

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
	StockItemID,
	StockItemName,
	JSON_VALUE( CustomFields, '$.CountryOfManufacture' ) AS CountryOfManufacture,
	JSON_VALUE( CustomFields, '$.Tags[0]' ) AS FirstTag
FROM Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.
*/

;WITH CustomTagsCTE( StockItemID, Tags ) AS
(
	SELECT
		StockItemID,
		STRING_AGG( [value], ', ' )
	FROM Warehouse.StockItems
	CROSS APPLY OPENJSON( CustomFields, '$.Tags' )
	GROUP BY StockItemID
)
SELECT
	SI.StockItemID,
	SI.StockItemName,
	CT.Tags
FROM Warehouse.StockItems SI
INNER JOIN CustomTagsCTE CT ON ( CT.StockItemID = SI.StockItemID )
CROSS APPLY OPENJSON( CustomFields, '$.Tags' )
WHERE [value] = 'Vintage'

/*
5. Пишем динамический PIVOT.
По заданию из занятия “Операторы CROSS APPLY, PIVOT, CUBE”.
Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Нужно написать запрос, который будет генерировать результаты для всех клиентов.
Имя клиента указывать полностью из CustomerName.
Дата должна иметь формат dd.mm.yyyy например 25.12.2019
*/

DECLARE @nvcCustomerList NVARCHAR( MAX ),
		@nvcPivotQuery NVARCHAR( MAX )

SELECT
	@nvcCustomerList = ISNULL( @nvcCustomerList + ',' , '' ) + QUOTENAME(CustomerName)
FROM Sales.Customers

SELECT @nvcPivotQuery = 
';WITH CustomerCTE( CustomerID, CustomerName, InvoiceDate ) AS
(
	SELECT
		C.CustomerID,
		CustomerName,
		DATEADD( mm, DATEDIFF( mm, 0, SI.InvoiceDate ), 0 ) AS InvoiceDate
	FROM Sales.Invoices SI
	INNER JOIN Sales.Customers C ON ( C.CustomerID = SI.CustomerID )
)
SELECT *
FROM CustomerCTE
PIVOT( COUNT( CustomerID )
	   FOR CustomerName IN ( ' + @nvcCustomerList + ' ) ) AS DatePivot
ORDER BY InvoiceDate'

EXEC sp_executesql @nvcPivotQuery;