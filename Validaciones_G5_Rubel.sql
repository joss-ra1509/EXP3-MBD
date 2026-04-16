USE SistemaVentas_G5;
GO

-- Funcion para ver si el DUI esta bien escrito
CREATE FUNCTION fn_ValidarDUI (@p_DUI VARCHAR(10)) 
RETURNS BIT
AS
BEGIN
    DECLARE @esValido BIT;
    -- Formato de 8 numeros, guion y un numero final
    IF @p_DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
        SET @esValido = 1;
    ELSE
        SET @esValido = 0;
    RETURN @esValido;
END;
GO

-- El procedimiento para meter clientes validando el DUI
CREATE PROCEDURE sp_InsertarCliente
    @p_Nombre VARCHAR(150), 
    @p_DUI VARCHAR(10), 
    @p_Email VARCHAR(100)
AS
BEGIN
    -- Primero revisamos el DUI antes de insertar
    IF @p_DUI IS NOT NULL AND @p_DUI <> '' AND dbo.fn_ValidarDUI(@p_DUI) = 0
    BEGIN
        RAISERROR('Error: DUI incorrecto.', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        -- Si esta bien, se guarda. El DUI es nuestro identificador principal
        INSERT INTO Clientes (Nombre_Completo, DUI, Email) 
        VALUES (@p_Nombre, @p_DUI, @p_Email);
    END
END;
GO