USE SistemaVentas_G5;
GO

-- 1. Crear el pedido maestro (CORREGIDO)
CREATE OR ALTER PROCEDURE sp_CrearPedido
    @p_DUI_Cliente VARCHAR(10),
    @p_ID_Pedido INT OUTPUT
AS
BEGIN
    -- Validamos que el cliente exista y use la columna DUI
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE DUI = @p_p_DUI_Cliente AND ID_Estado = 1)
    BEGIN
        RAISERROR('Error: El cliente no existe o esta inactivo.', 16, 1);
        RETURN;
    END

    -- CAMBIO AQUÍ: Usamos DUI_Cliente en lugar de Id_Cliente
    INSERT INTO Pedidos (DUI_Cliente, Total_Venta, ID_Estado)
    VALUES (@p_DUI_Cliente, 0, 1);

    SET @p_ID_Pedido = SCOPE_IDENTITY();
END;
GO

-- 2. Agregar productos (CORREGIDO)
CREATE OR ALTER PROCEDURE sp_AgregarDetallePedido
    @p_ID_Pedido INT,
    @p_ID_Producto INT,
    @p_Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @v_PrecioVenta DECIMAL(10,2), @v_StockActual INT;

        SELECT @v_PrecioVenta = Precio_Venta, @v_StockActual = Stock_Actual 
        FROM Productos WHERE ID_Producto = @p_ID_Producto;

        IF @v_StockActual < @p_Cantidad
        BEGIN
            RAISERROR('Error: No hay suficiente stock.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Productos 
        SET Stock_Actual = Stock_Actual - @p_Cantidad 
        WHERE ID_Producto = @p_ID_Producto;

        INSERT INTO Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario_Historico, Subtotal, ID_Estado)
        VALUES (@p_ID_Pedido, @p_ID_Producto, @p_Cantidad, @v_PrecioVenta, (@v_PrecioVenta * @p_Cantidad), 1);

        -- Recalculamos el total
        UPDATE Pedidos 
        SET Total_Venta = (SELECT SUM(Subtotal) FROM Detalle_Pedido WHERE ID_Pedido = @p_ID_Pedido AND ID_Estado = 1)
        WHERE ID_Pedido = @p_ID_Pedido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO