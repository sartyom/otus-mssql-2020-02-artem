--Первые таблицы базы данных интеренет магазина


CREATE DATABASE Webshop CONTAINMENT = NONE ON PRIMARY
( 
	NAME = Webshop, FILENAME = N'C:\Work\DB\Webshop.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB
)
LOG ON 
( 
	NAME = Webshop_Log, FILENAME = N'C:\Work\DB\Webshop.ldf' , 
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB
)
GO

use Webshop

GO

CREATE TABLE [Image](
	ImageId INT IDENTITY( 1,1 ) NOT NULL,
	Width INT NOT NULL,
	Height INT NOT NULL,
	[Data] VARBINARY( MAX ) NOT NULL,
	CONSTRAINT PK_Image PRIMARY KEY ( ImageId ASC )
)
GO

CREATE TABLE Category
(
	CategoryId INT IDENTITY( 1,1 ) NOT NULL,
	ParentCategoryId INT NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	CONSTRAINT PK_Category PRIMARY KEY( CategoryId )
)
GO

ALTER TABLE Category ADD CONSTRAINT UX_CategoryName UNIQUE ( [Name] )

GO

CREATE TABLE Brand
(
	BrandId INT IDENTITY( 1,1 ) NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	ImageId INT NOT NULL,
	CONSTRAINT PK_Brand PRIMARY KEY( BrandId )
)
GO

ALTER TABLE Brand ADD CONSTRAINT FK_Brand_Image FOREIGN KEY( ImageId ) REFERENCES [Image] ( ImageId )
GO

ALTER TABLE Brand ADD CONSTRAINT UX_BrandName UNIQUE ( [Name] )
GO

CREATE TABLE Product
(
	ProductId INT IDENTITY(1,1) NOT NULL,
	BrandId INT NOT NULL,
	CategoryId INT NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	ImageId INT NULL,
	Cost DECIMAL( 18,4 ) NULL,
	Price DECIMAL( 18,4 ) NULL,
	CONSTRAINT PK_Product PRIMARY KEY ( ProductId ASC )
)
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Brand FOREIGN KEY( BrandId ) REFERENCES Brand ( BrandId )
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Category FOREIGN KEY( CategoryId ) REFERENCES Category ( CategoryId )
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Image FOREIGN KEY( ImageId ) REFERENCES [Image] ( ImageId )
GO

ALTER TABLE Product ADD CONSTRAINT UX_ProductName UNIQUE ( [Name] )