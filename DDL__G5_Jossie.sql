USE master;
GO

-- =============================================
-- 1. LIMPIEZA DEL ENTORNO
-- =============================================
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

-- =============================================
-- 2. DEFINICIÓN DE TABLAS (DDL)
-- =============================================

-- Tabla Clientes: Maneja la integridad de identidad mediante el DUI
CREATE TABLE Clientes (
    DUI VARCHAR(10) PRIMARY KEY, 
    Nombre_Completo VARCHAR(150) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Email_Marketing BIT DEFAULT 1,
    Limite_Credito DECIMAL(10,2) DEFAULT 0,
    ID_Estado INT DEFAULT 1,
    CONSTRAINT chk_DUI_Formato CHECK (DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
    CONSTRAINT chk_Estado_Cliente CHECK (ID_Estado IN (0, 1))
);

-- Tabla Productos: Control de inventario y precios
CREATE TABLE Productos (
    ID_Producto INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Producto VARCHAR(100) NOT NULL,
    Precio_Costo DECIMAL(10,2) NOT NULL,
    Margen_Ganancia DECIMAL(5,2) NOT NULL, 
    Precio_Venta DECIMAL(10,2) NOT NULL, 
    Stock_Actual INT NOT NULL DEFAULT 0,
    ID_Estado INT DEFAULT 1,
    CONSTRAINT chk_Estado_Producto CHECK (ID_Estado IN (0, 1))
);

-- Tabla Pedidos (Maestro): Cabecera de la transacción
CREATE TABLE Pedidos (
    ID_Pedido INT PRIMARY KEY IDENTITY(1,1),
    DUI_Cliente VARCHAR(10) NOT NULL, 
    Fecha_Pedido DATETIME DEFAULT GETDATE(),
    Total_Venta DECIMAL(10,2) DEFAULT 0,
    ID_Estado INT DEFAULT 1,
    CONSTRAINT fk_cliente_pedido FOREIGN KEY (DUI_Cliente) REFERENCES Clientes(DUI)
);

-- Tabla Detalle_Pedido: Relación de muchos a muchos con integridad referencial
CREATE TABLE Detalle_Pedido (
    ID_Detalle INT PRIMARY KEY IDENTITY(1,1),
    ID_Pedido INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    Precio_Unitario_Historico DECIMAL(10,2) NOT NULL, 
    Subtotal DECIMAL(10,2) NOT NULL, 
    ID_Estado INT DEFAULT 1,
    CONSTRAINT fk_maestro_pedido FOREIGN KEY (ID_Pedido) REFERENCES Pedidos(ID_Pedido),
    CONSTRAINT fk_producto_detalle FOREIGN KEY (ID_Producto) REFERENCES Productos(ID_Producto)
);
GO