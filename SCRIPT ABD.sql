-- Generado por Oracle SQL Developer Data Modeler 24.3.1.351.0831
--   en:        2025-03-26 17:51:09 CET
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

-- CREAMOS EL USUARIO PARA PLYTIX
CREATE USER PLYTIX IDENTIFIED BY PLYTIX123
    DEFAULT TABLESPACE TS_PLYTIX
    QUOTA 2G ON TS_PLYTIX
    QUOTA 1G ON TS_INDICES;

ALTER USER PLYTIX ACCOUNT LOCK; -- LOS USUARIOS PROPIETARIOS DE LOS ESQUEMAS ES MUY COMÚN DESACTIVARLOS

GRANT DBA TO PLYTIX;

ALTER SESSION SET CURRENT_SCHEMA = PLYTIX; -- CUANDO HAGA UN CREATE TABLE SIN ESTAR ESPECIFICADO SE LOS DOY A PLYTIX.
-- Generado por Oracle SQL Developer Data Modeler 24.3.1.351.0831
--   en:        2025-03-27 14:10:29 CET
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE


-- SCRIPT PARA BORRAR LAS TABLAS

DROP TABLE REL_ACTIV_CATEGACT CASCADE CONSTRAINTS;
DROP TABLE REL_PROD_ACTIV CASCADE CONSTRAINTS;
DROP TABLE REL_PROD_CATEG CASCADE CONSTRAINTS;
DROP TABLE RELACIONADO CASCADE CONSTRAINTS;
DROP TABLE USUARIO CASCADE CONSTRAINTS;
DROP TABLE PRODUCTO CASCADE CONSTRAINTS;
DROP TABLE PLAN CASCADE CONSTRAINTS;
DROP TABLE CUENTA CASCADE CONSTRAINTS;
DROP TABLE CATEGORIA_ACTIVOS CASCADE CONSTRAINTS;
DROP TABLE CATEGORIA CASCADE CONSTRAINTS;
DROP TABLE ATRIBUTOS_PRODUCTO CASCADE CONSTRAINTS;
DROP TABLE ATRIBUTO CASCADE CONSTRAINTS;
DROP TABLE ACTIVO CASCADE CONSTRAINTS;

-- 1) CREACION DE USUARIO Y TABLESPACE

-- YA TENEMOS EL USUARIO PLYTIX CON EL TABLESPACE TS_PLYTIX

-- CREAMOS EL TABLESPACE PARA LOS INDICES

CREATE TABLESPACE TS_INDICES
DATAFILE 'ts_indices.dbf' SIZE 50M AUTOEXTEND ON;

-- LE ASIGNAMOS QUOTA A PLYTIX PARA ESE TABLESPACE

ALTER USER PLYTIX QUOTA UNLIMITED ON TS_INDICES;

-- COMPROBAMOS AL DICCIONARIO QUE EXISTEN LOS TABLESPACE
SELECT TABLESPACE_NAME, BYTES, MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = 'PLYTIX';

-- 2) CREACIÓN DEL ESQUEMA

CREATE TABLE Activo 
    ( 
     Id        INTEGER  NOT NULL , 
     Nombre    VARCHAR2 (100 CHAR)  NOT NULL , 
     Tamano    INTEGER  NOT NULL , 
     Tipo      VARCHAR2 (100 CHAR) , 
     URL       VARCHAR2 (200 CHAR) , 
     Cuenta_Id INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Activo 
    ADD CONSTRAINT Activo_PK PRIMARY KEY ( Id, Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE Atributo 
    ( 
     Id     INTEGER  NOT NULL , 
     Nombre VARCHAR2 (100 CHAR)  NOT NULL , 
     Tipo   VARCHAR2 (50 CHAR) , 
     Creado DATE  NOT NULL,
     Cuenta_Id INTEGER NOT NULL 
    ) 
;

ALTER TABLE Atributo 
    ADD CONSTRAINT Atributo_PK PRIMARY KEY ( Id, Cuenta_Id)  USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE Atributos_Producto 
    ( 
     Valor              VARCHAR2 (100 CHAR)  NOT NULL , 
     Producto_GTIN      INTEGER  NOT NULL , 
     Atributo_Id        INTEGER  NOT NULL , 
     Producto_Cuenta_Id INTEGER  NOT NULL
    ) 
;

ALTER TABLE Atributos_Producto 
    ADD CONSTRAINT Atributos_Producto_PK PRIMARY KEY ( Producto_GTIN, Producto_Cuenta_Id, Atributo_Id )  USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE Categoria 
    ( 
     Id        INTEGER  NOT NULL , 
     Nombre    VARCHAR2 (100 CHAR)  NOT NULL , 
     Cuenta_Id INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Categoria 
    ADD CONSTRAINT Categoria_PK PRIMARY KEY ( Id, Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE Categoria_Activos 
    ( 
     Id        INTEGER  NOT NULL , 
     Nombre    VARCHAR2 (100 CHAR)  NOT NULL , 
     Cuenta_Id INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Categoria_Activos 
    ADD CONSTRAINT Categoria_Activos_PK PRIMARY KEY ( Id, Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Cuenta 
    ( 
     Id                INTEGER  NOT NULL , 
     Nombre            VARCHAR2 (100 CHAR)  NOT NULL , 
     DirecciónFiscal   VARCHAR2 (200 CHAR)  NOT NULL , 
     NIF               VARCHAR2 (50 CHAR)  NOT NULL , 
     FechaAlta         DATE NOT NULL, 
     Plan_Id           INTEGER  NOT NULL , 
     Usuario_Cuenta_Id INTEGER , 
     Usuario_Id        INTEGER 
    ) 
;
CREATE UNIQUE INDEX Cuenta__IDX ON Cuenta 
    ( 
     Usuario_Id ASC 
    )
    TABLESPACE TS_INDICES 
;

ALTER TABLE Cuenta 
    ADD CONSTRAINT Cuenta_PK PRIMARY KEY ( Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Plan 
    ( 
     Id                 INTEGER  NOT NULL , 
     Productos          VARCHAR2 (100 CHAR)  NOT NULL , 
     Activos            VARCHAR2 (100 CHAR)  NOT NULL , 
     Almacenamiento     VARCHAR2 (100 CHAR)  NOT NULL , 
     CategoriasProducto VARCHAR2 (100 CHAR)  NOT NULL , 
     CategoriasActivos  VARCHAR2 (100 CHAR)  NOT NULL , 
     Relaciones         VARCHAR2 (100 CHAR)  NOT NULL , 
     PrecioAnual        VARCHAR2 (50 CHAR)  NOT NULL , 
     Nombre             VARCHAR2 (100 CHAR)  NOT NULL 
    ) 
;

ALTER TABLE Plan 
    ADD CONSTRAINT Plan_PK PRIMARY KEY ( Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Producto 
    ( 
     GTIN       INTEGER  NOT NULL , 
     SKU        VARCHAR2 (100 CHAR)  NOT NULL , 
     Nombre     VARCHAR2 (100 CHAR)  NOT NULL , 
     Miniatura  VARCHAR2 (300 CHAR) , 
     TextoCorto VARCHAR2 (300 CHAR) , 
     Creado     DATE  NOT NULL , 
     Modificado DATE , 
     Cuenta_Id  INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Producto 
    ADD CONSTRAINT Producto_PK PRIMARY KEY ( GTIN, Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Rel_Activ_CategAct 
    ( 
     Activo_Id                   INTEGER  NOT NULL , 
     Activo_Cuenta_Id            INTEGER  NOT NULL , 
     Categoria_Activos_Id        INTEGER  NOT NULL , 
     Categoria_Activos_Cuenta_Id INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Rel_Activ_CategAct 
    ADD CONSTRAINT Rel_Activ_CategAct_PK PRIMARY KEY ( Activo_Id, Activo_Cuenta_Id, Categoria_Activos_Id, Categoria_Activos_Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Rel_Prod_Activ 
    ( 
     Activo_Id          INTEGER  NOT NULL , 
     Activo_Cuenta_Id   INTEGER  NOT NULL , 
     Producto_GTIN      INTEGER  NOT NULL , 
     Producto_Cuenta_Id INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Rel_Prod_Activ 
    ADD CONSTRAINT Rel_Prod_Activ_PK PRIMARY KEY ( Activo_Id, Activo_Cuenta_Id, Producto_GTIN, Producto_Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Rel_Prod_Categ 
    ( 
     Categoria_Id        INTEGER  NOT NULL , 
     Categoria_Cuenta_Id INTEGER  NOT NULL , 
     Producto_GTIN       INTEGER  NOT NULL , 
     Producto_Cuenta_Id  INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Rel_Prod_Categ 
    ADD CONSTRAINT Rel_Prod_Categ_PK PRIMARY KEY ( Categoria_Id, Categoria_Cuenta_Id, Producto_GTIN, Producto_Cuenta_Id )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Relacionado 
    ( 
     Nombre              VARCHAR2 (100 CHAR)  NOT NULL , 
     Sentido             VARCHAR2 (100 CHAR) , 
     Producto_GTIN       INTEGER  NOT NULL , 
     Producto_GTIN1      INTEGER  NOT NULL , 
     Producto_Cuenta_Id  INTEGER  NOT NULL , 
     Producto_Cuenta_Id1 INTEGER  NOT NULL 
    ) 
;

ALTER TABLE Relacionado 
    ADD CONSTRAINT Relacionado_PK PRIMARY KEY ( Producto_GTIN, Producto_Cuenta_Id, Producto_GTIN1, Producto_Cuenta_Id1 )  USING INDEX TABLESPACE TS_INDICES ;

CREATE TABLE Usuario 
    ( 
     Id                INTEGER  NOT NULL , 
     NombreUsuario     VARCHAR2 (100 CHAR)  NOT NULL , 
     NombreCompleto    VARCHAR2 (100 CHAR)  NOT NULL , 
     Avatar            VARCHAR2 (200 CHAR) , 
     CorreoElectronico VARCHAR2 (150 CHAR) ENCRYPT, 
     Telefono          INTEGER ENCRYPT, 
     Cuenta_Id         INTEGER  NOT NULL , 
     Cuenta_Dueno        INTEGER 
    ) 
;
CREATE UNIQUE INDEX Usuario__IDX ON Usuario 
    ( 
     Cuenta_Dueno   ASC 
    ) 
    TABLESPACE TS_INDICES
;

ALTER TABLE Usuario 
    ADD CONSTRAINT Usuario_PK PRIMARY KEY ( Id )  USING INDEX TABLESPACE TS_INDICES ;

ALTER TABLE Activo 
    ADD CONSTRAINT Activo_Cuenta_FK FOREIGN KEY 
    ( 
     Cuenta_Id
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;

ALTER TABLE Atributos_Producto 
    ADD CONSTRAINT Atributos_Producto_Atributo_FK FOREIGN KEY 
    ( 
     Atributo_Id,
     Producto_Cuenta_Id
    ) 
    REFERENCES Atributo 
    ( 
     Id,
     Cuenta_Id
    ) 
;

ALTER TABLE Atributos_Producto 
    ADD CONSTRAINT Atributos_Producto_Producto_FK FOREIGN KEY 
    ( 
     Producto_GTIN,
     Producto_Cuenta_Id
    ) 
    REFERENCES Producto 
    ( 
     GTIN,
     Cuenta_Id
    ) 
;

ALTER TABLE Categoria_Activos 
    ADD CONSTRAINT Categoria_Activos_Cuenta_FK FOREIGN KEY 
    ( 
     Cuenta_Id
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;

ALTER TABLE Categoria 
    ADD CONSTRAINT Categoria_Cuenta_FK FOREIGN KEY 
    ( 
     Cuenta_Id
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;

ALTER TABLE Cuenta 
    ADD CONSTRAINT Cuenta_Plan_FK FOREIGN KEY 
    ( 
     Plan_Id
    ) 
    REFERENCES Plan 
    ( 
     Id
    ) 
;

ALTER TABLE Cuenta 
    ADD CONSTRAINT Cuenta_Usuario_FK FOREIGN KEY 
    ( 
     Usuario_Id
    ) 
    REFERENCES Usuario 
    ( 
     Id
    ) 
;

ALTER TABLE Producto 
    ADD CONSTRAINT Producto_Cuenta_FK FOREIGN KEY 
    ( 
     Cuenta_Id
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;

ALTER TABLE Rel_Activ_CategAct 
    ADD CONSTRAINT Rel_Activ_CategAct_FK FOREIGN KEY 
    ( 
     Activo_Id,
     Activo_Cuenta_Id
    ) 
    REFERENCES Activo 
    ( 
     Id,
     Cuenta_Id
    ) 
;

ALTER TABLE Rel_Activ_CategAct 
    ADD CONSTRAINT Rel_Activ_Categoria_Activos_FK FOREIGN KEY 
    ( 
     Categoria_Activos_Id,
     Categoria_Activos_Cuenta_Id
    ) 
    REFERENCES Categoria_Activos 
    ( 
     Id,
     Cuenta_Id
    ) 
;

ALTER TABLE Rel_Prod_Activ 
    ADD CONSTRAINT Rel_Prod_Activ_Activo_FK FOREIGN KEY 
    ( 
     Activo_Id,
     Activo_Cuenta_Id
    ) 
    REFERENCES Activo 
    ( 
     Id,
     Cuenta_Id
    ) 
;

ALTER TABLE Rel_Prod_Activ 
    ADD CONSTRAINT Rel_Prod_Activ_Producto_FK FOREIGN KEY 
    ( 
     Producto_GTIN,
     Producto_Cuenta_Id
    ) 
    REFERENCES Producto 
    ( 
     GTIN,
     Cuenta_Id
    ) 
;

ALTER TABLE Rel_Prod_Categ 
    ADD CONSTRAINT Rel_Prod_Categ_Categoria_FK FOREIGN KEY 
    ( 
     Categoria_Id,
     Categoria_Cuenta_Id
    ) 
    REFERENCES Categoria 
    ( 
     Id,
     Cuenta_Id
    ) 
;

ALTER TABLE Rel_Prod_Categ 
    ADD CONSTRAINT Rel_Prod_Categ_Producto_FK FOREIGN KEY 
    ( 
     Producto_GTIN,
     Producto_Cuenta_Id
    ) 
    REFERENCES Producto 
    ( 
     GTIN,
     Cuenta_Id
    ) 
;

ALTER TABLE Relacionado 
    ADD CONSTRAINT Relacionado_Producto_FK FOREIGN KEY 
    ( 
     Producto_GTIN,
     Producto_Cuenta_Id
    ) 
    REFERENCES Producto 
    ( 
     GTIN,
     Cuenta_Id
    ) 
;

ALTER TABLE Relacionado 
    ADD CONSTRAINT Relacionado_Producto_FKv2 FOREIGN KEY 
    ( 
     Producto_GTIN1,
     Producto_Cuenta_Id1
    ) 
    REFERENCES Producto 
    ( 
     GTIN,
     Cuenta_Id
    ) 
;

ALTER TABLE Usuario 
    ADD CONSTRAINT Usuario_Cuenta_FK FOREIGN KEY 
    ( 
     Cuenta_Id
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;

ALTER TABLE Usuario 
    ADD CONSTRAINT Usuario_Cuenta_FKv2 FOREIGN KEY 
    ( 
     Cuenta_Dueno  
    ) 
    REFERENCES Cuenta 
    ( 
     Id
    ) 
;



-- Informe de Resumen de Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                            13
-- CREATE INDEX                             2
-- ALTER TABLE                             31
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   0
-- WARNINGS                                 0

-- CREAMOS EL TRIGGER Y LA SECUENCIA PARA INSERTAR LOS DATOS EN PRODUCTOS

CREATE SEQUENCE SEQ_PRODUCTOS;

create or replace trigger TR_PRODUCTOS  
before insert on PRODUCTO for each row 
begin 
if :new.GTIN is null then  
:new.GTIN := SEQ_PRODUCTOS.NEXTVAL; 
end if; 
END tr_PRODUCTOS; 

-- CREAMOS LA TABLA EXTERNA DE PRODUCTOS




-- INSERTAR DATOS

-- CUENTA

INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (1,'Travel World Agency','Calle Serrano, 22, Madrid','V7235810',to_date('16/03/2025', 'DD/MM/YYYY'),NULL,1);
--Fila 2
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (2,'Tech Innovators Inc.','Avenida Diagonal, 20, Barcelona','K3574668',to_date('13/12/2020', 'DD/MM/YYYY'),NULL,4);
--Fila 3
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (3,'Bright Future Education','Calle Gran VÃ­a, 28, Madrid','D7411123',to_date('01/08/2024', 'DD/MM/YYYY'),NULL,3);
--Fila 4
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (4,'Elite Fitness Club','Calle Serrano, 22, Madrid','L7393738',to_date('07/02/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 5
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (5,'Bright Future Education','Calle Gran VÃ­a, 28, Madrid','V1876383',to_date('22/02/2025', 'DD/MM/YYYY'),NULL,4);
--Fila 6
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (6,'Luxury Living Estates','Calle de AlcalÃ¡, 45, Madrid','U5973630',to_date('05/09/2022', 'DD/MM/YYYY'),NULL,3);
--Fila 7
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (7,'Creative Media Agency','Calle Serrano, 22, Madrid','F4299726',to_date('06/06/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 8
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (8,'Health First Medical','Calle Gran VÃ­a, 28, Madrid','P2840144',to_date('06/05/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 9
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (9,'Global Trade Corp.','Calle Gran VÃ­a, 28, Madrid','A7066973',to_date('28/11/2024', 'DD/MM/YYYY'),NULL,2);
--Fila 10
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (10,'Luxury Living Estates','Calle Gran VÃ­a, 28, Madrid','M7360019',to_date('12/10/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 11
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (11,'Creative Media Agency','Calle Gran VÃ­a, 28, Madrid','F2234134',to_date('28/05/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 12
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (12,'Future Finance Group','Calle UrÃ­a, 3, Oviedo','A0461486',to_date('05/07/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 13
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (13,'SecureIT Services','Calle Larios, 10, MÃ¡laga','G2467937',to_date('19/08/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 14
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (14,'Bright Future Education','Calle de AlcalÃ¡, 45, Madrid','J5462411',to_date('09/01/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 15
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (15,'Fashion Forward Boutique','Calle UrÃ­a, 3, Oviedo','K1575025',to_date('04/10/2020', 'DD/MM/YYYY'),NULL,1);
--Fila 16
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (16,'Clean Water Initiative','Calle Serrano, 22, Madrid','N2982448',to_date('02/02/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 17
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (17,'Luxury Living Estates','Avenida Diagonal, 20, Barcelona','R5788502',to_date('06/06/2023', 'DD/MM/YYYY'),NULL,2);
--Fila 18
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (18,'Travel World Agency','Calle UrÃ­a, 3, Oviedo','R5636771',to_date('01/02/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 19
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (19,'Bright Future Education','Paseo de Gracia, 15, Barcelona','A9476104',to_date('13/03/2020', 'DD/MM/YYYY'),NULL,1);
--Fila 20
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (20,'Digital Marketing Pros','Paseo de Gracia, 15, Barcelona','C0387887',to_date('08/05/2021', 'DD/MM/YYYY'),NULL,2);
--Fila 21
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (21,'Tech Innovators Inc.','Calle Mayor, 5, Valencia','H7520094',to_date('27/09/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 22
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (22,'Creative Media Agency','Calle Gran VÃ­a, 28, Madrid','V3302898',to_date('22/03/2022', 'DD/MM/YYYY'),NULL,2);
--Fila 23
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (23,'Fresh Foods Market','Calle Serrano, 22, Madrid','C0161122',to_date('20/02/2025', 'DD/MM/YYYY'),NULL,2);
--Fila 24
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (24,'SecureIT Services','Calle Serrano, 22, Madrid','J5805392',to_date('06/05/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 25
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (25,'Clean Water Initiative','Avenida de la ConstituciÃ³n, 12, Sevilla','A1381742',to_date('07/09/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 26
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (26,'Urban Development Co.','Paseo de Gracia, 15, Barcelona','J2431831',to_date('09/12/2021', 'DD/MM/YYYY'),NULL,3);
--Fila 27
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (27,'Smart Home Technologies','Calle Serrano, 22, Madrid','Q8824456',to_date('21/03/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 28
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (28,'Digital Marketing Pros','Calle Serrano, 22, Madrid','E9402003',to_date('08/09/2024', 'DD/MM/YYYY'),NULL,3);
--Fila 29
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (29,'Urban Development Co.','Calle de AlcalÃ¡, 45, Madrid','A9867815',to_date('13/09/2020', 'DD/MM/YYYY'),NULL,4);
--Fila 30
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (30,'Creative Media Agency','Calle Larios, 10, MÃ¡laga','U9589848',to_date('09/04/2022', 'DD/MM/YYYY'),NULL,3);
--Fila 31
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (31,'Clean Water Initiative','Calle Larios, 10, MÃ¡laga','R1647951',to_date('14/10/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 32
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (32,'Global Trade Corp.','Calle Gran VÃ­a, 28, Madrid','B6235055',to_date('17/04/2024', 'DD/MM/YYYY'),NULL,3);
--Fila 33
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (33,'Future Finance Group','Avenida de la ConstituciÃ³n, 12, Sevilla','P8401310',to_date('11/02/2021', 'DD/MM/YYYY'),NULL,2);
--Fila 34
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (34,'Smart Home Technologies','Calle Gran VÃ­a, 28, Madrid','E1021060',to_date('22/10/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 35
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (35,'Global Trade Corp.','Avenida de la ConstituciÃ³n, 12, Sevilla','L3989512',to_date('22/12/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 36
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (36,'Fresh Foods Market','Calle de AlcalÃ¡, 45, Madrid','G0617931',to_date('18/11/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 37
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (37,'Global Trade Corp.','Calle Gran VÃ­a, 28, Madrid','E6476197',to_date('01/03/2022', 'DD/MM/YYYY'),NULL,4);
--Fila 38
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (38,'Health First Medical','Avenida de la ConstituciÃ³n, 12, Sevilla','P0308101',to_date('03/02/2020', 'DD/MM/YYYY'),NULL,4);
--Fila 39
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (39,'Future Finance Group','Avenida de la ConstituciÃ³n, 12, Sevilla','Q5840851',to_date('27/03/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 40
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (40,'Travel World Agency','Paseo de Gracia, 15, Barcelona','E9931977',to_date('31/12/2020', 'DD/MM/YYYY'),NULL,1);
--Fila 41
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (41,'SecureIT Services','Paseo de Gracia, 15, Barcelona','G9862224',to_date('12/10/2021', 'DD/MM/YYYY'),NULL,3);
--Fila 42
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (42,'Auto Experts Garage','Calle Larios, 10, MÃ¡laga','K1842986',to_date('29/03/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 43
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (43,'Creative Media Agency','Calle Larios, 10, MÃ¡laga','W8804894',to_date('07/03/2020', 'DD/MM/YYYY'),NULL,2);
--Fila 44
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (44,'Travel World Agency','Avenida Diagonal, 20, Barcelona','L7127457',to_date('05/06/2022', 'DD/MM/YYYY'),NULL,4);
--Fila 45
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (45,'Bright Future Education','Calle Mayor, 5, Valencia','R3627862',to_date('12/08/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 46
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (46,'Digital Marketing Pros','Calle ColÃ³n, 8, Valencia','P4885531',to_date('30/11/2022', 'DD/MM/YYYY'),NULL,4);
--Fila 47
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (47,'Fresh Foods Market','Calle Mayor, 5, Valencia','M1345231',to_date('24/12/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 48
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (48,'Auto Experts Garage','Calle ColÃ³n, 8, Valencia','D7233379',to_date('28/06/2023', 'DD/MM/YYYY'),NULL,2);
--Fila 49
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (49,'Smart Home Technologies','Calle ColÃ³n, 8, Valencia','F3899466',to_date('01/11/2023', 'DD/MM/YYYY'),NULL,2);
--Fila 50
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (50,'Elite Fitness Club','Paseo de Gracia, 15, Barcelona','S9613722',to_date('07/01/2025', 'DD/MM/YYYY'),NULL,3);
--Fila 51
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (51,'Fresh Foods Market','Calle UrÃ­a, 3, Oviedo','D7324463',to_date('04/02/2024', 'DD/MM/YYYY'),NULL,3);
--Fila 52
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (52,'Green Energy Solutions','Paseo de Gracia, 15, Barcelona','G1288467',to_date('30/06/2020', 'DD/MM/YYYY'),NULL,4);
--Fila 53
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (53,'Health First Medical','Calle ColÃ³n, 8, Valencia','F1648211',to_date('01/09/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 54
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (54,'Health First Medical','Calle Mayor, 5, Valencia','N9805933',to_date('15/08/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 55
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (55,'Luxury Living Estates','Avenida de la ConstituciÃ³n, 12, Sevilla','V3667580',to_date('26/12/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 56
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (56,'Creative Media Agency','Calle UrÃ­a, 3, Oviedo','A1691704',to_date('27/05/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 57
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (57,'Clean Water Initiative','Calle Larios, 10, MÃ¡laga','P5911480',to_date('30/08/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 58
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (58,'Auto Experts Garage','Avenida de la ConstituciÃ³n, 12, Sevilla','M6366356',to_date('02/03/2025', 'DD/MM/YYYY'),NULL,4);
--Fila 59
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (59,'Fashion Forward Boutique','Calle ColÃ³n, 8, Valencia','C9474308',to_date('26/12/2024', 'DD/MM/YYYY'),NULL,4);
--Fila 60
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (60,'Eco-Friendly Products','Avenida Diagonal, 20, Barcelona','W4632635',to_date('23/09/2022', 'DD/MM/YYYY'),NULL,2);
--Fila 61
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (61,'Urban Development Co.','Calle Serrano, 22, Madrid','M0081808',to_date('02/08/2021', 'DD/MM/YYYY'),NULL,3);
--Fila 62
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (62,'Green Energy Solutions','Paseo de Gracia, 15, Barcelona','R9530747',to_date('27/01/2022', 'DD/MM/YYYY'),NULL,2);
--Fila 63
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (63,'Digital Marketing Pros','Avenida Diagonal, 20, Barcelona','V6714460',to_date('03/04/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 64
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (64,'Elite Fitness Club','Avenida Diagonal, 20, Barcelona','V4306785',to_date('16/08/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 65
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (65,'Eco-Friendly Products','Calle ColÃ³n, 8, Valencia','M0871781',to_date('25/10/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 66
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (66,'Global Trade Corp.','Calle ColÃ³n, 8, Valencia','U1495106',to_date('10/12/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 67
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (67,'Future Finance Group','Calle Serrano, 22, Madrid','U6984280',to_date('03/11/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 68
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (68,'Health First Medical','Calle Serrano, 22, Madrid','M7705539',to_date('02/03/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 69
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (69,'Bright Future Education','Avenida Diagonal, 20, Barcelona','H8228526',to_date('17/01/2020', 'DD/MM/YYYY'),NULL,2);
--Fila 70
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (70,'Auto Experts Garage','Calle Mayor, 5, Valencia','M8101059',to_date('19/07/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 71
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (71,'Health First Medical','Calle ColÃ³n, 8, Valencia','U1715228',to_date('07/04/2022', 'DD/MM/YYYY'),NULL,4);
--Fila 72
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (72,'Smart Home Technologies','Calle UrÃ­a, 3, Oviedo','U6916574',to_date('28/09/2024', 'DD/MM/YYYY'),NULL,2);
--Fila 73
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (73,'Fresh Foods Market','Calle Mayor, 5, Valencia','V8562233',to_date('23/11/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 74
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (74,'Fresh Foods Market','Calle de AlcalÃ¡, 45, Madrid','P4907175',to_date('03/06/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 75
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (75,'Tech Innovators Inc.','Calle Gran VÃ­a, 28, Madrid','S5218224',to_date('02/10/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 76
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (76,'SecureIT Services','Calle UrÃ­a, 3, Oviedo','S7783005',to_date('29/04/2022', 'DD/MM/YYYY'),NULL,4);
--Fila 77
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (77,'Tech Innovators Inc.','Calle Serrano, 22, Madrid','V1306650',to_date('06/03/2021', 'DD/MM/YYYY'),NULL,2);
--Fila 78
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (78,'Health First Medical','Calle Mayor, 5, Valencia','U8893431',to_date('24/08/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 79
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (79,'Urban Development Co.','Paseo de Gracia, 15, Barcelona','U7016716',to_date('04/01/2025', 'DD/MM/YYYY'),NULL,3);
--Fila 80
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (80,'Eco-Friendly Products','Paseo de Gracia, 15, Barcelona','L8052984',to_date('29/11/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 81
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (81,'Green Energy Solutions','Paseo de Gracia, 15, Barcelona','D2777329',to_date('04/11/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 82
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (82,'Eco-Friendly Products','Calle Gran VÃ­a, 28, Madrid','C2345157',to_date('14/06/2021', 'DD/MM/YYYY'),NULL,2);
--Fila 83
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (83,'Smart Home Technologies','Avenida de la ConstituciÃ³n, 12, Sevilla','V4562337',to_date('04/11/2023', 'DD/MM/YYYY'),NULL,1);
--Fila 84
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (84,'Green Energy Solutions','Avenida Diagonal, 20, Barcelona','C6839292',to_date('29/06/2020', 'DD/MM/YYYY'),NULL,3);
--Fila 85
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (85,'Health First Medical','Calle Larios, 10, MÃ¡laga','C3859795',to_date('30/10/2024', 'DD/MM/YYYY'),NULL,1);
--Fila 86
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (86,'SecureIT Services','Calle de AlcalÃ¡, 45, Madrid','M2701424',to_date('11/07/2020', 'DD/MM/YYYY'),NULL,4);
--Fila 87
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (87,'Travel World Agency','Avenida de la ConstituciÃ³n, 12, Sevilla','G6996840',to_date('14/01/2025', 'DD/MM/YYYY'),NULL,2);
--Fila 88
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (88,'Travel World Agency','Calle Serrano, 22, Madrid','R9715792',to_date('09/06/2023', 'DD/MM/YYYY'),NULL,3);
--Fila 89
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (89,'Creative Media Agency','Calle UrÃ­a, 3, Oviedo','J2302678',to_date('13/12/2024', 'DD/MM/YYYY'),NULL,2);
--Fila 90
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (90,'Auto Experts Garage','Calle Gran VÃ­a, 28, Madrid','K8272395',to_date('18/07/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 91
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (91,'Urban Development Co.','Calle ColÃ³n, 8, Valencia','R5723629',to_date('05/03/2025', 'DD/MM/YYYY'),NULL,4);
--Fila 92
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (92,'Clean Water Initiative','Calle Gran VÃ­a, 28, Madrid','L2875426',to_date('24/02/2021', 'DD/MM/YYYY'),NULL,3);
--Fila 93
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (93,'SecureIT Services','Calle UrÃ­a, 3, Oviedo','M2363725',to_date('30/08/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 94
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (94,'Digital Marketing Pros','Calle Serrano, 22, Madrid','W5816604',to_date('23/02/2020', 'DD/MM/YYYY'),NULL,2);
--Fila 95
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (95,'Fresh Foods Market','Calle Mayor, 5, Valencia','V0667415',to_date('07/12/2020', 'DD/MM/YYYY'),NULL,1);
--Fila 96
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (96,'Bright Future Education','Calle Mayor, 5, Valencia','W0649640',to_date('08/12/2021', 'DD/MM/YYYY'),NULL,1);
--Fila 97
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (97,'Health First Medical','Calle Larios, 10, MÃ¡laga','S6333699',to_date('16/04/2021', 'DD/MM/YYYY'),NULL,4);
--Fila 98
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (98,'Luxury Living Estates','Calle Gran VÃ­a, 28, Madrid','G5195031',to_date('10/02/2022', 'DD/MM/YYYY'),NULL,2);
--Fila 99
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (99,'Eco-Friendly Products','Calle de AlcalÃ¡, 45, Madrid','S5182179',to_date('21/01/2022', 'DD/MM/YYYY'),NULL,1);
--Fila 100
INSERT INTO CUENTA (ID, NOMBRE, "DIRECCIÓNFISCAL", NIF, FECHAALTA, USUARIO_ID, PLAN_ID) VALUES (100,'Digital Marketing Pros','Avenida Diagonal, 20, Barcelona','V7437021',to_date('18/01/2023', 'DD/MM/YYYY'),NULL,4);

-- PLANES
--Fila 1
INSERT INTO PLAN (ID, NOMBRE, PRODUCTOS, ACTIVOS, ALMACENAMIENTO, CATEGORIASPRODUCTO, CATEGORIASACTIVOS, RELACIONES, PRECIOANUAL) VALUES (1,'Free','100','200','1GB','3','3','3','0');
--Fila 2
INSERT INTO PLAN (ID, NOMBRE, PRODUCTOS, ACTIVOS, ALMACENAMIENTO, CATEGORIASPRODUCTO, CATEGORIASACTIVOS, RELACIONES, PRECIOANUAL) VALUES (2,'Basic','1000','20000','50GB','10','10','5','7000');
--Fila 3
INSERT INTO PLAN (ID, NOMBRE, PRODUCTOS, ACTIVOS, ALMACENAMIENTO, CATEGORIASPRODUCTO, CATEGORIASACTIVOS, RELACIONES, PRECIOANUAL) VALUES (3,'Enterprise','100000','100000','200GB','1000','1000','10','50000');
--Fila 4
INSERT INTO PLAN (ID, NOMBRE, PRODUCTOS, ACTIVOS, ALMACENAMIENTO, CATEGORIASPRODUCTO, CATEGORIASACTIVOS, RELACIONES, PRECIOANUAL) VALUES (4,'Deluxe','200000','200000','1TB','2000','2000','20','75000');

-- PRODUCTO

--Fila 1
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000001','Fitness Tracker','Next-gen gaming console.',to_date('23/02/2024', 'DD/MM/YYYY'),2);
--Fila 2
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000002','Bluetooth Speaker','Professional laptop for all your needs.',to_date('31/10/2024', 'DD/MM/YYYY'),15);
--Fila 3
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000003','Wireless Headphones','Portable Bluetooth speaker.',to_date('11/10/2024', 'DD/MM/YYYY'),21);
--Fila 4
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000004','Smartwatch','Professional laptop for all your needs.',to_date('07/07/2024', 'DD/MM/YYYY'),20);
--Fila 5
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000005','Digital Camera','Portable Bluetooth speaker.',to_date('10/10/2024', 'DD/MM/YYYY'),2);
--Fila 6
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000006','Smartwatch','Smartwatch with health tracking.',to_date('31/07/2024', 'DD/MM/YYYY'),29);
--Fila 7
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000007','Digital Camera','Smartwatch with health tracking.',to_date('17/09/2024', 'DD/MM/YYYY'),13);
--Fila 8
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000008','Fitness Tracker','High-resolution digital camera.',to_date('04/10/2024', 'DD/MM/YYYY'),12);
--Fila 9
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000009','Laptop Pro','High-end smartphone with advanced features.',to_date('12/09/2024', 'DD/MM/YYYY'),22);
--Fila 10
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000010','Bluetooth Speaker','Portable Bluetooth speaker.',to_date('14/04/2024', 'DD/MM/YYYY'),10);
--Fila 11
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000011','Gaming Console','Ultra HD 4K television.',to_date('11/03/2025', 'DD/MM/YYYY'),19);
--Fila 12
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000012','Wireless Headphones','Portable Bluetooth speaker.',to_date('13/04/2024', 'DD/MM/YYYY'),5);
--Fila 13
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000013','4K TV','Versatile tablet for work and play.',to_date('23/07/2024', 'DD/MM/YYYY'),11);
--Fila 14
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000014','Gaming Console','Professional laptop for all your needs.',to_date('10/05/2024', 'DD/MM/YYYY'),12);
--Fila 15
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000015','Wireless Headphones','Fitness tracker with heart rate monitor.',to_date('26/06/2024', 'DD/MM/YYYY'),17);
--Fila 16
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000016','4K TV','Smartwatch with health tracking.',to_date('08/01/2024', 'DD/MM/YYYY'),23);
--Fila 17
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000017','Smartphone X','High-end smartphone with advanced features.',to_date('24/06/2024', 'DD/MM/YYYY'),10);
--Fila 18
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000018','4K TV','Versatile tablet for work and play.',to_date('15/11/2024', 'DD/MM/YYYY'),21);
--Fila 19
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000019','Wireless Headphones','Portable Bluetooth speaker.',to_date('08/03/2025', 'DD/MM/YYYY'),5);
--Fila 20
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000020','Digital Camera','Ultra HD 4K television.',to_date('05/02/2025', 'DD/MM/YYYY'),11);
--Fila 21
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000021','Digital Camera','Versatile tablet for work and play.',to_date('08/11/2024', 'DD/MM/YYYY'),27);
--Fila 22
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000022','Laptop Pro','Smartwatch with health tracking.',to_date('18/10/2024', 'DD/MM/YYYY'),26);
--Fila 23
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000023','Gaming Console','High-resolution digital camera.',to_date('25/01/2025', 'DD/MM/YYYY'),7);
--Fila 24
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000024','Smartphone X','Ultra HD 4K television.',to_date('04/03/2025', 'DD/MM/YYYY'),2);
--Fila 25
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000025','Gaming Console','Ultra HD 4K television.',to_date('05/03/2025', 'DD/MM/YYYY'),8);
--Fila 26
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000026','4K TV','Noise-cancelling wireless headphones.',to_date('29/08/2024', 'DD/MM/YYYY'),1);
--Fila 27
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000027','Bluetooth Speaker','Versatile tablet for work and play.',to_date('29/12/2024', 'DD/MM/YYYY'),16);
--Fila 28
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000028','Gaming Console','Portable Bluetooth speaker.',to_date('26/06/2024', 'DD/MM/YYYY'),27);
--Fila 29
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000029','Digital Camera','Professional laptop for all your needs.',to_date('19/12/2024', 'DD/MM/YYYY'),25);
--Fila 30
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000030','Smartphone X','High-resolution digital camera.',to_date('11/01/2024', 'DD/MM/YYYY'),26);
--Fila 31
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000031','Smartwatch','Versatile tablet for work and play.',to_date('22/01/2024', 'DD/MM/YYYY'),24);
--Fila 32
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000032','Smartphone X','Next-gen gaming console.',to_date('01/02/2025', 'DD/MM/YYYY'),3);
--Fila 33
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000033','4K TV','Ultra HD 4K television.',to_date('01/07/2024', 'DD/MM/YYYY'),13);
--Fila 34
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000034','Laptop Pro','Portable Bluetooth speaker.',to_date('22/08/2024', 'DD/MM/YYYY'),15);
--Fila 35
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000035','Laptop Pro','Fitness tracker with heart rate monitor.',to_date('07/02/2024', 'DD/MM/YYYY'),26);
--Fila 36
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000036','Smartwatch','Noise-cancelling wireless headphones.',to_date('29/02/2024', 'DD/MM/YYYY'),27);
--Fila 37
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000037','Gaming Console','Next-gen gaming console.',to_date('10/03/2025', 'DD/MM/YYYY'),26);
--Fila 38
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000038','Bluetooth Speaker','Noise-cancelling wireless headphones.',to_date('11/02/2025', 'DD/MM/YYYY'),15);
--Fila 39
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000039','Tablet Plus','Next-gen gaming console.',to_date('16/11/2024', 'DD/MM/YYYY'),19);
--Fila 40
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000040','Fitness Tracker','High-end smartphone with advanced features.',to_date('15/04/2024', 'DD/MM/YYYY'),26);
--Fila 41
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000041','Digital Camera','Portable Bluetooth speaker.',to_date('24/09/2024', 'DD/MM/YYYY'),28);
--Fila 42
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000042','Bluetooth Speaker','Next-gen gaming console.',to_date('18/01/2024', 'DD/MM/YYYY'),13);
--Fila 43
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000043','Digital Camera','Fitness tracker with heart rate monitor.',to_date('20/08/2024', 'DD/MM/YYYY'),21);
--Fila 44
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000044','Smartphone X','High-end smartphone with advanced features.',to_date('06/03/2024', 'DD/MM/YYYY'),27);
--Fila 45
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000045','Wireless Headphones','Versatile tablet for work and play.',to_date('24/01/2024', 'DD/MM/YYYY'),18);
--Fila 46
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000046','Smartwatch','Ultra HD 4K television.',to_date('24/05/2024', 'DD/MM/YYYY'),16);
--Fila 47
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000047','Smartwatch','High-resolution digital camera.',to_date('14/02/2024', 'DD/MM/YYYY'),8);
--Fila 48
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000048','Laptop Pro','Versatile tablet for work and play.',to_date('10/11/2024', 'DD/MM/YYYY'),17);
--Fila 49
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000049','Smartphone X','Noise-cancelling wireless headphones.',to_date('17/10/2024', 'DD/MM/YYYY'),4);
--Fila 50
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000050','Fitness Tracker','Professional laptop for all your needs.',to_date('06/12/2024', 'DD/MM/YYYY'),28);
--Fila 51
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000051','Tablet Plus','Ultra HD 4K television.',to_date('01/02/2025', 'DD/MM/YYYY'),2);
--Fila 52
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000052','Bluetooth Speaker','Professional laptop for all your needs.',to_date('19/03/2025', 'DD/MM/YYYY'),2);
--Fila 53
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000053','Smartwatch','High-end smartphone with advanced features.',to_date('29/11/2024', 'DD/MM/YYYY'),13);
--Fila 54
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000054','Gaming Console','Professional laptop for all your needs.',to_date('13/01/2025', 'DD/MM/YYYY'),25);
--Fila 55
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000055','4K TV','Smartwatch with health tracking.',to_date('03/07/2024', 'DD/MM/YYYY'),11);
--Fila 56
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000056','Smartwatch','Versatile tablet for work and play.',to_date('21/01/2024', 'DD/MM/YYYY'),13);
--Fila 57
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000057','Fitness Tracker','Next-gen gaming console.',to_date('17/06/2024', 'DD/MM/YYYY'),15);
--Fila 58
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000058','Laptop Pro','Versatile tablet for work and play.',to_date('05/07/2024', 'DD/MM/YYYY'),16);
--Fila 59
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000059','Laptop Pro','Portable Bluetooth speaker.',to_date('31/03/2024', 'DD/MM/YYYY'),24);
--Fila 60
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000060','Gaming Console','Portable Bluetooth speaker.',to_date('12/10/2024', 'DD/MM/YYYY'),24);
--Fila 61
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000061','Smartphone X','High-resolution digital camera.',to_date('14/06/2024', 'DD/MM/YYYY'),11);
--Fila 62
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000062','Fitness Tracker','Ultra HD 4K television.',to_date('03/01/2025', 'DD/MM/YYYY'),28);
--Fila 63
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000063','Laptop Pro','Noise-cancelling wireless headphones.',to_date('23/06/2024', 'DD/MM/YYYY'),20);
--Fila 64
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000064','Tablet Plus','Ultra HD 4K television.',to_date('05/05/2024', 'DD/MM/YYYY'),13);
--Fila 65
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000065','Bluetooth Speaker','Ultra HD 4K television.',to_date('28/01/2025', 'DD/MM/YYYY'),9);
--Fila 66
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000066','Fitness Tracker','Noise-cancelling wireless headphones.',to_date('14/04/2024', 'DD/MM/YYYY'),19);
--Fila 67
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000067','Wireless Headphones','Ultra HD 4K television.',to_date('22/02/2024', 'DD/MM/YYYY'),20);
--Fila 68
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000068','Fitness Tracker','Next-gen gaming console.',to_date('26/07/2024', 'DD/MM/YYYY'),19);
--Fila 69
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000069','Fitness Tracker','Smartwatch with health tracking.',to_date('23/05/2024', 'DD/MM/YYYY'),14);
--Fila 70
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000070','Tablet Plus','Ultra HD 4K television.',to_date('09/02/2024', 'DD/MM/YYYY'),3);
--Fila 71
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000071','Digital Camera','Portable Bluetooth speaker.',to_date('31/10/2024', 'DD/MM/YYYY'),8);
--Fila 72
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000072','Bluetooth Speaker','High-end smartphone with advanced features.',to_date('13/01/2025', 'DD/MM/YYYY'),23);
--Fila 73
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000073','Wireless Headphones','Versatile tablet for work and play.',to_date('20/05/2024', 'DD/MM/YYYY'),15);
--Fila 74
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000074','Fitness Tracker','Smartwatch with health tracking.',to_date('07/09/2024', 'DD/MM/YYYY'),7);
--Fila 75
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000075','Gaming Console','Professional laptop for all your needs.',to_date('15/12/2024', 'DD/MM/YYYY'),14);
--Fila 76
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000076','4K TV','Noise-cancelling wireless headphones.',to_date('08/05/2024', 'DD/MM/YYYY'),20);
--Fila 77
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000077','Smartwatch','High-end smartphone with advanced features.',to_date('02/04/2024', 'DD/MM/YYYY'),15);
--Fila 78
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000078','Fitness Tracker','Ultra HD 4K television.',to_date('11/01/2024', 'DD/MM/YYYY'),15);
--Fila 79
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000079','4K TV','High-resolution digital camera.',to_date('23/04/2024', 'DD/MM/YYYY'),16);
--Fila 80
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000080','Gaming Console','High-resolution digital camera.',to_date('03/10/2024', 'DD/MM/YYYY'),21);
--Fila 81
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000081','Bluetooth Speaker','Professional laptop for all your needs.',to_date('12/01/2025', 'DD/MM/YYYY'),4);
--Fila 82
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000082','Tablet Plus','Smartwatch with health tracking.',to_date('12/03/2024', 'DD/MM/YYYY'),15);
--Fila 83
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000083','Smartphone X','Smartwatch with health tracking.',to_date('02/02/2025', 'DD/MM/YYYY'),5);
--Fila 84
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000084','Smartphone X','Portable Bluetooth speaker.',to_date('02/04/2024', 'DD/MM/YYYY'),1);
--Fila 85
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000085','Digital Camera','Noise-cancelling wireless headphones.',to_date('18/02/2024', 'DD/MM/YYYY'),4);
--Fila 86
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000086','Fitness Tracker','Ultra HD 4K television.',to_date('01/01/2025', 'DD/MM/YYYY'),2);
--Fila 87
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000087','Smartphone X','Ultra HD 4K television.',to_date('31/01/2025', 'DD/MM/YYYY'),18);
--Fila 88
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000088','Gaming Console','Next-gen gaming console.',to_date('16/12/2024', 'DD/MM/YYYY'),17);
--Fila 89
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000089','Smartwatch','Ultra HD 4K television.',to_date('17/09/2024', 'DD/MM/YYYY'),5);
--Fila 90
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000090','Bluetooth Speaker','Portable Bluetooth speaker.',to_date('23/08/2024', 'DD/MM/YYYY'),27);
--Fila 91
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000091','Gaming Console','Versatile tablet for work and play.',to_date('24/02/2025', 'DD/MM/YYYY'),27);
--Fila 92
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000092','Bluetooth Speaker','Portable Bluetooth speaker.',to_date('17/01/2025', 'DD/MM/YYYY'),13);
--Fila 93
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000093','Gaming Console','Professional laptop for all your needs.',to_date('13/05/2024', 'DD/MM/YYYY'),22);
--Fila 94
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000094','Tablet Plus','High-end smartphone with advanced features.',to_date('12/05/2024', 'DD/MM/YYYY'),3);
--Fila 95
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000095','Wireless Headphones','Next-gen gaming console.',to_date('06/04/2024', 'DD/MM/YYYY'),3);
--Fila 96
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000096','4K TV','Noise-cancelling wireless headphones.',to_date('01/02/2025', 'DD/MM/YYYY'),3);
--Fila 97
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000097','Laptop Pro','Noise-cancelling wireless headphones.',to_date('03/05/2024', 'DD/MM/YYYY'),21);
--Fila 98
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000098','Gaming Console','Smartwatch with health tracking.',to_date('01/07/2024', 'DD/MM/YYYY'),12);
--Fila 99
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000099','Wireless Headphones','Next-gen gaming console.',to_date('28/01/2024', 'DD/MM/YYYY'),12);
--Fila 100
INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES ('SKU_000100','4K TV','High-resolution digital camera.',to_date('28/08/2024', 'DD/MM/YYYY'),28);


-- COPIAR TRIGGER.