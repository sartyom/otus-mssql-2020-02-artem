CREATE OR ALTER PROCEDURE Application.LoadUser
(  
	@Email NVARCHAR(100)
)  
AS
BEGIN  

	SELECT
		UserId,
		FirstName,
		LastName,
		Phone,
		UserRoleId,
		LanguageId,
		TimeOffset,
		PasswordHash
	FROM Application.[User]
	WHERE( Email = @Email )
  
END

GO

CREATE OR ALTER PROCEDURE Product.LoadCategoryTree
(
	@LanguageId SMALLINT
)
AS
BEGIN  

	;WITH CategoryTreeCTE AS
	(
		SELECT
			C.CategoryId,
			C.ParentCategoryId,
			C.Name
		FROM Product.Category C
		LEFT JOIN Product.CategoryName CN ON ( CN.CategoryId = C.CategoryId )
		WHERE ParentCategoryId IS NULL
		
		UNION ALL

		SELECT
			C.CategoryId,
			C.ParentCategoryId,
			C.Name
		FROM Product.Category C
		INNER JOIN CategoryTreeCTE CT ON ( CT.CategoryId = C.ParentCategoryId )
		
	)
	SELECT
		C.CategoryId,
		C.ParentCategoryId,
		ISNULL( CN.Name, C.Name ) AS CategoryName
	FROM CategoryTreeCTE C
	LEFT JOIN Product.CategoryName CN ON ( CN.CategoryId = C.CategoryId AND CN.LanguageId = @LanguageId )
  
END

GO

CREATE OR ALTER PROCEDURE Sales.LoadUserShoppingCart
(  
	@UserId BIGINT
)  
AS
BEGIN  

	DECLARE @ShoppingCartId BIGINT
	
	SELECT @ShoppingCartId = ShoppingCartId
	FROM Sales.ShoppingCart
	WHERE ( UserId = @UserId )

	IF( @ShoppingCartId IS NULL )
	BEGIN
		
		INSERT INTO Sales.ShoppingCart( UserId )
		SELECT @UserId

		SET @ShoppingCartId = SCOPE_IDENTITY()

	END

	SELECT @ShoppingCartId
	  
END

GO

CREATE OR ALTER PROCEDURE Product.LoadCategoryProducts
(  
	@CategoryId BIGINT,
	@LanguageId SMALLINT,
	@Offset INT,
	@PageSize INT,
	@SortMode TINYINT
)  
AS
BEGIN  

	SELECT
		P.ProductId,
		P.BrandId,
		ISNULL( PN.Name, P.Name ) AS ProductName,
		P.Sku,
		PP.Price,
		B.Name AS BrandName,
		COUNT(*) OVER() AS TotalCount
	FROM Product.Product P WITH( NOLOCK )
	INNER JOIN Product.Category C WITH( NOLOCK ) ON ( P.CategoryId = C.CategoryId )
	INNER JOIN Product.Brand B WITH( NOLOCK ) ON ( B.BrandId = P.BrandId )
	LEFT JOIN Product.ProductName PN WITH( NOLOCK ) ON ( P.ProductId = PN.ProductId AND PN.LanguageId = @LanguageId )
	LEFT JOIN Product.ProductPrice PP WITH( NOLOCK ) ON ( PP.ProductId = P.ProductId )
	WHERE ( P.Active = 1 )
	  AND ( PP.Price IS NOT NULL )
	  AND ( P.CategoryId = @CategoryId )
	ORDER BY
		CASE WHEN ( @SortMode = 1 ) THEN PP.Price END ASC,
		CASE WHEN ( @SortMode = 2 ) THEN PP.Price END DESC
	OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY

END

GO

CREATE OR ALTER PROCEDURE Product.FindProducts
(  
	@SearchString NVARCHAR(100),
	@LanguageId SMALLINT,
	@Offset INT,
	@PageSize INT,
	@SortMode TINYINT
)  
AS
BEGIN  

	SELECT
		P.ProductId,
		P.BrandId,
		P.CategoryId,
		ISNULL( CN.Name, C.Name ) AS CategoryName,
		ISNULL( PN.Name, P.Name ) AS ProductName,
		P.Sku,
		PP.Price,
		B.Name AS BrandName,
		COUNT(*) OVER() AS TotalCount
	FROM Product.Product P WITH( NOLOCK )
	INNER JOIN Product.Category C WITH( NOLOCK ) ON ( P.CategoryId = C.CategoryId )
	INNER JOIN Product.Brand B WITH( NOLOCK ) ON ( B.BrandId = P.BrandId )
	LEFT JOIN Product.CategoryName CN WITH( NOLOCK ) ON ( CN.CategoryId = C.CategoryId AND CN.LanguageId = @LanguageId )
	LEFT JOIN Product.ProductName PN WITH( NOLOCK ) ON ( P.ProductId = PN.ProductId AND PN.LanguageId = @LanguageId )
	LEFT JOIN Product.ProductPrice PP WITH( NOLOCK ) ON ( PP.ProductId = P.ProductId )
	WHERE ( P.Active = 1 )
	  AND ( PP.Price IS NOT NULL )
	  AND ( FREETEXT( P.Name, @SearchString ) OR FREETEXT( PN.Name, @SearchString ) )
	ORDER BY
		CASE WHEN ( @SortMode = 1 ) THEN PP.Price END ASC,
		CASE WHEN ( @SortMode = 2 ) THEN PP.Price END DESC
	OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
  
END

GO

CREATE OR ALTER PROCEDURE Product.LoadProductData
(  
	@ProductId BIGINT,
	@LanguageId SMALLINT
)  
AS
BEGIN  

	SELECT
		P.ProductId,
		P.BrandId,
		P.CategoryId,
		ISNULL( CN.Name, C.Name ) AS CategoryName,
		ISNULL( PN.Name, P.Name ) AS ProductName,
		P.Active,
		P.Sku,
		PP.Price,
		B.Name AS BrandName
	FROM Product.Product P WITH( NOLOCK )
	INNER JOIN Product.Category C WITH( NOLOCK ) ON ( P.CategoryId = C.CategoryId )
	INNER JOIN Product.Brand B WITH( NOLOCK ) ON ( B.BrandId = P.BrandId )
	LEFT JOIN Product.CategoryName CN WITH( NOLOCK ) ON ( CN.CategoryId = C.CategoryId AND CN.LanguageId = @LanguageId )
	LEFT JOIN Product.ProductName PN WITH( NOLOCK ) ON ( P.ProductId = PN.ProductId AND PN.LanguageId = @LanguageId )
	LEFT JOIN Product.ProductPrice PP WITH( NOLOCK ) ON ( PP.ProductId = P.ProductId )
	WHERE ( P.ProductId = @ProductId )

	SELECT
		U.UserId,
		U.FirstName,
		U.LastName,
		PR.Comment,
		PR.RatingValue,
		PR.CreatedDate
	FROM Product.ProductRating PR WITH( NOLOCK )
	INNER JOIN [Application].[User] U WITH( NOLOCK ) ON ( U.UserId = PR.UserId )
	WHERE( PR.ProductId = @ProductId )
	ORDER BY PR.CreatedDate

	SELECT
		D.DocumentId,
		D.Code,
		D.CreatedDate,
		D.Data,
		D.DocumentTypeId,
		D.Height,
		D.Width
	FROM Product.ProductDocument PD WITH( NOLOCK )
	INNER JOIN Product.Document D WITH( NOLOCK ) ON ( D.DocumentId = PD.DocumentId ) 
	WHERE ( PD.ProductId = @ProductId )
	ORDER BY D.DocumentTypeId, PD.[Order]
  
END

GO

CREATE OR ALTER PROCEDURE Sales.LoadShoppigCartProducts
(  
	@ShoppingCartId BIGINT,
	@LanguageId SMALLINT
)  
AS
BEGIN  

	SELECT
		SCL.ProductId,
		SCL.Quantity,
		PP.Price,
		ISNULL( PN.Name, P.Name ) AS ProductName
	FROM Sales.ShoppingCartLine SCL
	INNER JOIN Product.Product P ON ( P.ProductId = SCL.ProductId )
	INNER JOIN Product.ProductPrice PP ON ( PP.ProductId = P.ProductId )
	LEFT JOIN Product.ProductName PN ON ( PN.ProductId = P.ProductId AND PN.LanguageId = @LanguageId )
	ORDER BY SCL.[Order]
	  
END

GO

CREATE OR ALTER PROCEDURE Sales.AddProductToShoppingCart
(  
	@ShoppingCartId BIGINT,
	@ProductId BIGINT,
	@Quantity INT
)  
AS
BEGIN  

	DECLARE @Order INT

	IF( @Quantity = 0 )
	BEGIN
		DELETE 
		FROM Sales.ShoppingCartLine
		WHERE ( ShoppingCartId = @ShoppingCartId )
		  AND ( ProductId = @ProductId )
	END
	ELSE
	IF( EXISTS ( SELECT 1 FROM Sales.ShoppingCartLine WHERE( ( ShoppingCartId = @ShoppingCartId ) AND ( ProductId = @ProductId ) ) ) )
	BEGIN
		UPDATE Sales.ShoppingCartLine
		SET Quantity = Quantity + @Quantity
		WHERE ( ShoppingCartId = @ShoppingCartId )
		  AND ( ProductId = @ProductId )
	END
	ELSE
	BEGIN
		
		SELECT @Order = MAX( [Order] )
		FROM Sales.ShoppingCartLine
		WHERE ShoppingCartId = @ShoppingCartId

		IF( @Order IS NULL ) SET @Order = 0

		SET @Order = @Order + 1
		
		INSERT INTO Sales.ShoppingCartLine( ShoppingCartId, ProductId, Quantity, [Order] )
		SELECT @ShoppingCartId, @ProductId, @Quantity, @Order 
	END
	  
END

GO

CREATE OR ALTER PROCEDURE Sales.LoadUserContacts
(  
	@UserId BIGINT
)  
AS
BEGIN  

	SELECT
		CT.ContactId,
		C.Name AS CountryName,
		CITY.Name AS CityName,
		PC.PostalCode,
		CT.FirstName,
		CT.LastName,
		CT.Phone,
		CT.Street1,
		CT.Street2
	FROM Location.Contact CT
	INNER JOIN Location.Country C ON ( C.CountryId = CT.CountryId )
	INNER JOIN Location.City CITY ON ( CITY.CityId = CT.CityId )
	INNER JOIN Location.PostalCode PC ON ( PC.PostalCodeId = CT.PostalCodeId )
	WHERE ( CT.UserId = @UserId )
  
END

GO

CREATE OR ALTER PROCEDURE Sales.CreateSalesOrder
(  
	@ShoppingCartId BIGINT,
	@UserId BIGINT,
	@Comment NVARCHAR(500),
	@ShippingContactId BIGINT,
	@BillingContactId BIGINT,
	@SalesTax DECIMAL(18,4),
	@LanguageId SMALLINT,
	@SalesOrderId BIGINT = NULL OUTPUT
)  
AS
BEGIN  

	BEGIN TRY

		BEGIN TRAN
		
		DECLARE @OrderTotal DECIMAL(18,4)

		SELECT @OrderTotal = SUM( PP.Price * SCL.Quantity )
		FROM Sales.ShoppingCartLine SCL
		INNER JOIN Product.ProductPrice PP ON ( PP.ProductId = SCL.ProductId )
		WHERE ( SCL.ShoppingCartId = @ShoppingCartId )
		GROUP BY SCL.ShoppingCartId

		INSERT INTO Sales.SalesOrder( UserId, CreatedDate, Comment, OrderStatusId, ShippingContactId, BillingContactId, OrderTotal )
		SELECT @UserId, SYSUTCDATETIME(), @Comment, 1, @ShippingContactId, @BillingContactId, @OrderTotal

		SET @SalesOrderId = SCOPE_IDENTITY()

		INSERT INTO Sales.SalesOrderLine( SalesOrderId, ProductId, Quantity, SalesTax, ProductName, UserComment, SalesPrice )
		SELECT @SalesOrderId, SCL.ProductId, SCL.Quantity, @SalesTax, ISNULL( PN.Name, P.Name ), @Comment, PP.Price
		FROM Sales.ShoppingCartLine SCL
		INNER JOIN Product.Product P ON ( P.ProductId = SCL.ProductId )
		INNER JOIN Product.ProductPrice PP ON ( PP.ProductId = SCL.ProductId )
		LEFT JOIN Product.ProductName PN ON ( PN.ProductId = SCL.ProductId )
		WHERE ( SCL.ShoppingCartId = @ShoppingCartId )

		DELETE
		FROM Sales.ShoppingCartLine
		WHERE ( ShoppingCartId = @ShoppingCartId )

		COMMIT
	
	END TRY
	BEGIN CATCH

		IF( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION;

		THROW;

	END CATCH
END

GO

CREATE OR ALTER PROCEDURE Sales.LoadSalesOrder
(  
	@SalesOrderId BIGINT
)  
AS
BEGIN  

	SELECT
		SalesOrderId,
		UserId,
		CreatedDate,
		Comment,
		OrderTotal,
		OrderStatusId
	FROM Sales.SalesOrder
	WHERE ( SalesOrderId = @SalesOrderId )

	SELECT
		SO.SalesOrderId,
		SO.OrderStatusId,
		SO.ValidFrom,
		SO.ValidTo
	FROM Sales.SalesOrder FOR System_Time ALL SO
	WHERE ( SalesOrderId = @SalesOrderId )
	ORDER BY SO.ValidFrom
	
	SELECT
		SalesOrderLineId,
		ProductId,
		ProductName,
		UserComment,
		SalesPrice,
		Quantity
	FROM Sales.SalesOrderLine
	WHERE ( SalesOrderId = @SalesOrderId )

	SELECT
		C.Name AS CountryName,
		CITY.Name AS CityName,
		PC.PostalCode,
		CT.FirstName,
		CT.LastName,
		CT.Phone,
		CT.Street1,
		CT.Street2
	FROM Sales.SalesOrder SO
	INNER JOIN Location.Contact CT ON ( CT.ContactId = SO.ShippingContactId )
	INNER JOIN Location.Country C ON ( C.CountryId = CT.CountryId )
	INNER JOIN Location.City CITY ON ( CITY.CityId = CT.CityId )
	INNER JOIN Location.PostalCode PC ON ( PC.PostalCodeId = CT.PostalCodeId )
	WHERE ( SO.SalesOrderId = @SalesOrderId )

	SELECT
		C.Name AS CountryName,
		CITY.Name AS CityName,
		PC.PostalCode,
		CT.FirstName,
		CT.LastName,
		CT.Phone,
		CT.Street1,
		CT.Street2
	FROM Sales.SalesOrder SO
	INNER JOIN Location.Contact CT ON ( CT.ContactId = SO.BillingContactId )
	INNER JOIN Location.Country C ON ( C.CountryId = CT.CountryId )
	INNER JOIN Location.City CITY ON ( CITY.CityId = CT.CityId )
	INNER JOIN Location.PostalCode PC ON ( PC.PostalCodeId = CT.PostalCodeId )
	WHERE ( SO.SalesOrderId = @SalesOrderId )
  
END