-- CREAMOS LA TABLA DE TRAZAS PARA PODER SEGUIR LA TRAZA DE LOS ERRORES PRODUCIDOS

CREATE TABLE TRAZA (
    FECHA DATE,
    USUARIO VARCHAR2(40),
    CAUSANTE VARCHAR2(40),
    DESCRIPCION VARCHAR2(500)
);

-- CREAMOS EL PAQUETE PKG_ADMIN_PRODUCTOS QUE CONTIENE LAS FUNCIONES Y PROCEDIMIENTOS QUE SE VAN A UTILIZAR

create or replace PACKAGE PKG_ADMIN_PRODUCTOS AS

    -- DEFINIMOS LAS EXPCIONES PERSONALIZADAS QUE VAMOS A UTILIZAR, CON UN INDICE DE ERROR QUE NOSOTROS HEMOS PERSONALIZADO
    EXCEPTION_PLAN_NO_ASIGNADO EXCEPTION; -- Excepción personalizada para el caso de que no haya un plan asignado
    PRAGMA EXCEPTION_INIT(EXCEPTION_PLAN_NO_ASIGNADO, -20001);

    EXCEPTION_ASOCIACION_DUPLICADA EXCEPTION; -- Excepción personalizada para el caso de que la asociación ya exista
    PRAGMA EXCEPTION_INIT(EXCEPTION_ASOCIACION_DUPLICADA, -20002);

    EXCEPTION_USUARIO_EXISTENTE EXCEPTION; -- Excepción personalizada para el caso de que el usuario ya exista
    PRAGMA EXCEPTION_INIT(EXCEPTION_USUARIO_EXISTENTE, -20003);

    -- DEFINIMOS LAS FUNCIONES Y PROCEDIMIENTOS QUE VAMOS A UTILIZAR
    FUNCTION F_OBTENER_PLAN_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN PLAN%ROWTYPE;

    FUNCTION F_CONTAR_PRODUCTOS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN NUMBER;
    
    FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN NUMBER;

    FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN NUMBER;
    
    PROCEDURE  P_ACTUALIZAR_NOMBRE_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_nuevo_nombre IN 
    PRODUCTO.NOMBRE%TYPE);

    PROCEDURE  P_ASOCIAR_ACTIVO_A_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_producto_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_activo_id IN ACTIVO.ID%TYPE, 
    p_activo_cuenta_id IN ACTIVO.CUENTA_ID%TYPE);
    
    PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE);

    PROCEDURE P_ACTUALIZAR_PRODUCTOS(p_cuenta_id IN CUENTA.ID%TYPE);

    PROCEDURE P_CREAR_USUARIO(p_usuario IN USUARIO%ROWTYPE, p_rol IN VARCHAR, p_password 
    IN VARCHAR);

END PKG_ADMIN_PRODUCTOS;
/

-- AHORA DEFINIMOS EL CUERPO DEL PAQUETE DONDE VAN A ESTAR LAS FUNCIONES Y PROCEDIMIENTOS IMPLEMENTADOS

create or replace PACKAGE BODY PKG_ADMIN_PRODUCTOS AS

----------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDIMIENTSOS AUXILIARES QUE DEFINIMOS AQUI, PERO NO EN LA CABECERA DEL PAQUETE
PROCEDURE REGISTRA_ERRORES(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TRAZA VALUES(SYSDATE, USER, P_DONDE, P_MENSAJE);
    END;


FUNCTION F_ES_USUARIO_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
    RETURN NUMBER AS
    v_usuario_id NUMBER;
BEGIN
    -- OBTENEMOS EL ID DE SU CUENTA QUE HACE LA LLAMADA
    SELECT CUENTA_ID INTO v_usuario_id FROM USUARIO WHERE NOMBREUSUARIO = USER;

    -- COMPARAMOS EL ID DEL USUARIO CON EL ID DE LA CUENTA
    IF v_usuario_id = p_cuenta_id THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontró el usuario que realiza la llamada.');
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
        RETURN 0;
END F_ES_USUARIO_CUENTA;

-- 1 -

    FUNCTION F_OBTENER_PLAN_CUENTA (p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN PLAN%ROWTYPE AS
        v_plan PLAN%ROWTYPE;
        v_cuenta NUMBER;
        v_plan_cuenta CUENTA.PLAN_ID%TYPE;

    BEGIN

        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;
        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        SELECT PLAN_ID INTO v_plan_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_plan_cuenta IS NULL THEN
            RAISE EXCEPTION_PLAN_NO_ASIGNADO; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        SELECT * INTO v_plan FROM PLAN WHERE ID = v_plan_cuenta;

        RETURN v_plan;

    -- CAPTURA LAS EXCEPCIONES QUE PUEDAN OCURRIR Y NO HAYAMOS CONTROLADO PREVIAMENTE

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el plan para la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN EXCEPTION_PLAN_NO_ASIGNADO THEN
            DBMS_OUTPUT.PUT_LINE('No hay un plan asignado para la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END F_OBTENER_PLAN_CUENTA;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 2 -
    FUNCTION F_CONTAR_PRODUCTOS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN NUMBER AS
        v_num_productos NUMBER;
        v_cuenta NUMBER;

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;
        SELECT COUNT(*) INTO v_num_productos FROM PRODUCTO WHERE CUENTA_ID = p_cuenta_id;

        RETURN v_num_productos;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END F_CONTAR_PRODUCTOS_CUENTA;

-- 3 --------------------------------------------------
FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) 
        RETURN NUMBER IS

            CURSOR C_ATRIBUTO IS SELECT * FROM ATRIBUTO FOR UPDATE;

            -- Variables declaradas para almacenar los resultados de las consultas

            v_cuenta NUMBER; -- Para contar si existe la cuenta
            v_producto_cuenta NUMBER; -- Para contar si existe el producto
            v_valor NUMBER; -- Para almacenar el valor del atributo

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE TOO_MANY_ROWS; -- Lanza la excepción personalizada si no hay una cuenta asignada
        END IF;

        -- VERIFICAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO v_producto_cuenta FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF v_producto_cuenta = 0 THEN
            RAISE TOO_MANY_ROWS; -- Lanza la excepción personalizada si no hay un producto asignado
        END IF;

        -- RECORREMOS EL CURSOR PARA VERIFICAR SI EL PRODUCTO TIENE ATRIBUTOS ASIGNADOS
        FOR R_ATRIBUTO IN C_ATRIBUTO LOOP

            -- COMPROBAMOS SI EXISTE UN VALOR DE ESE ATRIBUTO PARA UN PRODUCTO DADO
            SELECT COUNT(*) INTO v_valor FROM ATRIBUTOS_PRODUCTO WHERE PRODUCTO_GTIN = p_producto_gtin AND Atributo_Id = R_ATRIBUTO.ID AND VALOR IS NOT NULL;

            IF v_valor = 0 THEN
                DBMS_OUTPUT.PUT_LINE('El producto ' || p_producto_gtin || ' no tiene el atributo ' || R_ATRIBUTO.ID);
                RETURN 0; -- Si no existe el valor, retornamos falso
            END IF;
        END LOOP;

        RETURN 1; -- Si todos los atributos tienen valor, retornamos verdadero

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END F_VALIDAR_ATRIBUTOS_PRODUCTO;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 4 -

    FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN NUMBER AS
        v_num_categorias NUMBER;
        v_cuenta NUMBER;

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        SELECT COUNT(*) INTO v_num_categorias FROM CATEGORIA WHERE CUENTA_ID = p_cuenta_id;

        RETURN v_num_categorias;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró la cuenta con ID: ' || p_cuenta_id);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;

    END F_NUM_CATEGORIAS_CUENTA;

-- 5 ---------------------------------------------------------------------


    PROCEDURE P_ACTUALIZAR_NOMBRE_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_nuevo_nombre IN 
        PRODUCTO.NOMBRE%TYPE) AS

        -- Variables declaradas para almacenar los resultados de las consultas
        v_cuenta NUMBER; -- Para contar si existe la cuenta
        v_producto_cuenta NUMBER; -- Para contar si existe el producto
        v_filas_afectadas NUMBER; -- Para contar las filas afectadas por la actualización

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        -- VERIFICAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO v_producto_cuenta FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF v_producto_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un producto asignado
        END IF;

        -- ACTUALIZAMOS EL NOMBRE DEL PRODUCTO
        UPDATE PRODUCTO SET NOMBRE = p_nuevo_nombre WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            ROLLBACK;
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END P_ACTUALIZAR_NOMBRE_PRODUCTO;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 6 - MODIFICAR EL TIPO DE EXCEPCION A EXCEPTION_ASOCIACION_DUPLICADA (AHORA MISMO ESTA PUESTO QUE LANCE NO_DATA_FOUND)

    PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_producto_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_activo_id IN ACTIVO.ID%TYPE, 
        p_activo_cuenta_id IN ACTIVO.CUENTA_ID%TYPE) AS

        -- Variables declaradas para almacenar los resultados de las consultas
        v_cuenta NUMBER; -- Para contar si existe la cuenta
        v_producto_cuenta NUMBER; -- Para contar si existe el producto
        v_activos_cuenta NUMBER; -- Para contar si existe el activo
        v_asociacion_existente NUMBER; -- Para contar si ya existe la asociación

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_producto_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        -- VERIFICAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO v_producto_cuenta FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_producto_cuenta_id;

        IF v_producto_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un producto asignado
        END IF;

        -- VERIFICAMOS SI EL ACTIVO EXISTE
        SELECT COUNT(*) INTO v_activos_cuenta FROM ACTIVO WHERE ID = p_activo_id AND CUENTA_ID = p_activo_cuenta_id;

        IF v_activos_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un activo asignado
        END IF;

        -- COMPROBAMOS SI YA EXISTE UNA ASOCIACION ENTRE EL PRODUCTO Y EL ACTIVO
        SELECT COUNT(*) INTO v_asociacion_existente FROM REL_PROD_ACTIV
        WHERE Producto_GTIN = p_producto_gtin
            AND Producto_Cuenta_Id = p_producto_cuenta_id
            AND Activo_Id = p_activo_id
            AND Activo_Cuenta_Id = p_activo_cuenta_id;

        IF v_asociacion_existente > 0 THEN
            RAISE EXCEPTION_ASOCIACION_DUPLICADA; -- Lanza la excepción personalizada si ya existe la asociación
        END IF;

        -- SI NO HAY ERRORES, ASOCIAMOS EL ACTIVO AL PRODUCTO
        INSERT INTO REL_PROD_ACTIV (Activo_Id, Activo_Cuenta_Id, Producto_GTIN, Producto_Cuenta_Id)
        VALUES (p_activo_id, p_activo_cuenta_id, p_producto_gtin, p_producto_cuenta_id);

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto o activo para la cuenta con ID: ' || p_producto_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN EXCEPTION_ASOCIACION_DUPLICADA THEN
            DBMS_OUTPUT.PUT_LINE('Ya existe una asociación entre el producto ' || p_producto_gtin || ' y el activo ' || p_activo_id);
            ROLLBACK;
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            ROLLBACK;
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END P_ASOCIAR_ACTIVO_A_PRODUCTO;

-- 7) ----------------------------------------------------------------------

    PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) AS

        -- Variables declaradas para almacenar los resultados de las consultas
        v_cuenta NUMBER; -- Para contar si existe la cuenta
        v_producto_cuenta NUMBER; -- Para contar si existe el producto

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        -- VERIFICAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO v_producto_cuenta FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF v_producto_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un producto asignado
        END IF;

        -- BORRAMOS DE LAS TABLAS SECUNDARIAS ANTES QUE DE LA TABLA PRINCIPAL
        DELETE FROM REL_PROD_ACTIV WHERE Producto_GTIN = p_producto_gtin AND Producto_Cuenta_Id = p_cuenta_id;

        DELETE FROM ATRIBUTOS_PRODUCTO WHERE Producto_GTIN = p_producto_gtin AND Producto_Cuenta_Id = p_cuenta_id;

        DELETE FROM REL_PROD_CATEG WHERE Producto_GTIN = p_producto_gtin AND Producto_Cuenta_Id = p_cuenta_id;

        DELETE FROM RELACIONADO WHERE Producto_GTIN = p_producto_gtin AND Producto_Cuenta_Id = p_cuenta_id;

        -- BORRAMOS EL PRODUCTO DE LA TABLA PRINCIPAL
        DELETE FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            ROLLBACK;
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES;

    -- 8 -
    PROCEDURE P_ACTUALIZAR_PRODUCTOS(p_cuenta_id IN CUENTA.ID%TYPE) IS
        CURSOR C_PRODUCTOS_EXT IS SELECT * FROM PRODUCTOS_EXT WHERE CUENTA_ID = p_cuenta_id;
        CURSOR C_PRODUCTOS IS SELECT * FROM PRODUCTO WHERE CUENTA_ID = p_cuenta_id;

        -- Variables declaradas para almacenar los resultados de las consultas
        v_cuenta NUMBER;
        v_num_productos NUMBER;
        v_producto_nombre PRODUCTO.NOMBRE%TYPE;
        v_producto_gtin PRODUCTO.GTIN%TYPE;

    BEGIN
        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;

        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        FOR R_PRODUCTO_EXT IN C_PRODUCTOS_EXT LOOP

            SELECT COUNT(*) INTO v_num_productos FROM PRODUCTO WHERE SKU = R_PRODUCTO_EXT.SKU AND CUENTA_ID = p_cuenta_id;

            IF v_num_productos = 0 THEN
                -- SI NO EXISTE EL PRODUCTO EN LA TABLA INTERNA, LO INSERTAMOS
                INSERT INTO PRODUCTO(SKU, NOMBRE, TEXTOCORTO, CREADO, CUENTA_ID) VALUES (R_PRODUCTO_EXT.SKU, R_PRODUCTO_EXT.NOMBRE, R_PRODUCTO_EXT.TEXTOCORTO, R_PRODUCTO_EXT.CREADO, R_PRODUCTO_EXT.CUENTA_ID);

            ELSE 

                SELECT NOMBRE INTO V_PRODUCTO_NOMBRE FROM PRODUCTO WHERE SKU = R_PRODUCTO_EXT.SKU AND CUENTA_ID = p_cuenta_id;
                SELECT GTIN INTO V_PRODUCTO_GTIN FROM PRODUCTO WHERE SKU = R_PRODUCTO_EXT.SKU AND CUENTA_ID = p_cuenta_id;
                -- VERIFICAMOS SI SE HA MODIFICADO EL NOMBRE DEL PRODUCTO
                IF R_PRODUCTO_EXT.NOMBRE !=  V_PRODUCTO_NOMBRE THEN
                    P_ACTUALIZAR_NOMBRE_PRODUCTO(V_PRODUCTO_GTIN, p_cuenta_id, R_PRODUCTO_EXT.NOMBRE);
                END IF;
            END IF;
        END LOOP;

        -- POR CADA FILA DE LA TABLA PRODUCTOS QUE NO SE ENCUENTRE EN LA EXTERNA, SE BORRA ESA FILA

        FOR R_PRODUCTO IN C_PRODUCTOS LOOP

            SELECT COUNT(*) INTO v_num_productos FROM PRODUCTOS_EXT WHERE SKU = R_PRODUCTO.SKU AND CUENTA_ID = p_cuenta_id;

            IF v_num_productos = 0 THEN
                P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(R_PRODUCTO.GTIN, p_cuenta_id);
            END IF;
        END LOOP;

        COMMIT;

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
    END P_ACTUALIZAR_PRODUCTOS;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- 9

    PROCEDURE P_CREAR_USUARIO(
    p_usuario  IN USUARIO%ROWTYPE,
    p_rol      IN VARCHAR,
    p_password IN VARCHAR
)
IS
    v_usuario_id NUMBER;
    NOMBRE_USER VARCHAR2(100);
BEGIN
    NOMBRE_USER := UPPER(p_usuario.NOMBREUSUARIO);

    -- Verifica si el usuario ya existe
    SELECT COUNT(*) INTO v_usuario_id 
    FROM USUARIO 
    WHERE UPPER(NOMBREUSUARIO) = NOMBRE_USER;

    IF v_usuario_id = 1 THEN
        RAISE EXCEPTION_USUARIO_EXISTENTE; -- Lanza la excepción personalizada si el usuario ya existe
    END IF;

    -- Inserta los datos en la tabla Usuario
    INSERT INTO Usuario (
        Id,
        NombreUsuario,
        NombreCompleto,
        Avatar,
        CorreoElectronico,
        Telefono,
        Cuenta_Id,
        Cuenta_Dueno
    ) VALUES (
        p_usuario.Id,
        p_usuario.NombreUsuario,
        p_usuario.NombreCompleto,
        p_usuario.Avatar,
        p_usuario.CorreoElectronico,
        p_usuario.Telefono,
        p_usuario.Cuenta_Id,
        p_usuario.Cuenta_Dueno
    );

    COMMIT;

    -- Crear el usuario en Oracle
    EXECUTE IMMEDIATE 'CREATE USER "' || NOMBRE_USER || '" IDENTIFIED BY "' || p_password || '"';

    -- Asignar el rol
    EXECUTE IMMEDIATE 'GRANT "' || p_rol || '" TO "' || NOMBRE_USER || '"';

    -- Asignar el perfil
    EXECUTE IMMEDIATE 'ALTER USER "' || NOMBRE_USER || '" PROFILE USERPLYTIX_PROFILE';

    -- Crear sinónimos
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".USUARIO_ESTANDAR FOR V_USUARIO_ESTANDAR';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".PRODUCTO FOR V_USUARIO_PRODUCTO';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".ACTIVO FOR V_USUARIO_ACTIVO';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".ATRIBUTO FOR V_USUARIO_ATRIBUTO';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".PLAN FOR V_USUARIO_PLAN';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".PRODUCTO_PUBLICO FOR V_PRODUCTO_PUBLICO';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".REL_ACTIVO_CATEGORIA FOR V_ACTIVO_REL_ACTIVO_CATEGORIA';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".CATEGORIA FOR V_CATEGORIA';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".REL_PRODUCTO_CATEGORIA FOR V_REL_PRODUCTO_CATEGORIA';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".RELACIONADO FOR V_RELACIONADO';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM "' || NOMBRE_USER || '".ATRIBUTO_PRODUCTO FOR V_ATRIBUTO_PRODUCTO';

EXCEPTION
        WHEN EXCEPTION_USUARIO_EXISTENTE THEN
            REGISTRA_ERRORES('Error inesperado Usuario existente: ' || SQLERRM, $$PLSQL_UNIT);
            DBMS_OUTPUT.PUT_LINE('Error inesperado Usuario existente: ' || SQLERRM);
            RAISE;

        WHEN OTHERS THEN
            DELETE FROM USUARIO WHERE NOMBREUSUARIO = NOMBRE_USER;
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado Al Crear Usuario Nuevo: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
END P_CREAR_USUARIO;

END PKG_ADMIN_PRODUCTOS;
/


-- CREAMOS ESTE JOB QUE RECOJA LOS USUARIOS QUE ESTAN CREADOS PERO NO ESTAN EN LA BASE DE DATOS DEL SISTEMA, Y LOS ELIMINE
-- EL JOB SE EJECUTARA UNA VEZ AL DIA A LAS 3 DE LA MAÑANA

BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'JOB_LIMPIEZA_USUARIOS_HUERFANOS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
      DECLARE
        CURSOR c IS
          SELECT username FROM all_users
          WHERE username NOT IN (
            SELECT UPPER(NombreUsuario) FROM Usuario
          );
      BEGIN
        FOR r IN c LOOP
          BEGIN
            EXECUTE IMMEDIATE ''DROP USER "'' || r.username || ''" CASCADE'';
            DBMS_OUTPUT.PUT_LINE(''Usuario eliminado: '' || r.username);
          EXCEPTION
            WHEN OTHERS THEN
              DBMS_OUTPUT.PUT_LINE(''Error eliminando usuario '' || r.username || '': '' || SQLERRM);
          END;
        END LOOP;
      END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=3;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Elimina usuarios del sistema que no estén en la tabla Usuario'
  );
END;
/

DECLARE
  v_usuario USUARIO%ROWTYPE;
BEGIN
  -- Rellenamos el registro con los valores deseados
  v_usuario.Id := 126;
  v_usuario.NombreUsuario := 'elena87';
  v_usuario.NombreCompleto := 'Marciano Pera Arias';
  v_usuario.Avatar := NULL; -- Aquí puedes poner una URL o una cadena si usas avatar
  v_usuario.CorreoElectronico := 'elena87@example.org';
  v_usuario.Telefono := '+34 723 463 244';
  v_usuario.Cuenta_Id := 3;
  v_usuario.Cuenta_Dueno := NULL; -- Si aplica, pon el ID del dueño; si no, déjalo como NULL

  -- Llamamos al procedimiento
  P_CREAR_USUARIO(
    p_usuario  => v_usuario,
    p_rol      => 'USUARIO_ESTANDAR', -- Asegúrate de que este rol exista en la BBDD
    p_password => 'MiContraseñaSegura123' -- Define la contraseña que tendrá el nuevo usuario
  );
END;
/
