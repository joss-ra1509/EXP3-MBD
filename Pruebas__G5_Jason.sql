USE SistemaVentas_G5;
GO

CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @ID_Cliente INT, 
    @ID_Producto INT, 
    @Cantidad INT, 
    @ID_Venta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; -- Ayuda a evitar mensajes extraños en la consola

    -- 1. Validar Stock
    DECLARE @StockActual INT;
    SELECT @StockActual = Stock_Actual FROM Productos WHERE ID_Producto = @ID_Producto;

    IF @StockActual < @Cantidad
    BEGIN
        RAISERROR('Error: Stock insuficiente para realizar la venta.', 16, 1);
        RETURN;
    END

    -- 2. Crear el encabezado del Pedido/Venta
    INSERT INTO Pedidos (ID_Cliente, Fecha, Total, ID_Estado)
    VALUES (@ID_Cliente, GETDATE(), 0, 1);

    -- Capturar el ID generado
    SET @ID_Venta = SCOPE_IDENTITY();

    -- 3. Insertar el Detalle 
    INSERT INTO Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Subtotal)
    VALUES (@ID_Venta, @ID_Producto, @Cantidad, 0); 

    -- 4. Actualizar el Stock
    UPDATE Productos 
    SET Stock_Actual = Stock_Actual - @Cantidad 
    WHERE ID_Producto = @ID_Producto;

    PRINT 'Venta registrada con éxito. ID: ' + CAST(@ID_Venta AS VARCHAR(10));
END;
GO