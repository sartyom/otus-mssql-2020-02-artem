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

CREATE UNIQUE INDEX UX_Country_Name ON Country( [Name] )

GO

--Подсистема продукта:

CREATE INDEX IX_Product_Sku ON Product( Sku )

GO

CREATE UNIQUE INDEX UX_ProductName_ProductId_LanguageId ON ProductName( ProductId, LanguageId )

GO

CREATE UNIQUE INDEX UX_Document_DocumentHash ON Document( DocumentHash )

GO

CREATE UNIQUE INDEX UX_Document_Code ON Document( Code )

GO

CREATE UNIQUE INDEX UX_Brand_Name ON Brand( [Name] )

GO

CREATE UNIQUE INDEX UX_CategoryName_CategoryId_LanguageId ON CategoryName( CategoryId, LanguageId )

GO

CREATE INDEX IX_User_Email ON [User]( Email ) INCLUDE ( PasswordHash )

GO

CREATE UNIQUE INDEX UX_UserWishProduct_UserWishId_ProductId ON UserWishProduct( UserWishId, ProductId )

GO