USE SistemaVentas_G5;
GO

-- 1. Limpiamos todo para que no haya basura de pruebas anteriores
DELETE FROM Detalle_Pedido;
DELETE FROM Pedidos;
DELETE FROM Productos;
DELETE FROM Clientes;
GO

-- 2. Insertamos al cliente 
EXEC sp_InsertarCliente 'Yoselyn Aguilar', '01234567-8', 'yose@ejemplo.com';

-- 3. Insertamos los productos PRIMERO (Importante para que tengan ID 1 y 2)
SET IDENTITY_INSERT Productos ON; -- Esto es para forzar los IDs y que no fallen las pruebas
INSERT INTO Productos (ID_Producto, Nombre_Producto, Precio_Costo, Margen_Ganancia, Precio_Venta, Stock_Actual)
VALUES 
(1, 'Laptop Lenovo', 500.00, 20.00, 600.00, 10),
(2, 'Mouse Inalambrico', 8.00, 50.00, 12.00, 50);
SET IDENTITY_INSERT Productos OFF;

-- 4. Ahora si, hacemos la venta (Luis)
DECLARE @id_pedido_final INT;
EXEC sp_CrearPedido '01234567-8', @p_ID_Pedido = @id_pedido_final OUTPUT;

-- Vendemos 2 Mouses (que es el ID 2)
EXEC sp_AgregarDetallePedido @id_pedido_final, 2, 2;

-- 5. Consultas para las capturas
SELECT * FROM Clientes;
SELECT * FROM Productos; -- Deberia decir 48 en el stock del mouse
SELECT * FROM Pedidos;
SELECT * FROM Detalle_Pedido;