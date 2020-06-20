CREATE OR ALTER PROCEDURE SendProductToQueue
(
	@BrandId INT,
	@CategoryId INT,
	@Name NVARCHAR(200),
	@Cost DECIMAL(18,4),
	@Price DECIMAL(18,4),
	@Sku NVARCHAR(200)
)
AS
BEGIN
	
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER; --open init dialog
	DECLARE @RequestMessage NVARCHAR(4000); --сообщение, которое будем отправлять
	
	BEGIN TRAN --начинаем транзакцию
		--Prepare the Message  !!!auto generate XML
		SELECT @RequestMessage = ( SELECT
										@BrandId AS BrandId,
										@CategoryId AS CategoryId,
										@Name AS [Name],
										@Cost AS Cost,
										@Price AS Price,
										@Sku AS Sku
								   FOR XML RAW('Product'), root('ImportProductRequestMessage'), ELEMENTS ); 

		--Determine the Initiator Service, Target Service and the Contract 
		BEGIN DIALOG @InitDlgHandle
		FROM SERVICE
		[//WS/SB/ImportProductInitiatorService]
		TO SERVICE
		'//WS/SB/ImportProductTargetService'
		ON CONTRACT
		[//WS/SB/ImportProductContract]
		WITH ENCRYPTION=OFF; 

		--Send the Message
		SEND ON CONVERSATION @InitDlgHandle 
		MESSAGE TYPE
		[//WS/SB/ImportProductRequestMessage]
		(@RequestMessage);
	COMMIT TRAN
END
GO

CREATE OR ALTER PROCEDURE ReceiveProductFromQueue
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER, --идентификатор диалога
			@Message NVARCHAR(4000),--полученное сообщение
			@MessageType Sysname,--тип полученного сообщения
			@ReplyMessage NVARCHAR(4000),--ответное сообщение
			@ProductId INT,
			@BrandId INT,
			@CategoryId INT,
			@Name NVARCHAR(200),
			@Cost DECIMAL(18,4),
			@Price DECIMAL(18,4),
			@Sku NVARCHAR(200),
			@xml XML;

	BEGIN TRAN; 

		--Receive message from Initiator
		RECEIVE TOP(1)
			@TargetDlgHandle = Conversation_Handle,
			@Message = Message_Body,
			@MessageType = Message_Type_Name
		FROM ImportProductTargetQueue; 

		SELECT @Message; --выводим в консоль полученный месседж

		SET @xml = CAST(@Message AS XML); -- получаем xml из мессаджа

		SELECT
			@BrandId = Request.Product.value('BrandId[1]','INT'),
			@CategoryId = Request.Product.value('CategoryId[1]','INT'),
			@Name = Request.Product.value('Name[1]','NVARCHAR(200)'),
			@Cost = Request.Product.value('Cost[1]','DECIMAL(18,4)'),
			@Price = Request.Product.value('Price[1]','DECIMAL(18,4)'),
			@Sku= Request.Product.value('Sku[1]','NVARCHAR(200)')
		FROM @xml.nodes('/ImportProductRequestMessage/Product') as Request(Product);

		IF( @@ROWCOUNT <> 0 )
		BEGIN

			SELECT @ProductId = ProductId
			FROM Product
			WHERE ( Sku = @Sku )

			IF( @ProductId IS NULL )
			BEGIN
				INSERT INTO Product( BrandId, CategoryId, Name, Cost, Price, Sku, Active )
				SELECT @BrandId, @CategoryId, @Name, @Cost, @Price, @Sku, 1
			END
			ELSE
			BEGIN
				UPDATE Product
				SET BrandId = @BrandId,
					CategoryId = @CategoryId,
					Name = @Name,
					Cost = @Cost,
					Price = @Price,
					Sku = @Sku
				WHERE ( ProductId = @ProductId )
			END
		END

		-- Confirm and Send a reply
			IF( @MessageType=N'//WS/SB/ImportProductRequestMessage' )
			BEGIN
				SET @ReplyMessage =N'<ImportProductReplyMessage> Message received</ImportProductReplyMessage>'; 
	
				SEND ON CONVERSATION @TargetDlgHandle
				MESSAGE TYPE
				[//WS/SB/ImportProductReplyMessage]
				(@ReplyMessage);
				END CONVERSATION @TargetDlgHandle;--закроем диалог со стороны таргета
			END

	COMMIT TRAN;
END
GO

CREATE OR ALTER PROCEDURE ConfirmSendProductToQueue
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER, --хэндл диалога
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

	--получим сообщение из очереди инициатора
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM ImportProductInitiatorQueue; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; --закроем диалог со стороны инициатора
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; --в консоль

	COMMIT TRAN; 
END
GO

