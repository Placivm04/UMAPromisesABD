-- CREAMOS EL PAQUETE PKG_ADMIN_PRODUCTOS_AVANZADO QUE VA A CONTENER LOS PROCEDIMIENTOS Y FUNCIONES

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS_AVANZADO AS

    -- FUNCIONES

    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.ID%TYPE) RETURN VARCHAR2;
    
    FUNCTION  F_LISTA_CATEGORIAS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN VARCHAR2;

    -- PROCEDIMIENTOS

    PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(p_cuenta_id IN CUENTA.ID%TYPE, 
    p_categoria_origen_id IN CATEGORIA.ID%TYPE, p_categoria_destino_id IN 
    CATEGORIA.ID%TYPE) ;

    PROCEDURE P_REPLICAR_ATRIBUTOS(p_cuenta_id IN CUENTA.ID%TYPE, p_producto_gtin_origen IN 
    PRODUCTO.GTIN%TYPE, p_producto_gtin_destino IN PRODUCTO.GTIN%TYPE);
    
END PKG_ADMIN_PRODUCTOS_AVANZADO;
/

-- CREAMOS EL CUERPO DEL PAQUETE PKG_ADMIN_PRODUCTOS_AVANZADO QUE VA A CONTENER LOS PROCEDIMIENTOS Y FUNCIONES
create or replace PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS

    PROCEDURE REGISTRA_ERRORES(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            INSERT INTO TRAZA VALUES(SYSDATE, USER, P_DONDE, P_MENSAJE);
            COMMIT;
        END;
    

    -- FUNCIONES
    -- 1 -

    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.ID%TYPE) RETURN VARCHAR2 IS
        V_RES VARCHAR2(100);
        v_plan_actual PLAN%ROWTYPE;
        v_cant_productos NUMBER;
        v_cant_activos NUMBER;
        v_cant_categorias_producto NUMBER;
        v_cant_categorias_activos NUMBER;
        v_cant_relaciones NUMBER;
        V_CUENTA NUMBER;

    BEGIN
        
        
        V_CUENTA := F_ES_USUARIO_CUENTA(P_CUENTA_ID);
        
        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;
        
        -- COMPROBAMOS SI LA CUENTA EXISTE
        
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;
        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        v_plan_actual := F_OBTENER_PLAN_CUENTA(p_cuenta_id);

        SELECT COUNT(*) INTO V_CANT_PRODUCTOS FROM PRODUCTO WHERE CUENTA_ID = p_cuenta_id;
        SELECT COUNT(*) INTO V_CANT_ACTIVOS FROM ACTIVO WHERE CUENTA_ID = p_cuenta_id;
        SELECT COUNT(*) INTO V_CANT_CATEGORIAS_PRODUCTO FROM CATEGORIA WHERE CUENTA_ID = p_cuenta_id;
        SELECT COUNT(*) INTO v_cant_categorias_activos FROM Categoria_Activos WHERE CUENTA_ID = p_cuenta_id;
        SELECT COUNT(*) INTO v_cant_relaciones FROM RELACIONADO WHERE P_CUENTA_ID = PRODUCTO_CUENTA_ID;

        -- COMPROBAMOS LOS CONTEOS CON LOS LIMITES PERMITIDOS POR EL PLAN
        V_RES := 'SUFICIENTE';

        IF v_cant_productos > v_plan_actual.PRODUCTOS THEN
            V_RES := 'INSUFICIENTE: PRODUCTOS';
        ELSIF v_cant_activos > v_plan_actual.ACTIVOS THEN
            V_RES := 'INSUFICIENTE: ACTIVOS';
        ELSIF v_cant_categorias_producto > v_plan_actual.CATEGORIASPRODUCTO THEN
            V_RES := 'INSUFICIENTE: CATEGORIAS PRODUCTO';
        ELSIF v_cant_categorias_activos > v_plan_actual.CATEGORIASACTIVOS THEN
            V_RES := 'INSUFICIENTE: CATEGORIAS ACTIVOS';
        ELSIF v_cant_relaciones > v_plan_actual.RELACIONES THEN
            V_RES := 'INSUFICIENTE: RELACIONES';
        
        END IF;

        RETURN V_RES;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    
    END F_VALIDAR_PLAN_SUFICIENTE;

    ---------------------------------------------------------------------------------------------------------------

    -- 2 -

    FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN VARCHAR2 IS
        CURSOR C_CATEGORIAS IS SELECT CATEGORIA_ID FROM REL_PROD_CATEG WHERE P_CUENTA_ID = PRODUCTO_CUENTA_ID AND p_producto_gtin = PRODUCTO_GTIN;
        V_PRODUCTO NUMBER;
        V_CUENTA NUMBER;
        V_RES VARCHAR2(400);
        V_CATEGORIA_NOMBRE VARCHAR2(100);

    BEGIN
        -- COMPROBAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        -- COMPROBAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto
        END IF;

        V_RES := '';

        -- RECORREMOS LAS CATEGORIAS DEL PRODUCTO
        FOR cat IN C_CATEGORIAS LOOP

            SELECT NOMBRE INTO V_CATEGORIA_NOMBRE FROM CATEGORIA WHERE ID = CAT.CATEGORIA_ID;
            V_RES := V_RES || V_CATEGORIA_NOMBRE || '; ';

        END LOOP;

        RETURN V_RES;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
            
    END F_LISTA_CATEGORIAS_PRODUCTO;
    
-- 3) ---------------------------------------------------


    PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(
        p_cuenta_id            IN CUENTA.ID%TYPE,
        p_categoria_origen_id  IN CATEGORIA.ID%TYPE,
        p_categoria_destino_id IN CATEGORIA.ID%TYPE

    ) IS
        -- Cursor para recorrer los productos de la categoría de origen
        CURSOR c_productos IS
            SELECT Producto_GTIN, Producto_Cuenta_Id
            FROM Rel_Prod_Categ
            WHERE Categoria_Id = p_categoria_origen_id
                AND Categoria_Cuenta_Id = p_cuenta_id
                FOR UPDATE; -- Bloquea esas filas para que nadie más las modifique durante la operación

        V_CUENTA NUMBER;
        V_CATEG_ORIGEN NUMBER;
        V_CATEG_DESTINO NUMBER;

    BEGIN 

        -- VERIFICAMOS QUE LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;
        
        -- VERIFICAMOS QUE LA CATEGORIA ORIGEN EXISTE
        SELECT COUNT(*) INTO V_CATEG_ORIGEN FROM CATEGORIA WHERE ID = p_categoria_origen_id AND CUENTA_ID = p_cuenta_id;
        IF V_CATEG_ORIGEN = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la categoría origen
        END IF;
        
        -- VERIFICAMOS QUE LA CATEGORIA DESTINO EXISTE
        SELECT COUNT(*) INTO V_CATEG_DESTINO FROM CATEGORIA WHERE ID = p_categoria_destino_id AND CUENTA_ID = p_cuenta_id;
        IF V_CATEG_DESTINO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la categoría destino
        END IF;
        

        -- Recorrer productos y actualizar categoría
        FOR r_producto IN c_productos LOOP
            UPDATE Rel_Prod_Categ
            SET Categoria_Id = p_categoria_destino_id
            WHERE CURRENT OF c_productos;

        -- UPDATE REL_PROD_CATEG SET CATEGORIA_ID = p_categoria_destino_id WHERE PRODUCTO_GTIN = R_PRODUCTO.PRODUCTO_GTIN AND PRODUCTO_CUENTA_ID = R_PRODUCTO.PRODUCTO_CUENTA_ID;

        END LOOP;

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            ROLLBACK;
            RAISE;

    END P_MIGRAR_PRODUCTOS_A_CATEGORIA;
    
-- 4) -----------------------------------------------------

PROCEDURE P_REPLICAR_ATRIBUTOS(
    p_cuenta_id              IN CUENTA.ID%TYPE,
    p_producto_gtin_origen   IN PRODUCTO.GTIN%TYPE,
    p_producto_gtin_destino  IN PRODUCTO.GTIN%TYPE
) IS

    -- Cursor para obtener los atributos del producto origen
    CURSOR c_atributos_origen IS
        SELECT atributo_id, valor
        FROM Atributos_Producto
        WHERE producto_gtin = p_producto_gtin_origen
          --AND producto_cuenta_id = p_cuenta_id
        FOR UPDATE;

    V_PRODUCTO NUMBER;
    V_REGISTRO NUMBER;

BEGIN
    

    -- VERIFICAMOS QUE EL PRODUCTO ORIGEN EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_origen AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto origen
        END IF;

    -- VERIFICAMOS QUE EL PRODUCTO DESTINO EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_destino AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto destino
        END IF;

    -- Procesar cada atributo del producto origen
    FOR r_atributo IN c_atributos_origen LOOP
        BEGIN
            -- Verificar si ya existe el atributo para el producto destino en ATRIBUTOS_PRODUCTO

            SELECT COUNT(*) INTO V_REGISTRO
            FROM Atributos_Producto
            WHERE producto_gtin = p_producto_gtin_destino
                AND producto_cuenta_id = p_cuenta_id
                AND atributo_id = r_atributo.atributo_id;

            -- Si no existe, insertamos un nuevo registro, pero con el gtin destino
            IF V_REGISTRO = 0 THEN
                INSERT INTO Atributos_Producto (
                    valor, producto_gtin, producto_cuenta_id, atributo_id
                ) VALUES (
                    r_atributo.valor, p_producto_gtin_destino, p_cuenta_id, r_atributo.atributo_id
                );
            ELSE
                -- Si existe, actualizamos el valor al valor del registro origen
                UPDATE Atributos_Producto
                SET valor = r_atributo.valor
                WHERE producto_gtin = p_producto_gtin_destino
                  AND producto_cuenta_id = p_cuenta_id
                  AND atributo_id = r_atributo.atributo_id;
            END IF;
        END;
    END LOOP;

    -- Confirmar transacción
    COMMIT;

-- Manejo de errores específicos
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            ROLLBACK;
            RAISE;
END P_REPLICAR_ATRIBUTOS;
    
END PKG_ADMIN_PRODUCTOS_AVANZADO;
/

-- PROCEDIMIENTOS REQUERIDOS

CREATE OR REPLACE PROCEDURE P_REPLICAR_ATRIBUTOS(
    p_cuenta_id              IN CUENTA.ID%TYPE,
    p_producto_gtin_origen   IN PRODUCTO.GTIN%TYPE,
    p_producto_gtin_destino  IN PRODUCTO.GTIN%TYPE
) IS

    -- Cursor para obtener los atributos del producto origen
    CURSOR c_atributos_origen IS
        SELECT atributo_id, valor
        FROM Atributos_Producto
        WHERE producto_gtin = p_producto_gtin_origen
          --AND producto_cuenta_id = p_cuenta_id
        FOR UPDATE;

    V_PRODUCTO NUMBER;
    V_REGISTRO NUMBER;

BEGIN
    

    -- VERIFICAMOS QUE EL PRODUCTO ORIGEN EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_origen AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto origen
        END IF;

    -- VERIFICAMOS QUE EL PRODUCTO DESTINO EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_destino AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto destino
        END IF;

    -- Procesar cada atributo del producto origen
    FOR r_atributo IN c_atributos_origen LOOP
        BEGIN
            -- Verificar si ya existe el atributo para el producto destino en ATRIBUTOS_PRODUCTO

            SELECT COUNT(*) INTO V_REGISTRO
            FROM Atributos_Producto
            WHERE producto_gtin = p_producto_gtin_destino
                AND producto_cuenta_id = p_cuenta_id
                AND atributo_id = r_atributo.atributo_id;

            -- Si no existe, insertamos un nuevo registro, pero con el gtin destino
            IF V_REGISTRO = 0 THEN
                INSERT INTO Atributos_Producto (
                    valor, producto_gtin, producto_cuenta_id, atributo_id
                ) VALUES (
                    r_atributo.valor, p_producto_gtin_destino, p_cuenta_id, r_atributo.atributo_id
                );
            ELSE
                -- Si existe, actualizamos el valor al valor del registro origen
                UPDATE Atributos_Producto
                SET valor = r_atributo.valor
                WHERE producto_gtin = p_producto_gtin_destino
                  AND producto_cuenta_id = p_cuenta_id
                  AND atributo_id = r_atributo.atributo_id;
            END IF;
        END;
    END LOOP;

    -- Confirmar transacción
    COMMIT;

-- Manejo de errores específicos
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            ROLLBACK;
            RAISE;
END P_REPLICAR_ATRIBUTOS;
/


-- JOBS

-- J_LIMPIA_TRAZA: Limpia las entradas de la tabla TRAZA que tengan más de 1 año.
-- Para probarlo se pueden hacer con las que tengan más de un minuto y luego modificarlo.

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
job_name => 'J_LIMPIA_TRAZA',
job_type => 'PLSQL_BLOCK',
job_action => 'BEGIN 
DELETE FROM TRAZA  
WHERE MONTHS_BETWEEN(SYSDATE, FECHA) >= 12; --Borra los que tengan un año
END;',
start_date => SYSDATE,
repeat_interval => 'FREQ=DAILY; INTERVAL=1',
end_date => TO_DATE('01-JAN-2030 00:00:00', 'DD-MON-YYYY HH24:MI:SS'),
enabled => TRUE,
comments => 'Limpia las entradas de la tabla TRAZA que tengan más de 1 año.');
END;
/

----------------------------------------------------------------------------------------------------------------

-- J_ACTUALIZA_PRODUCTOS. Actualiza desde la tabla de productos externos los productos
-- de la tabla Productos para todas las cuentas de la base de datos llamando a P_ACTUALIZAR_PRODUCTOS.

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
job_name => 'J_ACTUALIZA_PRODUCTOS',
job_type => 'PLSQL_BLOCK',
job_action => 'BEGIN 
    FOR CUENTA IN (SELECT ID FROM CUENTA) LOOP  
        P_ACTUALIZAR_PRODUCTOS(CUENTA.ID);  
    END LOOP; 
END;',
start_date => SYSDATE,
repeat_interval => 'FREQ=WEEKLY; INTERVAL=1', --Semanalmente
end_date => TO_DATE('01-1-2030 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),
enabled => TRUE,
comments => 'Actualiza desde la tabla de productos externos los productos de
la tabla Productos para todas las cuentas de la base de datos llamando a
P_ACTUALIZAR_PRODUCTOS.');
END;
/

SELECT * FROM dba_scheduler_jobs WHERE  job_name = 'J_LIMPIA_TRAZA' OR job_name = 'J_ACTUALIZA_PRODUCTOS';

------------------------------------------------------------------------------------------------------------------------------
-- Alguna política de gestión de contraseñas
-- VAMOS A CREAR UN PROFILE CON ALGUNAS CARACTERISTICAS QUE ES EL QUE VAN A TENER LOS USUARIOS DE LA APLICACION

 CREATE PROFILE USERPLYTIX_PROFILE LIMIT
    CONNECT_TIME UNLIMITED  --Duración máxima de la conexión.
    IDLE_TIME 20            --Minutos de tiempo muerto en una sesión.
    FAILED_LOGIN_ATTEMPTS 4 --nº máximo de intentos para bloquear cuenta.
    PASSWORD_LIFE_TIME 90-- Nº de días de expiración de la password.
    PASSWORD_GRACE_TIME 3;  --Periodo de gracia después de los 90 días.

 SELECT * FROM DBA_PROFILES WHERE PROFILE = 'USERPLYTIX_PROFILE';

------------------------------------------------------------------------------------------------------------------------------


-- PRUEBAS FUNCIONES

-- 9) CREATE USER

SELECT * FROM USUARIO WHERE NOMBREUSUARIO = 'jdoe';

DECLARE
    v_usuario USUARIO%ROWTYPE;
BEGIN
    -- Simulamos datos de entrada
    v_usuario.Id := 888;
    v_usuario.NombreUsuario := 'jdoe';
    v_usuario.NombreCompleto := 'John Doe';
    v_usuario.Avatar := 'https://example.com/avatar.jpg';
    v_usuario.CorreoElectronico := 'jdoe@example.com';
    v_usuario.Telefono := 123456789;
    v_usuario.Cuenta_Id := 1;
    v_usuario.Cuenta_Dueno := NULL;

    -- Llamamos al procedimiento con el usuario, el rol deseado y una contraseña
    PKG_ADMIN_PRODUCTOS.P_CREAR_USUARIO(
        p_usuario => v_usuario,
        p_rol => 'ROL_USUARIO',
        p_password => 'PRUEBA'
    );
END;
/

SELECT * FROM USUARIO WHERE NOMBREUSUARIO = 'jdoe';

-- PRUEBAS FUNCIONES
-- 1) F_OBTENER_PLAN_CUENTA
DECLARE
    RES PLYTIX.PLAN%ROWTYPE;
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS.F_OBTENER_PLAN_CUENTA(2);
    DBMS_OUTPUT.PUT_LINE('PLAN: ID = ' || res.id || ' NOMBRE: ' || res.nombre);
END;

-- COMPROBAMOS QUE NOS DEVUELVE ERROR SI INTENTAMOS OBTENER EL PLAN DE UNA CUENTA DIFERENTE A LA QUE TIENE EL USUARIO
DECLARE
    RES PLYTIX.PLAN%ROWTYPE;
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS.F_OBTENER_PLAN_CUENTA(4);
    DBMS_OUTPUT.PUT_LINE('PLAN: ID = ' || res.id || ' NOMBRE: ' || res.nombre);
END;

-- 2) F_CONTAR_PRODUCTOS_CUENTA

DECLARE
    RES NUMBER;
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS.F_CONTAR_PRODUCTOS_CUENTA(2);
    DBMS_OUTPUT.PUT_LINE('NUMERO PRODUCTOS: ' || res);
END;
/

SELECT COUNT(*) FROM PRODUCTO WHERE CUENTA_ID = 2;

-- 3) F_VALIDAR_ATRIBUTOS_PRODUCTO
-- VERIFICA QUE TODOS LOS ATRIBUTOS DE LA TABLA ATRIBUTOS TENGAN UN VALOR EN ATRIBUTO_PRODUCTO PARA UN PRODUCTO EN CONCRETO
-- DEVUELVE TRUE YA QUE PARA EL PRODUCTO CON GTIN 152 Y CUENTA_ID 2 TODOS LOS ATRIBUTOS TIENEN VALOR
DECLARE
    RES NUMBER;
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS.F_VALIDAR_ATRIBUTOS_PRODUCTO(152, 2);
    
    IF RES = 1 THEN
        DBMS_OUTPUT.PUT_LINE('VALIDAR TRUE');
    ELSE 
        DBMS_OUTPUT.PUT_LINE('VALIDAR FALSE');
    END IF;
END;

-- 4) F_NUM_CATEGORIAS_CUENTA

DECLARE
    RES NUMBER;
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS.F_NUM_CATEGORIAS_CUENTA(2);
    DBMS_OUTPUT.PUT_LINE('NUMERO CATEGORIAS: ' || res);
END;


-- 5) P_ACTUALIZAR_NOMBRE_PRODUCTO
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_NOMBRE_PRODUCTO(101, 2, 'DRON');
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;
/

-- CASO EN EL QUE EL NOMBRE ES NULO O VACIO (ME DEVUELVE UN ERROR PERSONALIZADO ORA-20004)
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_NOMBRE_PRODUCTO(101, 2, NULL);
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;

-- 7) P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES
-- SI NO HAY ALGUNA RELACION ENTRE PRODUCTO CON SUS TABLAS RELACIONADAS, NO PASA NADA, YA QUE EL DELETE ELIMINA LA FILA O NO BORRA NADA, PERO NO LANZA UN ERROR
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(888, 2);
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;

-- 8) P_ACTUALIZAR_PRODUCTOS -> DEMO

-- PRIMERO VEMOS QUE PRODUCTOS HAY EN PRODUCTOS_EXT Y NO EN LA TABLA PRODUCTO
SELECT *
FROM PRODUCTOS_EXT pe
WHERE NOT EXISTS (
    SELECT 1
    FROM PRODUCTO p
    WHERE p.SKU = pe.SKU  -- Correlación con la fila externa
);

SELECT * FROM PRODUCTO WHERE SKU = 'SKU DEL PRODUCTO QUE NO EXISTE'; -- VEMOS QUE NO NOS DEVUELVE NADA

-- AHORA EJECUTAMOS EL PROCEDIMIENTO
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_PRODUCTOS(2);
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;
/

-- VEMOS QUE AHORA SI QUE EXISTE EL PRODUCTO EN LA TABLA PRODUCTO
SELECT * FROM PRODUCTO WHERE SKU = 'SKU DEL PRODUCTO QUE NO EXISTE'; -- VEMOS QUE AHORA SI QUE NOS DEVUELVE EL PRODUCTO

-- VAMOS AHORA A COMPROBAR SI CAMBIAMOS EL NOMBRE DEL PRODUCTO EN LA TABLA PRODUCTO, CUANDO LLAMEMOS AL PROCEDIMIENTO, SE ACTUALIZA AL NOMBRE DE LA TABLA PRODUCTOS_EXT
UPDATE PRODUCTO SET NOMBRE = 'NUEVO NOMBRE' WHERE SKU = 'SKU DEL PRODUCTO QUE NO EXISTE';

BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_PRODUCTOS(2);
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;

SELECT * FROM PRODUCTO WHERE SKU = 'SKU DEL PRODUCTO QUE NO EXISTE'; -- VEMOS QUE AHORA SI QUE NOS DEVUELVE EL PRODUCTO CON EL NOMBRE ACTUALIZADO

-- AHORA VAMOS A TENER UN PRODUCTO EN LA TABLA PRODUCTO QUE NO ESTÁ EN PRODUCTOS_EXT, ESTO DEBERIA ELIMINARLO DE LA TABLA PRODUCTO
-- PRIMERO INSERTAMOS UN PRODUCTO EN LA TABLA PRODUCTO QUE NO ESTÁ EN PRODUCTOS_EXT
INSERT INTO PRODUCTO VALUES(888, 'SKU_777', 'CAMISETA REAL MADRID', NULL, 'CAMISETA MADRID', TO_DATE('29/05/2024', 'DD/MM/YYYY'), NULL, 2, 'S');
COMMIT;

SELECT * FROM PRODUCTO WHERE GTIN = 888;

BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_PRODUCTOS(2);
    DBMS_OUTPUT.PUT_LINE('TERMINADO');
END;

SELECT * FROM PRODUCTO WHERE GTIN = 888; -- VEMOS QUE NO NOS DEVUELVE NADA, YA QUE EL PRODUCTO SE HA ELIMINADO


-- PARTE 2

-- 1) F_VALIDAR_PLAN_SUFICIENTE

-- CASO EN EL QUE LA CUENTA TIENE UN PLAN SUFICIENTE
DECLARE
    RES VARCHAR2(100);
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS_AVANZADO.F_VALIDAR_PLAN_SUFICIENTE(2);
    DBMS_OUTPUT.PUT_LINE(RES);
END;

-- AHORA VAMOS A MODIFICAR POR EJEMPLO EL NUMERO DE PRODUCTOS DEL PLAN PARA QUE NO SEA SUFICIENTE
UPDATE PLAN SET PRODUCTOS = 2 WHERE ID = 4; -- PONEMOS A 0 EL NUMERO DE PRODUCTOS DEL PLAN
COMMIT;

DECLARE
    RES VARCHAR2(100);
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS_AVANZADO.F_VALIDAR_PLAN_SUFICIENTE(2);
    DBMS_OUTPUT.PUT_LINE(RES);
END;

-- EL RESULTADO ES 'INSUFICIENTE: PRODUCTOS', YA QUE EL PLAN TIENE 2 PRODUCTOS Y LA CUENTA TIENE MAS DE 2 PRODUCTOS

-- 2) F_LISTA_CATEGORIAS_PRODUCTO
DECLARE
    RES VARCHAR2(100);
BEGIN
    RES := PLYTIX.PKG_ADMIN_PRODUCTOS_AVANZADO.F_LISTA_CATEGORIAS_PRODUCTO(101, 2);
    DBMS_OUTPUT.PUT_LINE(RES);
END;

-- RESULTADO: 'Recursos Humanos; Sociales;'

-- 3) P_MIGRAR_PRODUCTOS_A_CATEGORIA
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS_AVANZADO.P_MIGRAR_PRODUCTOS_A_CATEGORIA(2, 7, 6);
END;

-- VEMOS QUE TODAS LOS PRODUCTOS DE LA CUENTA 2 QUR TENIAN CATEGORIA 7 AHORA TIENEN CATEGORIA 6
-- HAY QUE TENER CUIDADO YA QUE LAS CATEGORIAS QUE SE LE PASA POR PARAMETRO, ESTAMOS COMPROBANDO QUE PERTENECEN A LA CUENTA

-- 4) P_REPLICAR_ATRIBUTOS
BEGIN
    PLYTIX.PKG_ADMIN_PRODUCTOS_AVANZADO.P_REPLICAR_ATRIBUTOS(2, 151, 152);
END;
/

-- VEMOS QUE LOS ATRIBUTOS DEL PRODUCTO 151 SE HAN COPIADO AL PRODUCTO 152
-- SI YA EXISTE, PERO TIENE DISTINTO NOMBRE, SE ACTUALIZA EL NOMBRE DEL ATRIBUTO
-- SI NO EXISTE, SE CREA UN NUEVO ATRIBUTO PARA EL PRODUCTO 152