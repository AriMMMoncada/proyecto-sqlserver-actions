USE EmpresaDB;
GO

INSERT INTO Ventas(Producto,Cantidad) VALUES('Laptop',3);
INSERT INTO Ventas(Producto,Cantidad) VALUES('Monitor',5);

-- Prueba de inserción múltiple (reto principal)
INSERT INTO Ventas(Producto,Cantidad)
VALUES('Laptop',1),('Monitor',2),('Laptop',4);
GO

SELECT * FROM Ventas;
SELECT * FROM AuditoriaVentas;
SELECT * FROM Inventario;
GO