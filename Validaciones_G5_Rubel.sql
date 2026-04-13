-- =============================================
-- BLOQUE B: VALIDACIONES Y ALTAS (ADMINISTRACIÓN)
-- =============================================

DELIMITER //

CREATE FUNCTION fn_ValidarDUI(p_DUI VARCHAR(10)) RETURNS BOOLEAN DETERMINISTIC
BEGIN
    RETURN p_DUI REGEXP '^[0-9]{8}-[0-9]$';
END //

CREATE PROCEDURE sp_InsertarCliente(
    IN p_Nombre VARCHAR(150), IN p_DUI VARCHAR(10), IN p_Email VARCHAR(100)
)
BEGIN
    IF p_DUI IS NOT NULL AND p_DUI <> '' AND fn_ValidarDUI(p_DUI) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: DUI incorrecto.';
    ELSE
        INSERT INTO Clientes (Nombre_Completo, DUI, Email) VALUES (p_Nombre, p_DUI, p_Email);
    END IF;
END //

DELIMITER ;