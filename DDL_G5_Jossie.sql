-- PROYECTO: Sistema de Ventas G5
-- BLOQUE A: Estructura DDL (Cimiento del Sistema)
-- Responsable: Jossie

DROP DATABASE IF EXISTS SistemaVentas_G5;
CREATE DATABASE SistemaVentas_G5;
USE SistemaVentas_G5;

-- Tabla de Clientes: Incluye campos de la Exp 2 para Marketing y Crédito
CREATE TABLE Clientes (
    Id_Cliente INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_Completo VARCHAR(150) NOT NULL,
    DUI VARCHAR(10) UNIQUE NULL, 
    Email VARCHAR(100) UNIQUE,
    Email_Marketing BOOLEAN DEFAULT TRUE, 
    Limite_Credito DECIMAL(10,2) DEFAULT 0 CHECK (Limite_Credito >= 0),
    ID_Estado INT DEFAULT 1 CHECK (ID_Estado IN (0, 1))
);

-- Tabla de Productos: Con control de costos y margen de ganancia
CREATE TABLE Productos (
    ID_Producto INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_Producto VARCHAR(100) NOT NULL,
    Precio_Costo DECIMAL(10,2) NOT NULL CHECK (Precio_Costo >= 0),
    Margen_Ganancia DECIMAL(5,2) NOT NULL, 
    Precio_Venta DECIMAL(10,2) NOT NULL CHECK (Precio_Venta > 0), 
    Stock_Actual INT NOT NULL DEFAULT 0 CHECK (Stock_Actual >= 0),
    ID_Estado INT DEFAULT 1 CHECK (ID_Estado IN (0, 1))
);

-- 3. TABLA PEDIDOS (Maestro)
CREATE TABLE Pedidos (
    ID_Pedido INT PRIMARY KEY AUTO_INCREMENT,
    ID_Cliente INT NOT NULL,
    Fecha_Pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    Total_Venta DECIMAL(10,2) DEFAULT 0 CHECK (Total_Venta >= 0),
    ID_Estado INT DEFAULT 1 CHECK (ID_Estado IN (0, 1)), -- 1: Vigente, 0: Anulado
    CONSTRAINT fk_cliente_pedido FOREIGN KEY (ID_Cliente) 
        REFERENCES Clientes(ID_Cliente)
);

-- 4. TABLA DETALLE_PEDIDO (Detalle)
CREATE TABLE Detalle_Pedido (
    ID_Detalle INT PRIMARY KEY AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    Precio_Unitario_Historico DECIMAL(10,2) NOT NULL, 
    Subtotal DECIMAL(10,2) NOT NULL, 
    ID_Estado INT DEFAULT 1 CHECK (ID_Estado IN (0, 1)), -- Para anular líneas específicas
    CONSTRAINT fk_maestro_pedido FOREIGN KEY (ID_Pedido) 
        REFERENCES Pedidos(ID_Pedido),
    CONSTRAINT fk_producto_detalle FOREIGN KEY (ID_Producto) 
        REFERENCES Productos(ID_Producto)
);