-- CREAMOS LA TABLA DE TRAZAS PARA PODER SEGUIR LA TRAZA DE LOS ERRORES PRODUCIDOS

CREATE TABLE TRAZA (
    FECHA DATE,
    USUARIO VARCHAR2(40),
    CAUSANTE VARCHAR2(40),
    DESCRIPCION VARCHAR2(500)
);

-- CREAMOS EL PAQUETE PKG_ADMIN_PRODUCTOS QUE CONTIENE LAS FUNCIONES Y PROCEDIMIENTOS QUE SE VAN A UTILIZAR

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS AS

    -- DEFINIMOS LAS EXPCIONES PERSONALIZADAS QUE VAMOS A UTILIZAR, CON UN INDICE DE ERROR QUE NOSOTROS HEMOS PERSONALIZADO
    EXCEPTION_PLAN_NO_ASIGNADO EXCEPTION; -- Excepción personalizada para el caso de que no haya un plan asignado
    PRAGMA EXCEPTION_INIT(EXCEPTION_PLAN_NO_ASIGNADO, -20001);

    EXCEPTION_ASOCIACION_DUPLICADA EXCEPTION; -- Excepción personalizada para el caso de que la asociación ya exista
    PRAGMA EXCEPTION_INIT(EXCEPTION_ASOCIACION_DUPLICADA, -20002);

    -- DEFINIMOS LAS FUNCIONES Y PROCEDIMIENTOS QUE VAMOS A UTILIZAR
    FUNCTION F_OBTENER_PLAN_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN PLAN%ROWTYPE;

    FUNCTION F_CONTAR_PRODUCTOS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN NUMBER;

    FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN BOOLEAN;

    FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) RETURN NUMBER;

    PROCEDURE  P_ACTUALIZAR_NOMBRE_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_nuevo_nombre IN 
    PRODUCTO.NOMBRE%TYPE);

    PROCEDURE  P_ASOCIAR_ACTIVO_A_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_producto_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_activo_id IN ACTIVOS.ID%TYPE, 
    p_activo_cuenta_id IN ACTIVOS.CUENTA_ID%TYPE);

    PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE);

    PROCEDURE P_ACTUALIZAR_PRODUCTOS(p_cuenta_id IN CUENTA.ID%TYPE);

    PROCEDURE P_CREAR_USUARIO(p_usuario IN USUARIO%ROWTYPE, p_rol IN VARCHAR, p_password 
    IN VARCHAR);

END;
/

-- AHORA DEFINIMOS EL CUERPO DEL PAQUETE DONDE VAN A ESTAR LAS FUNCIONES Y PROCEDIMIENTOS IMPLEMENTADOS

CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS AS

----------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDIMIENTSOS AUXILIARES QUE DEFINIMOS AQUI, PERO NO EN LA CABECERA DEL PAQUETE
PROCEDURE REGISTRA_ERRORES(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TRAZA VALUES(SYSDATE, USER, DONDE, P_MENSAJE);
    END;
/

FUNCTION F_ES_USUARIO_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
    RETURN NUMBER AS
    v_usuario_id NUMBER;
BEGIN
    -- OBTENEMOS EL ID DEL USUARIO QUE HACE LA LLAMADA
    SELECT ID INTO v_usuario_id FROM USUARIO WHERE USERNAME = USER;

    -- COMPARAMOS EL ID DEL USUARIO CON EL ID DE LA CUENTA
    IF v_usuario_id = p_cuenta_id THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontró el usuario que realiza la llamada.');
        RETURN FALSE;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
        RETURN FALSE;
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

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 3 -
FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) 
        RETURN NUMBER IS

            CURSOR C_ATRIBUTO IS SELECT * FROM ATRIBUTO;

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

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 5 -

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
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END P_ACTUALIZAR_NOMBRE_PRODUCTO;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 6 - MODIFICAR EL TIPO DE EXCEPCION A EXCEPTION_ASOCIACION_DUPLICADA (AHORA MISMO ESTA PUESTO QUE LANCE NO_DATA_FOUND)

    PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_producto_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_activo_id IN ACTIVOS.ID%TYPE, 
        p_activo_cuenta_id IN ACTIVOS.CUENTA_ID%TYPE) AS

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
            AND Activo_Cuenta_Id = p_activo_cuenta_id FOR UPDATE;

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
            RAISE;
        WHEN EXCEPTION_ASOCIACION_DUPLICADA THEN
            DBMS_OUTPUT.PUT_LINE('Ya existe una asociación entre el producto ' || p_producto_gtin || ' y el activo ' || p_activo_id);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
    END P_ASOCIAR_ACTIVO_A_PRODUCTO;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- 7 -
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
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            ROLLBACK;
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

    CREATE OR REPLACE PROCEDURE P_CREAR_USUARIO(
        p_usuario IN USUARIO%ROWTYPE,
        p_rol IN VARCHAR2,
        p_password IN VARCHAR2
    ) AS
        -- Variables locales
        v_usuario_existe NUMBER := 0;
        v_rol_valido BOOLEAN := FALSE;
        v_sql VARCHAR2(4000);
        v_user_id NUMBER;
        
        -- Excepciones personalizadas
        e_usuario_existente EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_usuario_existente, -20001);
        e_rol_invalido EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_rol_invalido, -20002);
        e_password_invalido EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_password_invalido, -20003);
    
    BEGIN
        -- 1. VALIDACIONES INICIALES
        -- Verificar si el usuario ya existe
        SELECT COUNT(*) INTO v_usuario_existe 
        FROM USUARIO 
        WHERE UPPER(USERNAME) = UPPER(p_usuario.USERNAME);
        
        IF v_usuario_existe > 0 THEN
            RAISE e_usuario_existente;
        END IF;
        
        -- Validar rol (ejemplo con roles predefinidos)
        v_rol_valido := p_rol IN ('ADMIN', 'EDITOR', 'LECTOR', 'INVITADO');
        IF NOT v_rol_valido THEN
            RAISE e_rol_invalido;
        END IF;
        
        -- Validar contraseña (mínimo 8 caracteres)
        IF LENGTH(p_password) < 8 THEN
            RAISE e_password_invalido;
        END IF;
    
        -- 2. CREACIÓN DEL USUARIO EN LA BASE DE DATOS
        -- Insertar en tabla USUARIO
        INSERT INTO USUARIO (
            ID,
            USERNAME,
            NOMBRE,
            APELLIDO,
            EMAIL,
            FECHA_CREACION,
            ULTIMO_ACCESO,
            ESTADO
        ) VALUES (
            SEQ_USUARIO.NEXTVAL,
            p_usuario.USERNAME,
            p_usuario.NOMBRE,
            p_usuario.APELLIDO,
            p_usuario.EMAIL,
            SYSDATE,
            NULL,
            'ACTIVO'
        ) RETURNING ID INTO v_user_id;
    
    -- 3. ASIGNACIÓN DE PERMISOS Y ROLES
    -- Crear usuario en el sistema (si se usa autenticación de BD)
    BEGIN
        v_sql := 'CREATE USER ' || p_usuario.USERNAME || ' IDENTIFIED BY "' || p_password || '"';
        EXECUTE IMMEDIATE v_sql;
        
        -- Asignar roles según configuración
        CASE p_rol
            WHEN 'ADMIN' THEN
                EXECUTE IMMEDIATE 'GRANT DBA TO ' || p_usuario.USERNAME;
            WHEN 'EDITOR' THEN
                EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO ' || p_usuario.USERNAME;
                EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON SCHEMA_PROYECTO.* TO ' || p_usuario.USERNAME;
            WHEN 'LECTOR' THEN
                EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || p_usuario.USERNAME;
                EXECUTE IMMEDIATE 'GRANT SELECT ON SCHEMA_PROYECTO.* TO ' || p_usuario.USERNAME;
            ELSE -- INVITADO
                EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || p_usuario.USERNAME;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error al crear usuario en BD: ' || SQLERRM);
            RAISE;
    END;
    
    -- 4. CREACIÓN DE SINÓNIMOS (OPCIONAL)
    BEGIN
        FOR tab_rec IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'SCHEMA_PROYECTO') LOOP
            v_sql := 'CREATE SYNONYM ' || tab_rec.TABLE_NAME || ' FOR SCHEMA_PROYECTO.' || tab_rec.TABLE_NAME;
            EXECUTE IMMEDIATE v_sql;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Advertencia: Error creando sinónimos: ' || SQLERRM);
    END;
    
    -- 5. CONFIGURACIÓN DE CONTEXTO DE APLICACIÓN (OPCIONAL)
    BEGIN
        INSERT INTO CONTEXTOS_APLICACION (
            USUARIO_ID,
            ROL,
            FECHA_CREACION
        ) VALUES (
            v_user_id,
            p_rol,
            SYSDATE
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Advertencia: Error configurando contexto: ' || SQLERRM);
    END;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Usuario ' || p_usuario.USERNAME || ' creado exitosamente con rol ' || p_rol);
    
    EXCEPTION
        WHEN e_usuario_existente THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: El usuario ' || p_usuario.USERNAME || ' ya existe');
            INSERT INTO TRAZA VALUES(
                SYSDATE, 
                USER, 
                'P_CREAR_USUARIO', 
                '-20001 - Usuario existente: ' || p_usuario.USERNAME
            );
            RAISE;
            
        WHEN e_rol_invalido THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: Rol ' || p_rol || ' no válido');
            INSERT INTO TRAZA VALUES(
                SYSDATE, 
                USER, 
                'P_CREAR_USUARIO', 
                '-20002 - Rol inválido: ' || p_rol
            );
            RAISE;
            
        WHEN e_password_invalido THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: La contraseña debe tener al menos 8 caracteres');
            INSERT INTO TRAZA VALUES(
                SYSDATE, 
                USER, 
                'P_CREAR_USUARIO', 
                '-20003 - Contraseña inválida'
            );
            RAISE;
            
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error inesperado al crear usuario: ' || SQLERRM);
            INSERT INTO TRAZA VALUES(
                SYSDATE, 
                USER, 
                'P_CREAR_USUARIO', 
                SQLCODE || ' - ' || SUBSTR(SQLERRM, 1, 200)
            );
            RAISE;
    END P_CREAR_USUARIO;

END PKG_ADMIN_PRODUCTOS;
/
    -- CASOS DE PRUEBA (LO PIDE EL ENUNCIADO)

    -- Procedimiento de pruebas
    CREATE OR REPLACE PROCEDURE TEST_P_CREAR_USUARIO AS
        v_usuario USUARIO%ROWTYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== INICIO PRUEBAS P_CREAR_USUARIO ===');
    
        -- Caso 1: Creación exitosa de usuario ADMIN
        BEGIN
            v_usuario.USERNAME := 'admin_test';
            v_usuario.NOMBRE := 'Administrador';
            v_usuario.APELLIDO := 'Prueba';
            v_usuario.EMAIL := 'admin@test.com';
            
            P_CREAR_USUARIO(v_usuario, 'ADMIN', 'SecurePass123');
            DBMS_OUTPUT.PUT_LINE('Prueba 1: OK - Usuario ADMIN creado correctamente');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Prueba 1: FALLÓ - ' || SQLERRM);
        END;
        
        -- Caso 2: Usuario existente (debería fallar)
        BEGIN
            P_CREAR_USUARIO(v_usuario, 'ADMIN', 'SecurePass123');
            DBMS_OUTPUT.PUT_LINE('Prueba 2: FALLÓ - No detectó usuario existente');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20001 THEN
                    DBMS_OUTPUT.PUT_LINE('Prueba 2: OK - Correctamente detectado usuario existente');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Prueba 2: FALLÓ - Error inesperado: ' || SQLERRM);
                END IF;
        END;
        
        -- Caso 3: Rol inválido (debería fallar)
        BEGIN
            v_usuario.USERNAME := 'test_invalido';
            P_CREAR_USUARIO(v_usuario, 'ROL_INVALIDO', 'SecurePass123');
            DBMS_OUTPUT.PUT_LINE('Prueba 3: FALLÓ - No detectó rol inválido');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20002 THEN
                    DBMS_OUTPUT.PUT_LINE('Prueba 3: OK - Correctamente detectado rol inválido');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Prueba 3: FALLÓ - Error inesperado: ' || SQLERRM);
                END IF;
        END;
        
        -- Caso 4: Contraseña inválida (debería fallar)
        BEGIN
            v_usuario.USERNAME := 'test_pass';
            P_CREAR_USUARIO(v_usuario, 'LECTOR', '123');
            DBMS_OUTPUT.PUT_LINE('Prueba 4: FALLÓ - No detectó contraseña inválida');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20003 THEN
                    DBMS_OUTPUT.PUT_LINE('Prueba 4: OK - Correctamente detectada contraseña inválida');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Prueba 4: FALLÓ - Error inesperado: ' || SQLERRM);
                END IF;
        END;
    
        DBMS_OUTPUT.PUT_LINE('=== FIN PRUEBAS P_CREAR_USUARIO ===');

    END TEST_P_CREAR_USUARIO;


PROCEDURE REGISTRA_ERRORES(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TRAZA VALUES(SYSDATE, USER, DONDE, P_MENSAJE);
    END;
/

FUNCTION F_ES_USUARIO_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
    RETURN BOOLEAN AS
    v_usuario_id NUMBER;
BEGIN
    -- OBTENEMOS EL ID DEL USUARIO QUE HACE LA LLAMADA
    SELECT ID INTO v_usuario_id FROM USUARIO WHERE USERNAME = USER;

    -- COMPARAMOS EL ID DEL USUARIO CON EL ID DE LA CUENTA
    IF v_usuario_id = p_cuenta_id THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontró el usuario que realiza la llamada.');
        REGISTRA_ERRORES('No se encontró el usuario que realiza la llamada.', $$PLSQL_UNIT);
        RETURN FALSE;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
        RETURN FALSE;
END F_ES_USUARIO_CUENTA;

