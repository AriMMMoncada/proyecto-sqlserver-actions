USE EmpresaDB;
GO

CREATE TRIGGER trg_AuditarVenta
ON Ventas
AFTER INSERT
AS
BEGIN
 SET NOCOUNT ON;

 -- Una sola operación para TODAS las filas insertadas
 INSERT INTO AuditoriaVentas(VentaID, Mensaje)
 SELECT VentaID, 'Venta registrada automáticamente'
 FROM inserted;

 -- Reto avanzado: descontar inventario por conjunto
 UPDATE i
 SET i.Existencias = i.Existencias - v.TotalVendido
 FROM Inventario i
 JOIN (SELECT Producto, SUM(Cantidad) AS TotalVendido
       FROM inserted GROUP BY Producto) v
   ON v.Producto = i.Producto;
END;
GO