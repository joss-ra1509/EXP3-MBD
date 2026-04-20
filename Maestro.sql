USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SistemaVentas_G5')
BEGIN
    ALTER DATABASE SistemaVentas_G5 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SistemaVentas_G5;
END
GO
CREATE DATABASE SistemaVentas_G5;
GO
USE SistemaVentas_G5;
GO


CREATE TABLE Clientes (
    DUI VARCHAR(10) PRIMARY KEY,
    Nombre_Completo VARCHAR(150) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    ID_Estado INT DEFAULT 1
);

CREATE TABLE Productos (
    ID_Producto INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Producto VARCHAR(100) NOT NULL,
    Precio_Costo DECIMAL(10,2) NOT NULL,    
    Margen_Ganancia DECIMAL(5,2) NOT NULL,   
    Precio_Venta DECIMAL(10,2) NOT NULL,
    Stock_Actual INT NOT NULL DEFAULT 0,
    ID_Estado INT DEFAULT 1
);

CREATE TABLE Pedidos (
    ID_Pedido INT PRIMARY KEY IDENTITY(1,1),
    DUI_Cliente VARCHAR(10) NOT NULL,
    Total_Venta DECIMAL(10,2) DEFAULT 0,
    ID_Estado INT DEFAULT 1,
    FOREIGN KEY (DUI_Cliente) REFERENCES Clientes(DUI)
);

CREATE TABLE Detalle_Pedido (
    ID_Detalle INT PRIMARY KEY IDENTITY(1,1),
    ID_Pedido INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad INT NOT NULL,
    Precio_Unitario_Historico DECIMAL(10,2) NOT NULL,
    Subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (ID_Pedido) REFERENCES Pedidos(ID_Pedido)
);
GO

-- 2. PROCEDIMIENTO DE VENTA (Transacción real)
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @p_DUI_Cliente VARCHAR(10), @p_ID_Producto INT, @p_Cantidad INT
AS
BEGIN
    DECLARE @v_precio DECIMAL(10,2), @v_pedidoID INT;
    SELECT @v_precio = Precio_Venta FROM Productos WHERE ID_Producto = @p_ID_Producto;

    INSERT INTO Pedidos (DUI_Cliente, Total_Venta) VALUES (@p_DUI_Cliente, (@v_precio * @p_Cantidad));
    SET @v_pedidoID = SCOPE_IDENTITY();

    INSERT INTO Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario_Historico, Subtotal)
    VALUES (@v_pedidoID, @p_ID_Producto, @p_Cantidad, @v_precio, (@v_precio * @p_Cantidad));

    UPDATE Productos SET Stock_Actual = Stock_Actual - @p_Cantidad WHERE ID_Producto = @p_ID_Producto;
END;
GO

--Pruebas--
INSERT INTO Productos (Nombre_Producto, Precio_Costo, Margen_Ganancia, Precio_Venta, Stock_Actual)
VALUES ('Laptop Gaming', 800.00, 25.00, 1000.00, 10);

INSERT INTO Clientes (Nombre_Completo, DUI, Email) 
VALUES ('Jossie Perez', '12345678-9', 'jossie@educacion.com');

EXEC sp_RegistrarVenta '12345678-9', 1, 1;

-- VER RESULTADOS
SELECT * FROM Productos;
SELECT * FROM Pedidos;
SELECT * FROM Detalle_Pedido;