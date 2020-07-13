--поиск пользователя по email
Application.LoadUser 'richard.sapogov@gmail.com'

--загрузка полного дерева категорий
Product.LoadCategoryTree @LanguageId=1 --English
GO
Product.LoadCategoryTree @LanguageId=2 --Russian

GO

Sales.LoadUserShoppingCart @UserId = 3

GO

Product.LoadCategoryProducts @CategoryId=8, @LanguageId=1, @Offset=0, @PageSize=25, @SortMode=2

GO

Product.FindProducts @SearchString='IPHONE', @LanguageId=1, @Offset=0, @PageSize=25, @SortMode=1

GO

Product.LoadProductData @ProductId=12, @LanguageId=1

GO

Sales.LoadShoppigCartProducts @ShoppingCartId=1, @LanguageId=1 

GO

Sales.AddProductToShoppingCart @ShoppingCartId=1, @ProductId=5, @Quantity=5
Sales.AddProductToShoppingCart @ShoppingCartId=1, @ProductId=11, @Quantity=3
Sales.AddProductToShoppingCart @ShoppingCartId=1, @ProductId=12, @Quantity=1


GO

Sales.LoadUserContacts @UserId=3

GO

Sales.CreateSalesOrder @ShoppingCartId=1,
					   @UserId=3,
					   @Comment=N'Place box in front of the door',
					   @ShippingContactId=3,
					   @BillingContactId=2,
					   @SalesTax=25,
					   @LanguageId=1

SELECT *
FROM Sales.SalesOrder

UPDATE Sales.SalesOrder
SET OrderStatusId = 3
WHERE SalesOrderId = 26230


Sales.LoadSalesOrder @SalesOrderId = 26229


