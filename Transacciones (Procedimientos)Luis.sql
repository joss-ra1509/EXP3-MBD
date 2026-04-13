-- =============================================
-- BLOQUE 3: TRAZABILIDAD Y AUDITORÍA
-- Descripción: Scripts para el seguimiento de movimientos y registro de cambios en la base de datos.
-- =============================================

-- PROYECTO: Sistema de Ventas G5
-- BLOQUE C: Transacciones (Procedimientos)
-- Responsable: Luis

USE SistemaVentas_G5;

DELIMITER //

-- 1. Crear pedido maestro

CREATE PROCEDURE sp_CrearPedido(
    IN p_ID_Cliente INT,
    OUT p_ID_Pedido INT
)
BEGIN
    DECLARE v_ExisteCliente INT DEFAULT 0;
    DECLARE v_EstadoCliente INT DEFAULT 0;

    SELECT COUNT(*), COALESCE(MAX(ID_Estado), 0)
      INTO v_ExisteCliente, v_EstadoCliente
    FROM Clientes
    WHERE ID_Cliente = p_ID_Cliente;

    IF v_ExisteCliente = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente no existe.';
    END IF;

    IF v_EstadoCliente <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente se encuentra inactivo.';
    END IF;

    INSERT INTO Pedidos (ID_Cliente, Total_Venta, ID_Estado)
    VALUES (p_ID_Cliente, 0, 1);

    SET p_ID_Pedido = LAST_INSERT_ID();
END //

-- 2. Agregar detalle a un pedido y descontar stock
--    Este procedimiento:
--      - Valida pedido activo
--      - Valida producto activo
--      - Bloquea el producto con FOR UPDATE
--      - Descuenta stock
--      - Inserta detalle
--      - Recalcula total del pedido

CREATE PROCEDURE sp_AgregarDetallePedido(
    IN p_ID_Pedido INT,
    IN p_ID_Producto INT,
    IN p_Cantidad INT
)
BEGIN
    DECLARE v_ExistePedido INT DEFAULT 0;
    DECLARE v_EstadoPedido INT DEFAULT 0;
    DECLARE v_ExisteProducto INT DEFAULT 0;
    DECLARE v_EstadoProducto INT DEFAULT 0;
    DECLARE v_StockActual INT DEFAULT 0;
    DECLARE v_PrecioVenta DECIMAL(10,2) DEFAULT 0;
    DECLARE v_Subtotal DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_Cantidad IS NULL OR p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La cantidad debe ser mayor que cero.';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*), COALESCE(MAX(ID_Estado), 0)
      INTO v_ExistePedido, v_EstadoPedido
    FROM Pedidos
    WHERE ID_Pedido = p_ID_Pedido;

    IF v_ExistePedido = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido no existe.';
    END IF;

    IF v_EstadoPedido <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido no está vigente.';
    END IF;

    SELECT COUNT(*)
      INTO v_ExisteProducto
    FROM Productos
    WHERE ID_Producto = p_ID_Producto;

    IF v_ExisteProducto = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto no existe.';
    END IF;

    SELECT ID_Estado, Stock_Actual, Precio_Venta
      INTO v_EstadoProducto, v_StockActual, v_PrecioVenta
    FROM Productos
    WHERE ID_Producto = p_ID_Producto
    FOR UPDATE;

    IF v_EstadoProducto <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto se encuentra inactivo.';
    END IF;

    IF v_StockActual < p_Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente para completar la venta.';
    END IF;

    SET v_Subtotal = v_PrecioVenta * p_Cantidad;

    UPDATE Productos
       SET Stock_Actual = Stock_Actual - p_Cantidad
     WHERE ID_Producto = p_ID_Producto;

    INSERT INTO Detalle_Pedido (
        ID_Pedido,
        ID_Producto,
        Cantidad,
        Precio_Unitario_Historico,
        Subtotal,
        ID_Estado
    )
    VALUES (
        p_ID_Pedido,
        p_ID_Producto,
        p_Cantidad,
        v_PrecioVenta,
        v_Subtotal,
        1
    );

    UPDATE Pedidos
       SET Total_Venta = (
           SELECT COALESCE(SUM(Subtotal), 0)
           FROM Detalle_Pedido
           WHERE ID_Pedido = p_ID_Pedido
             AND ID_Estado = 1
       )
     WHERE ID_Pedido = p_ID_Pedido;

    COMMIT;
END //


-- 3. Registrar venta completa en una sola transacción
--    Crea el pedido + agrega el detalle + descuenta stock

CREATE PROCEDURE sp_RegistrarVenta(
    IN p_ID_Cliente INT,
    IN p_ID_Producto INT,
    IN p_Cantidad INT,
    OUT p_ID_Pedido INT
)
BEGIN
    DECLARE v_ExisteCliente INT DEFAULT 0;
    DECLARE v_EstadoCliente INT DEFAULT 0;
    DECLARE v_ExisteProducto INT DEFAULT 0;
    DECLARE v_EstadoProducto INT DEFAULT 0;
    DECLARE v_StockActual INT DEFAULT 0;
    DECLARE v_PrecioVenta DECIMAL(10,2) DEFAULT 0;
    DECLARE v_Subtotal DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_Cantidad IS NULL OR p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La cantidad debe ser mayor que cero.';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*), COALESCE(MAX(ID_Estado), 0)
      INTO v_ExisteCliente, v_EstadoCliente
    FROM Clientes
    WHERE ID_Cliente = p_ID_Cliente;

    IF v_ExisteCliente = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente no existe.';
    END IF;

    IF v_EstadoCliente <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente se encuentra inactivo.';
    END IF;

    SELECT COUNT(*)
      INTO v_ExisteProducto
    FROM Productos
    WHERE ID_Producto = p_ID_Producto;

    IF v_ExisteProducto = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto no existe.';
    END IF;

    SELECT ID_Estado, Stock_Actual, Precio_Venta
      INTO v_EstadoProducto, v_StockActual, v_PrecioVenta
    FROM Productos
    WHERE ID_Producto = p_ID_Producto
    FOR UPDATE;

    IF v_EstadoProducto <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto se encuentra inactivo.';
    END IF;

    IF v_StockActual < p_Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente para completar la venta.';
    END IF;

    INSERT INTO Pedidos (ID_Cliente, Total_Venta, ID_Estado)
    VALUES (p_ID_Cliente, 0, 1);

    SET p_ID_Pedido = LAST_INSERT_ID();
    SET v_Subtotal = v_PrecioVenta * p_Cantidad;

    UPDATE Productos
       SET Stock_Actual = Stock_Actual - p_Cantidad
     WHERE ID_Producto = p_ID_Producto;

    INSERT INTO Detalle_Pedido (
        ID_Pedido,
        ID_Producto,
        Cantidad,
        Precio_Unitario_Historico,
        Subtotal,
        ID_Estado
    )
    VALUES (
        p_ID_Pedido,
        p_ID_Producto,
        p_Cantidad,
        v_PrecioVenta,
        v_Subtotal,
        1
    );

    UPDATE Pedidos
       SET Total_Venta = v_Subtotal
     WHERE ID_Pedido = p_ID_Pedido;

    COMMIT;
END //

-- 4. Anular pedido
--    Revierte stock de todos los detalles activos
--    Marca pedido y detalles como inactivos/anulados

CREATE PROCEDURE sp_AnularPedido(
    IN p_ID_Pedido INT
)
BEGIN
    DECLARE v_ExistePedido INT DEFAULT 0;
    DECLARE v_EstadoPedido INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*), COALESCE(MAX(ID_Estado), 0)
      INTO v_ExistePedido, v_EstadoPedido
    FROM Pedidos
    WHERE ID_Pedido = p_ID_Pedido
    FOR UPDATE;

    IF v_ExistePedido = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido no existe.';
    END IF;

    IF v_EstadoPedido = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido ya fue anulado.';
    END IF;

    UPDATE Productos p
    INNER JOIN Detalle_Pedido d
        ON p.ID_Producto = d.ID_Producto
    SET p.Stock_Actual = p.Stock_Actual + d.Cantidad
    WHERE d.ID_Pedido = p_ID_Pedido
      AND d.ID_Estado = 1;

    UPDATE Detalle_Pedido
       SET ID_Estado = 0
     WHERE ID_Pedido = p_ID_Pedido
       AND ID_Estado = 1;

    UPDATE Pedidos
       SET ID_Estado = 0,
           Total_Venta = 0
     WHERE ID_Pedido = p_ID_Pedido;

    COMMIT;
END //

DELIMITER ;


