use WideWorldImporters

-- Чистим от предыдущих экспериментов
DROP FUNCTION IF EXISTS dbo.fn_GetCurrencyRate
DROP ASSEMBLY IF EXISTS SqlLibraryAssembly

-- Включаем CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0 
GO

RECONFIGURE;
GO

-- Для EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 
EXEC sp_changedbowner 'sa'

CREATE ASSEMBLY SqlLibraryAssembly
FROM 'c:\Work\SqlDll\SqlLibrary.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;  

--WITH PERMISSION_SET = SAFE; 

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies
GO

-- Подключить функцию из dll
CREATE FUNCTION dbo.fn_GetCurrencyRate(@fromRate NVARCHAR(50), @toRate NVARCHAR(50))  
RETURNS DECIMAL(18,6)
AS EXTERNAL NAME SqlLibraryAssembly.[SqlLibrary.SqlCurrencyRate].[GetCurrencyRate];
GO

SELECT dbo.fn_GetCurrencyRate( 'USD', 'RUB' )
SELECT dbo.fn_GetCurrencyRate( 'RUB', 'EUR' )
SELECT dbo.fn_GetCurrencyRate( 'EUR', 'RUB' )