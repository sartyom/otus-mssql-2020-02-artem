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

CREATE TABLE [Image]
(
	ImageId INT IDENTITY( 1,1 ) NOT NULL,
	Width INT NOT NULL,
	Height INT NOT NULL,
	[Data] VARBINARY NOT NULL,
	ImageSource NVARCHAR( 500 ) NOT NULL,
	CreatedDate DATETIME2( 7 ) NOT NULL,
	CONSTRAINT PK_Image PRIMARY KEY CLUSTERED( ImageId )
)
GO

CREATE INDEX IX_Image_ImageSource ON [Image] ( ImageSource )
GO

CREATE TABLE [Language]
(
	LanguageId SMALLINT NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	Code NVARCHAR( 10 ) NOT NULL,
	CONSTRAINT PK_Language PRIMARY KEY CLUSTERED ( LanguageId )
)
GO

CREATE TABLE Category
(
	CategoryId INT IDENTITY( 1, 1 ) NOT NULL,
	ParentCategoryId INT NOT NULL,
	CreatedDate DATETIME2( 7 ) NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	CONSTRAINT PK_Category PRIMARY KEY CLUSTERED ( CategoryId ),
	CONSTRAINT UX_Category_Name UNIQUE NONCLUSTERED ( [Name] )
)
GO

CREATE TABLE CategoryName
(
	CategoryId INT NOT NULL,
	LanguageId SMALLINT NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	CONSTRAINT PK_CategoryName PRIMARY KEY CLUSTERED ( CategoryId, LanguageId )
)
GO

ALTER TABLE CategoryName ADD CONSTRAINT FK_CategoryName_Category FOREIGN KEY( CategoryId ) REFERENCES Category( CategoryId )
GO

ALTER TABLE CategoryName ADD CONSTRAINT FK_CategoryName_Language FOREIGN KEY( LanguageId ) REFERENCES [Language]( LanguageId )
GO

CREATE INDEX IX_CategoryName_Name ON CategoryName ( [Name] )
GO

CREATE TABLE Brand
(
	BrandId INT IDENTITY( 1,1 ) NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	ImageId INT NOT NULL,
	CreatedDate DATETIME2(7) NOT NULL,
	CONSTRAINT PK_Brand PRIMARY KEY CLUSTERED ( BrandId ),
	CONSTRAINT UX_Brand_Name UNIQUE NONCLUSTERED ( [Name] )
)
GO

ALTER TABLE Brand ADD CONSTRAINT FK_Brand_Image FOREIGN KEY( ImageId ) REFERENCES [Image]( ImageId )
GO

CREATE TABLE Product
(
	ProductId INT IDENTITY(1,1) NOT NULL,
	BrandId INT NOT NULL,
	CategoryId INT NOT NULL,
	[Name] NVARCHAR( 100 ) NOT NULL,
	ImageId INT NULL,
	Cost DECIMAL(18, 4) NULL,
	Price DECIMAL(18, 4) NULL,
	Active BIT NOT NULL,
	Sku NVARCHAR(100) NOT NULL,
	CONSTRAINT PK_Product PRIMARY KEY CLUSTERED( ProductId ),
	CONSTRAINT UX_Product_Name UNIQUE NONCLUSTERED(	[Name] )
)
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Brand FOREIGN KEY( BrandId ) REFERENCES Brand( BrandId )
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Category FOREIGN KEY( CategoryId ) REFERENCES Category( CategoryId )
GO

ALTER TABLE Product ADD CONSTRAINT FK_Product_Image FOREIGN KEY( ImageId ) REFERENCES [Image] ( ImageId )
GO

CREATE INDEX IX_Product_Sku ON Product ( Sku )
GO