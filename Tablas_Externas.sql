--Tablas Externas 

--Añadimos a la ruta C:\app\alumnos\admin\orcl\dpdump , el fichero productos.csv

--Cambiamos a system y ejecutamos el siguiente comando 

create or replace directory directorio_ext as 'C:\app\alumnos\admin\orcl\dpdump'

-- Siguiente paso 

grant read, write on directory directorio_ext to PLYTIX;

-- Cerramos sesion en system y nos conectamos a Plytix, rellenamos los campos vacios 

CREATE TABLE productos_ext (
  sku          VARCHAR2(20),
  nombre       VARCHAR2(100),
  textocorto   VARCHAR2(255),
  creado       DATE,
  cuenta_id    VARCHAR2(20)
)

ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY directorio_ext
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    SKIP 1
    CHARACTERSET UTF8
    FIELDS TERMINATED BY ';'
    OPTIONALLY ENCLOSED BY '"'
    MISSING FIELD VALUES ARE NULL
    (
      sku          CHAR(20),
      nombre       CHAR(100),
      textocorto   CHAR(255),
      creado       CHAR(10) DATE_FORMAT DATE MASK "dd/mm/yyyy",
      cuenta_id    CHAR(20)
    )
  )
  LOCATION ('productos.csv')
);



-- Apartado 8, se insertan los datos de la tabla externa de producto a la tabla producto

INSERT INTO PRODUCTO (SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID)
SELECT
  sku,
  nombre,
  textocorto,
  TO_DATE(creado, 'DD/MM/YYYY'),
  cuenta_id
FROM productos_ext;
