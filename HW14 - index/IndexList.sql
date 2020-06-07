
-- Какие индексы вам нужны
-- Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе.


Краткое описание

В проекте используется обычные индексы, уникальные индексы и полнотекстовый поиск.

Например:

Country.Name, Brand.Name  - уникальные индексы, так как повторений в имнах стран и брендов быть не может, но при этом эти поля учавствуют в поиске.

ProductName.ProductId + ProductName.LanguageId - уникальный индекс по двум полям, подразумевается, что будет запрос с поиском имени продукта для конкретного языка, например:

SELECT ProductId, Name 
FROM ProductName
WHERE ( ProductId = 112233 ) AND ( LangueageId = 1 )


User.Email - индекс с включением паролья, для ускорения поиска пользователя:

SELECT 1
FROM User
WHWRE ( Email = 'xxxx@mail.com' ) AND ( PasswordHash = 'some_password_hash' )

Пример полнотекстового поиска:

SELECT ProductId, Name
FROM Product
WHERE FREETEXT ( Name, N'iphone or ipod' )


Полный список индексов:

Подсистема адреса:

- Country.Name - уникальный индекс, для быстрого поиска страны

- Region.Name - простой индекс
- Region.CountryId - простой индекс

- City.Name - простой индекс
- City.CountryId - простой индекс
- City.RegionId - простой индекс

- PostalCode.CityId - простой индекс
- PostalCode.PostalCode - простой индекс


Подсистема продукта:

- Product.Name - полнотекстовый поиск
- Product.BrandId - простой индекс
- Product.CategoryId - простой индекс
- Product.Sku - простой индекс
- ProductName.Name - полнотекстовый поиск
- ProductName.ProductId + ProductName.LanguageId - уникальный индекс

- ProductDocument.ProductId - простой индекс

- Document.DocumentHash - уникальный индекс
- Document.Source - прстой индекс
- Document.Code - простой индекс

- Brand.Name - уникальный индекс

- Category.ParentCategoryId - простой индекс
- Category.Name - простой индекс
- CategoryName.Name - простой индекс
- CategoryName.CategoryId + CategoryName.LanguageId - уникальный индекс

- ProductRating.UserId

- User.Email - простой индекс + включить в этот индекс поле пассворда, для более быстрого поиска

- UserWishProduct.UserWishId + UserWishProduct.ProductId - уникальный констреинт
- UserWish.UserId - простой индекс


Подсистема сейлс ордер и корзины:

- SalesOrder.UserId - простой индекс
- SalesOrderLine.SalesOrderId - простой индекс

- Address.UserId - простой индекс

- ShoppingCart.UserId - простой индекс
- ShoppingCartLine.ShoppingCartId - простой индекс