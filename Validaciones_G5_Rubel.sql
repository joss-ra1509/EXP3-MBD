USE SistemaVentas_G5;
GO

-- =============================================
-- 1. FUNCIONES DE VALIDACIÓN 
-- =============================================

-- Validar formato de DUI
CREATE OR ALTER FUNCTION fn_ValidarDUI (@p_DUI VARCHAR(10)) 
RETURNS BIT
AS
BEGIN
    DECLARE @esValido BIT;
    IF @p_DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
        SET @esValido = 1;
    ELSE
        SET @esValido = 0;
    RETURN @esValido;
END;
GO

-- Validar Email
CREATE OR ALTER FUNCTION fn_ValidarEmail (@Email VARCHAR(100))
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN @Email LIKE '%_@__%.__%' THEN 1 ELSE 0 END;
END;
GO

-- =============================================
-- 2. PROCEDIMIENTOS ALMACENADOS (Mantenimiento)
-- =============================================

-- Insertar Cliente con validación de DUI
CREATE OR ALTER PROCEDURE sp_InsertarCliente
    @p_Nombre VARCHAR(150), 
    @p_DUI VARCHAR(10), 
    @p_Email VARCHAR(100)
AS
BEGIN
    IF dbo.fn_ValidarDUI(@p_DUI) = 0
    BEGIN
        RAISERROR('Error: El formato del DUI es incorrecto (########-#).', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Clientes WHERE DUI = @p_DUI)
    BEGIN
        RAISERROR('Error: El cliente con este DUI ya existe.', 16, 1);
        RETURN;
    END

    INSERT INTO Clientes (Nombre_Completo, DUI, Email) 
    VALUES (@p_Nombre, @p_DUI, @p_Email);
    PRINT 'Cliente insertado con éxito.';
END;
GO

-- PROCEDIMIENTO DE VENTA (Versión corregida de Ruben + Tu DUI)
CREATE OR ALTER PROCEDURE sp_realizar_venta
    @p_DUI_Cliente VARCHAR(10),
    @p_ID_Producto INT,
    @p_cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_precio DECIMAL(10,2);
    DECLARE @v_total DECIMAL(10,2);
    DECLARE @v_pedido INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar si el cliente existe y está activo
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE DUI = @p_DUI_Cliente AND ID_Estado = 1)
            THROW 50002, 'Cliente no existe o está inactivo', 1;

        -- Obtener precio y validar stock
        SELECT @v_precio = Precio_Venta FROM Productos WHERE ID_Producto = @p_ID_Producto AND ID_Estado = 1;
        
        IF @v_precio IS NULL
            THROW 50003, 'Producto no disponible o no existe', 1;

        IF (SELECT Stock_Actual FROM Productos WHERE ID_Producto = @p_ID_Producto) < @p_cantidad
            THROW 50004, 'Stock insuficiente para realizar la venta', 1;

        SET @v_total = @v_precio * @p_cantidad;

        -- Crear cabecera del pedido
        INSERT INTO Pedidos (DUI_Cliente, Total_Venta, Fecha_Pedido)
        VALUES (@p_DUI_Cliente, @v_total, GETDATE());

        SET @v_pedido = SCOPE_IDENTITY();

        -- Insertar detalle
        INSERT INTO Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario_Historico, Subtotal)
        VALUES (@v_pedido, @p_ID_Producto, @p_cantidad, @v_precio, @v_total);

        -- Descontar Stock (Vital para la consistencia)
        UPDATE Productos 
        SET Stock_Actual = Stock_Actual - @p_cantidad 
        WHERE ID_Producto = @p_ID_Producto;

        COMMIT;
        PRINT 'Venta registrada exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsj NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsj, 16, 1);
    END CATCH
END;
GO