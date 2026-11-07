USE EmpresaDB;
GO

CREATE PROCEDURE sp_RegistrarAuditoria
 @VentaID INT
AS
BEGIN
 SET NOCOUNT ON;

 INSERT INTO AuditoriaVentas(VentaID, Mensaje)
 VALUES(@VentaID, 'Venta registrada automáticamente');

 -- Reto avanzado: descontar inventario
 UPDATE i
 SET i.Existencias = i.Existencias - v.Cantidad
 FROM Inventario i
 JOIN Ventas v ON v.Producto = i.Producto
 WHERE v.VentaID = @VentaID;
END;
GO