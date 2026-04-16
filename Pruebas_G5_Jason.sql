USE SistemaVentas_G5;
GO

-- =============================================
-- SECCIÓN 1: CLIENTES (Pruebas 1 a 5)
-- =============================================

-- PRUEBA 1: Ver Clientes actuales
SELECT DUI, Nombre_Completo, Email, ID_Estado FROM Clientes;

-- PRUEBA 2: Insertar cliente válido A
EXEC sp_InsertarCliente 'María Hernández', '99887766-5', 'mariah1@gmail.com';
SELECT DUI, Nombre_Completo, Email, ID_Estado FROM Clientes;

-- PRUEBA 3: Insertar cliente válido B
EXEC sp_InsertarCliente 'José Castillo', '44556677-8', 'josec1@gmail.com';
SELECT DUI, Nombre_Completo, Email, ID_Estado FROM Clientes;

-- PRUEBA 4: Insertar cliente con DUI nulo (Dará error por ser Primary Key)
-- Captura el mensaje de error de SQL Server
EXEC sp_InsertarCliente 'Andrea López', NULL, 'andreal1@gmail.com';

-- PRUEBA 5: DUI inválido (Validación de Rubel)
-- Captura el mensaje de error rojo: "Error: DUI incorrecto"
EXEC sp_InsertarCliente 'Mario Pérez', '1234-567', 'mariop1@gmail.com';


-- =============================================
-- SECCIÓN 2: PRODUCTOS (Pruebas 6 a 7)
-- =============================================

-- PRUEBA 6: Insertar productos
INSERT INTO Productos (Nombre_Producto, Precio_Costo, Margen_Ganancia, Precio_Venta, Stock_Actual, ID_Estado)
VALUES 
('Laptop Lenovo', 500.00, 20.00, 600.00, 10, 1),
('Mouse Inalambrico', 8.00, 50.00, 12.00, 50, 1),
('Teclado Mecanico', 25.00, 40.00, 35.00, 15, 1),
('Monitor 24', 120.00, 25.00, 150.00, 5, 0);

-- PRUEBA 7: Verificar productos
SELECT ID_Producto, Nombre_Producto, Precio_Venta, Stock_Actual, ID_Estado FROM Productos;


-- =============================================
-- SECCIÓN 3: VENTAS Y LÓGICA (Pruebas 8 a 14)
-- =============================================

-- PRUEBA 8: Crear pedido
DECLARE @pedido1 INT;
EXEC sp_CrearPedido '99887766-5', @p_ID_Pedido = @pedido1 OUTPUT;
SELECT @pedido1 AS Pedido_Creado;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;

-- PRUEBA 9: Agregar primer detalle al pedido
EXEC sp_AgregarDetallePedido @pedido1, 1, 2; -- 2 Laptops
SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;

-- PRUEBA 10: Agregar segundo detalle al mismo pedido
EXEC sp_AgregarDetallePedido @pedido1, 2, 3; -- 3 Mouses
SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;

-- PRUEBA 11: Venta completa (Simulada creando otro pedido)
DECLARE @pedido2 INT;
EXEC sp_CrearPedido '44556677-8', @p_ID_Pedido = @pedido2 OUTPUT;
EXEC sp_AgregarDetallePedido @pedido2, 3, 1;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido2;

-- PRUEBA 12: Error por stock insuficiente
EXEC sp_AgregarDetallePedido @pedido2, 1, 100; 

-- PRUEBA 13: Error por cantidad inválida (0 o negativo)
EXEC sp_AgregarDetallePedido @pedido2, 1, 0;

-- PRUEBA 14: Error por producto inactivo (Monitor 24 tiene estado 0)
EXEC sp_AgregarDetallePedido @pedido2, 4, 1;


-- =============================================
-- SECCIÓN 4: ESTADOS Y ANULACIÓN (Pruebas 15 a 20)
-- =============================================

-- PRUEBA 15: Inactivar un cliente y probar error
UPDATE Clientes SET ID_Estado = 0 WHERE DUI = '44556677-8';
SELECT * FROM Clientes WHERE DUI = '44556677-8';

-- PRUEBA 16: Reactivar cliente
UPDATE Clientes SET ID_Estado = 1 WHERE DUI = '44556677-8';
SELECT * FROM Clientes WHERE DUI = '44556677-8';

-- PRUEBA 17: Ver estado antes de anular
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto IN (1, 2);

-- PRUEBA 18: Anular pedido (Devuelve el stock)
EXEC sp_AnularPedido @pedido1;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1; -- Debería decir Anulado

-- PRUEBA 19: Error por anular pedido ya anulado
EXEC sp_AnularPedido @pedido1;

-- PRUEBA 20: Consultas finales
SELECT * FROM Clientes;
SELECT * FROM Productos;
SELECT * FROM Pedidos;
SELECT * FROM Detalle_Pedido;
