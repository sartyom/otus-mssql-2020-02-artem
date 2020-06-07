use Webshop7

CREATE FULLTEXT CATALOG WebshopFullTextCatalog 
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]

GO

-- Создаем Full-Text Index
CREATE FULLTEXT INDEX ON Product( [Name] LANGUAGE English )
KEY INDEX PK_Product ON ( WebshopFullTextCatalog )
WITH
(
  CHANGE_TRACKING = AUTO,
  STOPLIST = SYSTEM
);
GO

-- Включаем Full-Text Index
ALTER FULLTEXT INDEX ON Product ENABLE;

GO

CREATE FULLTEXT INDEX ON ProductName( [Name] LANGUAGE English )
KEY INDEX PK_ProductName ON ( WebshopFullTextCatalog )
WITH
(
  CHANGE_TRACKING = AUTO,
  STOPLIST = SYSTEM
);
GO

-- Включаем Full-Text Index
ALTER FULLTEXT INDEX ON ProductName ENABLE;

GO

--Подсистема адреса:

CREATE INDEX IX_Country_Name ON Country( [Name] )

GO

CREATE INDEX IX_Region_Name ON Region( [Name] )

GO

CREATE INDEX IX_Region_CountryId ON Region( CountryId )

GO

CREATE INDEX IX_City_Name ON City( [Name] )

GO

CREATE INDEX IX_City_CountryId ON City( CountryId )

GO

CREATE INDEX IX_City_RegionId ON City( RegionId )

GO

CREATE INDEX IX_PostalCode_CityId ON PostalCode( CityId )

GO

CREATE INDEX IX_PostalCode_PostalCode ON PostalCode( PostalCode )

GO

--Подсистема продукта:

CREATE INDEX IX_Product_BrandId ON Product( BrandId )

GO

CREATE INDEX IX_Product_CategoryId ON Product( CategoryId )

GO

CREATE INDEX IX_Product_Sku ON Product( Sku )

GO

CREATE UNIQUE INDEX UX_ProductName_ProductId_LanguageId ON ProductName( ProductId, LanguageId )

GO

CREATE INDEX IX_ProductDocument_ProductId ON ProductDocument( ProductId )

GO

CREATE UNIQUE INDEX UX_Document_DocumentHash ON Document( DocumentHash )

GO

CREATE INDEX IX_Document_Source ON Document( Source )

GO

CREATE INDEX IX_Document_Code ON Document( Code )

GO

CREATE UNIQUE INDEX UX_Brand_Name ON Brand( [Name] )

GO

CREATE INDEX IX_Category_ParentCategoryId ON Category( ParentCategoryId )

GO

CREATE INDEX IX_Category_Name ON Category( [Name] )

GO

CREATE INDEX IX_CategoryName_Name ON CategoryName( [Name] )

GO

CREATE INDEX UX_CategoryName_CategoryId_LanguageId ON CategoryName( CategoryId, LanguageId )

GO

CREATE INDEX IX_ProductRating_UserId ON ProductRating( UserId )

GO

CREATE INDEX IX_User_Email ON [User]( Email ) INCLUDE ( PasswordHash )

GO

CREATE INDEX UX_UserWishProduct_UserWishId_ProductId ON UserWishProduct( UserWishId, ProductId )

GO

CREATE INDEX IX_UserWish_UserId ON UserWish( UserId )

GO

--Подсистема сейлс ордер и корзины:

CREATE INDEX IX_SalesOrder_UserId ON SalesOrder( UserId )

GO

CREATE INDEX IX_SalesOrderLine_SalesOrderId ON SalesOrderLine( SalesOrderId )

GO

CREATE INDEX IX_Address_UserId ON Address( UserId )

GO

CREATE INDEX IX_ShoppingCart_UserId ON ShoppingCart( UserId )

GO

CREATE INDEX IX_ShoppingCartLine_ShoppingCartId ON ShoppingCartLine( ShoppingCartId )


