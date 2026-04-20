/* SISTEMA DE VENTAS G5 - SQL SERVER VERSION
   Ajustado por: Jossie Aguilar
*/

USE SistemaVentas_G5;
GO

-- PRUEBA 1: Ver Clientes actuales
SELECT ID_Cliente, Nombre_Completo, DUI, Email, ID_Estado
FROM Clientes;

-- Prueba 2 & 3: Insertar clientes válidos
-- Nota: En SQL Server usamos EXEC
EXEC sp_InsertarCliente 'María Hernández', '99887766-5', 'mariah1@gmail.com';
EXEC sp_InsertarCliente 'José Castillo', '44556677-8', 'josec1@gmail.com';

SELECT * FROM Clientes;

-- Prueba 4 & 5: Pruebas de errores (DUI nulo o inválido)
EXEC sp_InsertarCliente 'Andrea López', NULL, 'andreal1@gmail.com';
EXEC sp_InsertarCliente 'Mario Pérez', '1234-567', 'mariop1@gmail.com';

-- Prueba 6: Insertar productos (Sin los paréntesis de MySQL en VALUES múltiples)
INSERT INTO Productos (Nombre_Producto, Precio_Costo, Margen_Ganancia, Precio_Venta, Stock_Actual, ID_Estado)
VALUES 
('Laptop Lenovo', 500.00, 20.00, 600.00, 10, 1),
('Mouse Inalambrico', 8.00, 50.00, 12.00, 50, 1),
('Teclado Mecanico', 25.00, 40.00, 35.00, 15, 1),
('Monitor 24', 120.00, 25.00, 150.00, 5, 0);

-- Prueba 7: Verificar productos
SELECT ID_Producto, Nombre_Producto, Precio_Venta, Stock_Actual, ID_Estado
FROM Productos;

-- Prueba 8: Crear pedido 
-- En SQL Server declaramos la variable para recibir el ID
DECLARE @pedido1 INT;
EXEC sp_CrearPedido 1, @pedido1 OUTPUT; -- Se usa OUTPUT para capturar el valor

SELECT @pedido1 AS Pedido_Creado;
SELECT * FROM Pedidos WHERE ID_Pedido = @pedido1;

-- Prueba 9 & 10: Agregar detalles al pedido
EXEC sp_AgregarDetallePedido @pedido1, 1, 2;
EXEC sp_AgregarDetallePedido @pedido1, 2, 3;

SELECT * FROM Detalle_Pedido WHERE ID_Pedido = @pedido1;
SELECT * FROM Productos WHERE ID_Producto IN (1,2);

-- Prueba 11: Venta completa (Transacción)
DECLARE @pedido2 INT;
EXEC sp_RegistrarVenta 2, 3, 2, @pedido2 OUTPUT;

SELECT @pedido2 AS Pedido_Venta_Completa;

-- Prueba 12, 13 & 14: Pruebas de error (Stock, Cantidad, Inactivo)
-- Estas deberían disparar el RAISERROR o THROW de tus procedimientos
EXEC sp_RegistrarVenta 1, 1, 100, NULL; -- Error Stock
EXEC sp_RegistrarVenta 1, 1, 0, NULL;   -- Error Cantidad
EXEC sp_RegistrarVenta 1, 4, 1, NULL;   -- Error Producto Inactivo

-- Prueba 15 & 16: Inactivar y Reactivar cliente
UPDATE Clientes SET ID_Estado = 0 WHERE ID_Cliente = 2;
-- Esto debería fallar si intentas venderle:
EXEC sp_RegistrarVenta 2, 1, 1, NULL; 

UPDATE Clientes SET ID_Estado = 1 WHERE ID_Cliente = 2;

-- Prueba 18 & 19: Anular pedido
EXEC sp_AnularPedido @pedido1;
-- Segunda anulación (debe dar error)
EXEC sp_AnularPedido @pedido1;

-- Prueba 20: Consultas finales
SELECT * FROM Clientes;
SELECT * FROM Productos;
SELECT * FROM Pedidos;
SELECT * FROM Detalle_Pedido;