DECLARE @I INT

SET @I = 0;

WHILE( @I < 1608 )
BEGIN
	SET @I = @I + 1

	insert into SalesOrder( UserId, SalesOrderDate, OrderTotal, UserComment, OrderStatusId, ShippingAddressId, BillingAddressId )
	select 1, DATEADD( year, -4, GETDATE()), 100, 'TestOrder', 1, 2, 2
END

SET @I = 0;

WHILE( @I < 4105 )
BEGIN
	SET @I = @I + 1

	insert into SalesOrder( UserId, SalesOrderDate, OrderTotal, UserComment, OrderStatusId, ShippingAddressId, BillingAddressId )
	select 1, DATEADD( year, -3, GETDATE()), 100, 'TestOrder', 1, 2, 2
END

SET @I = 0;

WHILE( @I < 2952 )
BEGIN
	SET @I = @I + 1

	insert into SalesOrder( UserId, SalesOrderDate, OrderTotal, UserComment, OrderStatusId, ShippingAddressId, BillingAddressId )
	select 1, DATEADD( year, -2, GETDATE()), 100, 'TestOrder', 1, 2, 2
END

SET @I = 0;

WHILE( @I < 1344 )
BEGIN
	SET @I = @I + 1

	insert into SalesOrder( UserId, SalesOrderDate, OrderTotal, UserComment, OrderStatusId, ShippingAddressId, BillingAddressId )
	select 1, DATEADD( year, -1, GETDATE()), 100, 'TestOrder', 1, 2, 2
END

SET @I = 0;

WHILE( @I < 3104 )
BEGIN
	SET @I = @I + 1

	insert into SalesOrder( UserId, SalesOrderDate, OrderTotal, UserComment, OrderStatusId, ShippingAddressId, BillingAddressId )
	select 1, GETDATE(), 100, 'TestOrder', 1, 2, 2
END