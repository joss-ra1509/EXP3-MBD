-- BLOQUE C: TRANSACCIONES (FASE 3 FINAL)

USE SistemaVentas_G5;

-- 1. Crear Pedido usando DUI
CREATE PROCEDURE sp_CrearPedido(
    IN p_DUI_Cliente VARCHAR(10),
    OUT p_ID_Pedido INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM Clientes -
        WHERE DUI = p_DUI_Cliente 
          AND ID_Estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cliente no válido.';
    END IF;

    INSERT INTO Pedidos (DUI_Cliente, Total_Venta, ID_Estado)
    VALUES (p_DUI_Cliente, 0, 1);

    SET p_ID_Pedido = LAST_INSERT_ID();
END //

-- 2. Agregar Detalle

CREATE PROCEDURE sp_AgregarDetallePedido(
    IN p_ID_Pedido INT,
    IN p_ID_Producto INT,
    IN p_Cantidad INT
)
BEGIN
    DECLARE v_Precio DECIMAL(10,2);
    DECLARE v_Stock INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_Cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cantidad inválida.';
    END IF;

    SELECT Precio_Venta, Stock_Actual
    INTO v_Precio, v_Stock
    FROM Productos
    WHERE ID_Producto = p_ID_Producto
      AND ID_Estado = 1
    FOR UPDATE;

    IF v_Stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Producto no válido.';
    END IF;

    IF v_Stock < p_Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente.';
    END IF;

    UPDATE Productos
    SET Stock_Actual = Stock_Actual - p_Cantidad
    WHERE ID_Producto = p_ID_Producto;

    INSERT INTO Detalle_Pedido (
        ID_Pedido, ID_Producto, Cantidad,
        Precio_Unitario_Historico, Subtotal, ID_Estado
    )
    VALUES (
        p_ID_Pedido,
        p_ID_Producto,
        p_Cantidad,
        v_Precio,
        v_Precio * p_Cantidad,
        1
    );

    UPDATE Pedidos
    SET Total_Venta = (
        SELECT COALESCE(SUM(Subtotal),0)
        FROM Detalle_Pedido
        WHERE ID_Pedido = p_ID_Pedido
          AND ID_Estado = 1
    )
    WHERE ID_Pedido = p_ID_Pedido;

    COMMIT;
END //


-- 3. Venta completa usando DUI

CREATE PROCEDURE sp_RegistrarVenta(
    IN p_DUI_Cliente VARCHAR(10),
    IN p_ID_Producto INT,
    IN p_Cantidad INT,
    OUT p_ID_Pedido INT
)
BEGIN
    DECLARE v_Precio DECIMAL(10,2);
    DECLARE v_Stock INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 
        FROM Clientes 
        WHERE DUI = p_DUI_Cliente 
          AND ID_Estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cliente no válido.';
    END IF;

    SELECT Precio_Venta, Stock_Actual
    INTO v_Precio, v_Stock
    FROM Productos
    WHERE ID_Producto = p_ID_Producto
      AND ID_Estado = 1
    FOR UPDATE;

    IF v_Stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Producto no válido.';
    END IF;

    IF v_Stock < p_Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente.';
    END IF;

    INSERT INTO Pedidos (DUI_Cliente, Total_Venta, ID_Estado)
    VALUES (p_DUI_Cliente, 0, 1);

    SET p_ID_Pedido = LAST_INSERT_ID();

    UPDATE Productos
    SET Stock_Actual = Stock_Actual - p_Cantidad
    WHERE ID_Producto = p_ID_Producto;

    INSERT INTO Detalle_Pedido (
        ID_Pedido, ID_Producto, Cantidad,
        Precio_Unitario_Historico, Subtotal, ID_Estado
    )
    VALUES (
        p_ID_Pedido,
        p_ID_Producto,
        p_Cantidad,
        v_Precio,
        v_Precio * p_Cantidad,
        1
    );

    UPDATE Pedidos
    SET Total_Venta = v_Precio * p_Cantidad
    WHERE ID_Pedido = p_ID_Pedido;

    COMMIT;
END //

DELIMITER ;