--создадим файловую группу
ALTER DATABASE [Webshop] ADD FILEGROUP [YearData]
GO

ALTER DATABASE [Webshop] ADD FILE ( NAME = N'Years', FILENAME = N'C:\Work\DB\WebshopYeardata.ndf', 
											   SIZE = 50152KB , FILEGROWTH = 10536KB ) TO FILEGROUP [YearData]
GO

--создаем RIGHT функцию партиционирования  - по умолчанию left!!
CREATE PARTITION FUNCTION [fnYearPartition](DATETIME2(7)) AS RANGE RIGHT FOR VALUES( '20160101','20170101','20180101','20190101','20200101' );																																																									
GO

CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] ALL TO ([YearData])

GO
--удаляется существующий кластерный индекс
 ALTER TABLE SalesOrder DROP CONSTRAINT PK_SalesOrder
 GO

ALTER TABLE SalesOrder ADD CONSTRAINT PK_SalesOrder_SalesOrderYears 
PRIMARY KEY CLUSTERED  (SalesOrderDate, SalesOrderId)
 ON [schmYearPartition]([SalesOrderDate]);

select distinct t.name
from sys.partitions p
inner join sys.tables t
on p.object_id = t.object_id
where p.partition_number <> 1

--наполним табличку
--посмотрим, что внутри таблицы
SELECT $PARTITION.fnYearPartition(SalesOrderDate) AS Partition,   
COUNT(*) AS [COUNT], MIN(SalesOrderDate),MAX(SalesOrderDate) 
FROM SalesOrder
GROUP BY $PARTITION.fnYearPartition(SalesOrderDate) 
ORDER BY Partition ; 

SELECT *
FROM SalesOrder
where ( SalesOrderDate >= '20170202' AND SalesOrderDate < '20180909' )
