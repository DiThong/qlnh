USE [Quanly nha hàng]
GO
/****** Object:  UserDefinedFunction [dbo].[ft_Charged_GrandTotal]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Charged_GrandTotal]
(
	@BillID INT
)
RETURNS FLOAT
AS
BEGIN
	RETURN (SELECT SUM(dbo.OrderDetails.Total) AS [GrandTotal]
	FROM dbo.OrderDetails 
	WHERE dbo.OrderDetails.BillID = @BillID);
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Charged_Total]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ft_Charged_Total]
(
	@BillID int,
	@FoodID int
)
RETURNS FLOAT
AS
BEGIN
	--get price of Food
	DECLARE @UnitPriceOfFood FLOAT; 
	SELECT @UnitPriceOfFood = dr.UnitPrice 
		FROM dbo.Food AS dr
		WHERE dr.FoodID = @FoodID;
	
	--get quantity of Food
	DECLARE @Quantity FLOAT;
	SELECT @Quantity = od.Quantity
		FROM dbo.OrderDetails AS od
		WHERE BillID = @BillID AND FoodID = @FoodID;
	
	--charged total
	DECLARE @Total FLOAT;
	SET @Total =  @Quantity * @UnitPriceOfFood;

	RETURN @Total;
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Statistic_Food_Quantity]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Statistic_Food_Quantity] 
(
	-- Add the parameters for the function here
	@fromdate DATETIME,
	@toDate DATETIME 
)
RETURNS @table TABLE 
(
	FoodName NVARCHAR(MAX),
	Quantity INT
)
AS
BEGIN
	INSERT INTO @table
	SELECT FoodName AS [FoodName], COALESCE(SUM(dbo.Vw_OrderDetails.Quantity), 0) AS [Quantity]
	FROM dbo.Vw_OrderDetails, dbo.Bills
	WHERE dbo.Vw_OrderDetails.BillID = Bills.BillID AND
			dbo.Bills.OrderTime BETWEEN @fromdate AND @toDate
	GROUP BY dbo.Vw_OrderDetails.FoodName;
	RETURN; 
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Statistic_Food_Revenue]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Statistic_Food_Revenue] 
(
	-- Add the parameters for the function here
	@fromdate DATETIME,
	@toDate DATETIME 
)
RETURNS @table TABLE 
(
	FoodName NVARCHAR(MAX),
	Revenue FLOAT
)
AS
BEGIN
	INSERT INTO @table
	SELECT FoodName AS [FoodName], COALESCE(SUM(dbo.Vw_OrderDetails.Total), 0.0) AS [Revenue]
	FROM dbo.Vw_OrderDetails, dbo.Bills
	WHERE dbo.Vw_OrderDetails.BillID = Bills.BillID AND
			dbo.Bills.OrderTime BETWEEN @fromdate AND @toDate
	GROUP BY dbo.Vw_OrderDetails.FoodName;
	RETURN; 
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Statistic_Foodtype_Quantity]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Statistic_Foodtype_Quantity] 
(
	-- Add the parameters for the function here
	@fromdate DATETIME,
	@toDate DATETIME 
)
RETURNS @table TABLE 
(
	FoodTypeName NVARCHAR(MAX),
	Quantity INT
)
AS
BEGIN
	INSERT INTO @table
	SELECT dt.FoodTypeName, d.Quantity 
	FROM (SELECT dbo.Food.FoodTypeID, COALESCE(SUM(dbo.Vw_OrderDetails.Quantity), 0) AS Quantity
	FROM dbo.Vw_OrderDetails, dbo.Bills, dbo.Food
	WHERE dbo.Vw_OrderDetails.BillID = Bills.BillID AND
			dbo.Vw_OrderDetails.FoodID = dbo.Food.FoodID AND
			dbo.Bills.OrderTime BETWEEN @fromdate AND @toDate
	GROUP BY Food.FoodTypeID) AS d, dbo.FoodTypes AS dt
	WHERE d.FoodTypeID =  dt.FoodTypeID;
	RETURN; 
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Statistic_Foodtype_Revenue]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Statistic_Foodtype_Revenue] 
(
	-- Add the parameters for the function here
	@fromdate DATETIME,
	@toDate DATETIME 
)
RETURNS @table TABLE 
(
	FoodTypeName NVARCHAR(MAX),
	Revenue FLOAT
)
AS
BEGIN
	INSERT INTO @table
	SELECT dt.FoodTypeName, d.Revenue
	FROM (SELECT dbo.Food.FoodTypeID, COALESCE(SUM(dbo.Vw_OrderDetails.Total), 0.0) AS Revenue
	FROM dbo.Vw_OrderDetails, dbo.Bills, dbo.Food
	WHERE dbo.Vw_OrderDetails.BillID = Bills.BillID AND
			dbo.Vw_OrderDetails.FoodID = dbo.Food.FoodID AND
			dbo.Bills.OrderTime BETWEEN @fromdate AND @toDate
	GROUP BY Food.FoodTypeID) AS d, dbo.FoodTypes AS dt
	WHERE d.FoodTypeID =  dt.FoodTypeID;
	RETURN; 
END


GO
/****** Object:  UserDefinedFunction [dbo].[ft_Total_Revenue]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_Total_Revenue]
(
@fromDate DATETIME,
@toDate DATETIME
)
RETURNS FLOAT
AS
BEGIN
	-- Return the result of the function
	RETURN (SELECT COALESCE(SUM(Revenue), 0.0) 
			FROM dbo.ft_Statistic_Foodtype_Revenue(@fromDate, @toDate));

END


GO
/****** Object:  Table [dbo].[Ar]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ar](
	[ArID] [int] NOT NULL,
	[ArName] [nvarchar](50) NULL,
 CONSTRAINT [PK_Ar] PRIMARY KEY CLUSTERED 
(
	[ArID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bills]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bills](
	[BillID] [int] IDENTITY(1,1) NOT NULL,
	[OrderTime] [datetime] NOT NULL,
	[GrandTotal] [float] NOT NULL,
	[IsPaid] [bit] NOT NULL,
	[TableID] [int] NOT NULL,
 CONSTRAINT [PK_Bills] PRIMARY KEY CLUSTERED 
(
	[BillID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Food]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Food](
	[FoodID] [int] IDENTITY(1,1) NOT NULL,
	[FoodTypeID] [int] NOT NULL,
	[FoodName] [nvarchar](max) NOT NULL,
	[UnitPrice] [float] NOT NULL,
	[Image] [varbinary](max) NULL,
 CONSTRAINT [PK_Drinks] PRIMARY KEY CLUSTERED 
(
	[FoodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FoodTypes]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FoodTypes](
	[FoodTypeID] [int] IDENTITY(1,1) NOT NULL,
	[FoodTypeName] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_DrinkTypes] PRIMARY KEY CLUSTERED 
(
	[FoodTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[OrderDetails]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderDetails](
	[BillID] [int] NOT NULL,
	[FoodID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[Total] [float] NOT NULL,
 CONSTRAINT [PK_OrderDetails] PRIMARY KEY CLUSTERED 
(
	[BillID] ASC,
	[FoodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tables]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tables](
	[TableID] [int] NOT NULL,
	[TableName] [nvarchar](max) NOT NULL,
	[ArID] [int] NULL,
 CONSTRAINT [PK_Tables] PRIMARY KEY CLUSTERED 
(
	[TableID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  View [dbo].[Vw_FoodType]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_FoodType]
AS
SELECT        FoodTypeID
FROM            dbo.FoodTypes
WHERE        EXISTS
                             (SELECT        FoodID, FoodTypeID, FoodName, UnitPrice, Image
                               FROM            dbo.Food
                               WHERE        (FoodTypeID = dbo.FoodTypes.FoodTypeID))


GO
/****** Object:  View [dbo].[Vw_FoodTypes]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_FoodTypes]
AS
SELECT        FoodTypeName, FoodTypeID
FROM            dbo.FoodTypes
WHERE        EXISTS
                             (SELECT        FoodID, FoodTypeID, FoodName, UnitPrice, Image
                               FROM            dbo.Food
                               WHERE        (FoodTypeID = dbo.FoodTypes.FoodTypeID))


GO
/****** Object:  View [dbo].[Vw_Free_Tables]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_Free_Tables]
AS
SELECT        TableID, ArID, TableName
FROM            dbo.Tables
WHERE        (TableID NOT IN
                             (SELECT DISTINCT TableID
                               FROM            dbo.Bills AS b
                               WHERE        (IsPaid = 0)))


GO
/****** Object:  View [dbo].[Vw_OrderDetails]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_OrderDetails]
AS
SELECT        dbo.Food.FoodID, dbo.Food.FoodTypeID, dbo.Food.FoodName, dbo.Food.UnitPrice, dbo.Food.Image, dbo.FoodTypes.FoodTypeName, dbo.OrderDetails.BillID, dbo.OrderDetails.Quantity, 
                         dbo.OrderDetails.Total
FROM            dbo.Food INNER JOIN
                         dbo.FoodTypes ON dbo.Food.FoodTypeID = dbo.FoodTypes.FoodTypeID INNER JOIN
                         dbo.OrderDetails ON dbo.Food.FoodID = dbo.OrderDetails.FoodID


GO
/****** Object:  View [dbo].[Vw_Receipt]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_Receipt]
AS (SELECT        dbo.OrderDetails.*, dbo.Food.FoodName, dbo.Food.UnitPrice
FROM            dbo.Food INNER JOIN
                         dbo.OrderDetails ON dbo.Food.FoodID = dbo.OrderDetails.FoodID)

GO
ALTER TABLE [dbo].[Bills]  WITH CHECK ADD  CONSTRAINT [FK_Bills_Tables] FOREIGN KEY([TableID])
REFERENCES [dbo].[Tables] ([TableID])
GO
ALTER TABLE [dbo].[Bills] CHECK CONSTRAINT [FK_Bills_Tables]
GO
ALTER TABLE [dbo].[Food]  WITH CHECK ADD  CONSTRAINT [FK_Food_FoodTypes] FOREIGN KEY([FoodTypeID])
REFERENCES [dbo].[FoodTypes] ([FoodTypeID])
GO
ALTER TABLE [dbo].[Food] CHECK CONSTRAINT [FK_Food_FoodTypes]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Bills] FOREIGN KEY([BillID])
REFERENCES [dbo].[Bills] ([BillID])
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Bills]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Food] FOREIGN KEY([FoodID])
REFERENCES [dbo].[Food] ([FoodID])
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Food]
GO
ALTER TABLE [dbo].[Tables]  WITH CHECK ADD  CONSTRAINT [FK_Tables_Ar] FOREIGN KEY([ArID])
REFERENCES [dbo].[Ar] ([ArID])
GO
ALTER TABLE [dbo].[Tables] CHECK CONSTRAINT [FK_Tables_Ar]
GO
/****** Object:  StoredProcedure [dbo].[sp_Add_Item]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Add_Item](
	@BillID INT,
	@FoodID INT,
	@Quantity INT
)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.OrderDetails 
	        ( BillID, FoodID, Quantity, Total )
	VALUES  ( @BillID, -- BillID - int
	          @FoodID, -- FoodID - int
	          @Quantity, -- Quantity - int
	          0.0  -- Total - float
	          )
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Change_Quantity_Item]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_Change_Quantity_Item]
(
@BillID INT,
@FoodID INT,
@Quantity INT
)
AS
BEGIN
	SET NOCOUNT ON;
	IF (@Quantity <= 0)
		RETURN;
	
	UPDATE dbo.OrderDetails SET Quantity = @Quantity;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Delete_Bill]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Delete_Bill]
(@BillID INT)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;  
	DELETE dbo.OrderDetails WHERE BillID = @BillID;
	DELETE dbo.Bills WHERE BillID = @BillID;
	COMMIT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Delete_Item]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Delete_Item]
(
	@BillID INT,
	@FoodID INT
)
AS
BEGIN
	BEGIN TRANSACTION
		DECLARE @Total FLOAT;
		SELECT @Total = Total FROM dbo.OrderDetails WHERE BillID = @BillID AND FoodID = @FoodID;
		
		DELETE FROM dbo.OrderDetails WHERE BillID = @BillID AND FoodID = @FoodID;
		UPDATE dbo.Bills SET GrandTotal = GrandTotal - @Total WHERE BillID = @BillID;
	COMMIT
END


GO
/****** Object:  StoredProcedure [dbo].[sp_New_Bill]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_New_Bill]
(@TabelID INT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Bills
	        ( OrderTime ,
	          GrandTotal ,
	          IsPaid ,
	          TableID
	        )
	VALUES  ( GETDATE() , -- OrderTime - datetime
	          0.0 , -- GrandTotal - float
	          0 , -- IsPaid - bit
	          @TabelID  -- TableID - int
	        )
END


GO
/****** Object:  StoredProcedure [dbo].[sp_New_Food]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_New_Food]
(
@FoodTypeID INT,
@FoodName NVARCHAR(MAX),
@UnitPrice FLOAT,
@Image VARBINARY(MAX)
)
AS
BEGIN
	INSERT INTO dbo.Food
	        ( FoodTypeID ,
	          FoodName ,
	          UnitPrice ,
	          Image 
	        )
	VALUES  ( @FoodTypeID , -- FoodTypeID - int
	          @FoodName , -- FoodName - nvarchar(max)
	          @UnitPrice , -- UnitPrice - float
	          @Image -- Image - varbinary(max)
	        )
END


GO
/****** Object:  StoredProcedure [dbo].[sp_New_FoodType]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_New_FoodType]
(
@FoodTypeName NVARCHAR(MAX)
)
AS
BEGIN
	INSERT INTO dbo.FoodTypes
	        ( FoodTypeName )
	VALUES  ( @FoodTypeName  -- FoodTypeName - nvarchar(max)
	          )
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Sale_On_Bill]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sale_On_Bill]
(
@BillID INT,
@Percent FLOAT
)
AS
BEGIN
	UPDATE dbo.Bills 
	SET GrandTotal = (SELECT dbo.ft_Charged_GrandTotal(@BillID))* (1.0 - @Percent/100.0)
	WHERE BillID = @BillID
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Update_GrandTotal_On_Bill]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Update_GrandTotal_On_Bill]
	@BillID int
AS
	--Charged sum total
	DECLARE	@GrandTotal FLOAT;
	SELECT @GrandTotal = dbo.ft_Charged_GrandTotal(@BillID)
	
	IF(@GrandTotal IS NULL)
		SET @GrandTotal = 0.0;
	--update GrandTotal

	UPDATE dbo.Bills
		SET GrandTotal = @GrandTotal
	WHERE BillID = @BillID;


GO
/****** Object:  StoredProcedure [dbo].[sp_Update_Total_On_Item]    Script Date: 12/13/2017 1:33:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Update_Total_On_Item]
	@BillID int,
	@FoodID int
AS
	UPDATE dbo.OrderDetails
		SET dbo.OrderDetails.Total = COALESCE((SELECT dbo.ft_Charged_Total(@BillID, @FoodID)), 0.0)
	WHERE BillID = @BillID AND FoodID = @FoodID;
	 
GO
