-- PRUEBA 1 Ver Clientes actuales

USE SistemaVentas_G5;

SELECT ID_Cliente, Nombre_Completo, DUI, Email, ID_Estado
FROM Clientes;

-- Prueba 2 Insertar cliente valido A 

USE SistemaVentas_G5;

CALL sp_InsertarCliente('María Hernández', '99887766-5', 'mariah1@gmail.com');

SELECT ID_Cliente, Nombre_Completo, DUI, Email, ID_Estado
FROM Clientes;

-- Prueba 3  Insertar cliente válido B

USE SistemaVentas_G5;

CALL sp_InsertarCliente('José Castillo', '44556677-8', 'josec1@gmail.com');

SELECT ID_Cliente, Nombre_Completo, DUI, Email, ID_Estado
FROM Clientes;

-- Prueba 4 Insertar cliente con DUI nulo

USE SistemaVentas_G5;

CALL sp_InsertarCliente('Andrea López', NULL, 'andreal1@gmail.com');

SELECT ID_Cliente, Nombre_Completo, DUI, Email, ID_Estado
FROM Clientes;

-- Prueba 5 DUI inválido

USE SistemaVentas_G5;

CALL sp_InsertarCliente('Mario Pérez', '1234-567', 'mariop1@gmail.com');

-- Prueba 6  Insertar productos

USE SistemaVentas_G5;

INSERT INTO Productos (
    Nombre_Producto,
    Precio_Costo,
    Margen_Ganancia,
    Precio_Venta,
    Stock_Actual,
    ID_Estado
)
VALUES 
('Laptop Lenovo', 500.00, 20.00, 600.00, 10, 1),
('Mouse Inalambrico', 8.00, 50.00, 12.00, 50, 1),
('Teclado Mecanico', 25.00, 40.00, 35.00, 15, 1),
('Monitor 24', 120.00, 25.00, 150.00, 5, 0);

SELECT * FROM Productos;

-- Prueba 7 Verificar productos

USE SistemaVentas_G5;

SELECT ID_Producto, Nombre_Producto, Precio_Venta, Stock_Actual, ID_Estado
FROM Productos;

-- Prueba 8 Crear pedido

USE SistemaVentas_G5;

CALL sp_CrearPedido(1, @pedido1);

SELECT @pedido1 AS Pedido_Creado;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;

-- Prueba 9 Agregar primer detalle al pedido

USE SistemaVentas_G5;

CALL sp_AgregarDetallePedido(@pedido1, 1, 2);

SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto = 1;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;

-- Prueba 10 Agregar segundo detalle al mismo pedido

USE SistemaVentas_G5;

CALL sp_AgregarDetallePedido(@pedido1, 2, 3);

SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto IN (1,2);
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;

-- Prueba 11 Venta completa en una sola transacción

USE SistemaVentas_G5;

CALL sp_RegistrarVenta(2, 3, 2, @pedido2);

SELECT @pedido2 AS Pedido_Venta_Completa;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido2;
SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido2;
SELECT * FROM Productos WHERE ID_Producto = 3;

-- Prueba 12 Error por stock insuficiente

USE SistemaVentas_G5;

CALL sp_RegistrarVenta(1, 1, 100, @pedido_error_stock);

-- Prueba 13 Error por cantidad inválida

USE SistemaVentas_G5;

CALL sp_RegistrarVenta(1, 1, 0, @pedido_error_cantidad);

-- Prueba 14  Error por producto inactivo

USE SistemaVentas_G5;

CALL sp_RegistrarVenta(1, 4, 1, @pedido_error_producto);

-- Prueba 15 Inactivar un cliente y probar error

USE SistemaVentas_G5;

UPDATE Clientes
SET ID_Estado = 0
WHERE ID_Cliente = 2;

SELECT * FROM Clientes WHERE ID_Cliente = 2;

-- Comprobar

USE SistemaVentas_G5;

CALL sp_RegistrarVenta(2, 1, 1, @pedido_error_cliente);

-- Prueba 16  Reactivar clienteUSE SistemaVentas_G5;

USE SistemaVentas_G5;

UPDATE Clientes
SET ID_Estado = 1
WHERE ID_Cliente = 2;

SELECT * FROM Clientes WHERE ID_Cliente = 2;

-- Prueba 17 Ver estado antes de anular

USE SistemaVentas_G5;

SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;
SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto IN (1,2);

-- Prueba 18 Anular pedido

USE SistemaVentas_G5;

CALL sp_AnularPedido(@pedido1);

SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;
SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto IN (1,2);

-- Prueba 19 Error por anular pedido ya anulado

USE SistemaVentas_G5;

CALL sp_AnularPedido(@pedido1);

-- Prueba 20 Consultas finales

USE SistemaVentas_G5;

SELECT * FROM Clientes;
SELECT * FROM Productos;
SELECT * FROM Pedidos;
SELECT * FROM Detalle_Pedido;