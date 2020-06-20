--переведем БД в однопользовательский режим, отключив остальных
USE master
GO
ALTER DATABASE Webshop SET SINGLE_USER WITH ROLLBACK IMMEDIATE

USE master
ALTER DATABASE Webshop
SET ENABLE_BROKER; --необходимо включить service broker

ALTER DATABASE Webshop SET TRUSTWORTHY ON; --и разрешить доверенные подключения
--посммотрим свойства БД через студию
select DATABASEPROPERTYEX ('Webshop','UserAccess');
SELECT is_broker_enabled FROM sys.databases WHERE name = 'Webshop';

ALTER AUTHORIZATION    
   ON DATABASE::Webshop TO [sa];

ALTER DATABASE Webshop SET MULTI_USER WITH ROLLBACK IMMEDIATE
GO

--Create Message Types for Request and Reply messages
USE Webshop
-- For Request
CREATE MESSAGE TYPE
[//WS/SB/ImportProductRequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
[//WS/SB/ImportProductReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO
--create contract
CREATE CONTRACT [//WS/SB/ImportProductContract]
      ([//WS/SB/ImportProductRequestMessage]
         SENT BY INITIATOR,
       [//WS/SB/ImportProductReplyMessage]
         SENT BY TARGET
      );
GO

--создаем очередь
CREATE QUEUE ImportProductTargetQueue;

GO

--создаем сервис обслуживающий очередь
CREATE SERVICE [//WS/SB/ImportProductTargetService]
       ON QUEUE ImportProductTargetQueue
       ([//WS/SB/ImportProductContract]);
GO


CREATE QUEUE ImportProductInitiatorQueue;

CREATE SERVICE [//WS/SB/ImportProductInitiatorService]
       ON QUEUE ImportProductInitiatorQueue
       ([//WS/SB/ImportProductContract]);
GO

ALTER QUEUE ImportProductInitiatorQueue WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = ConfirmSendProductToQueue, MAX_QUEUE_READERS = 100, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE ImportProductTargetQueue WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = ReceiveProductFromQueue, MAX_QUEUE_READERS = 100, EXECUTE AS OWNER) ; 
