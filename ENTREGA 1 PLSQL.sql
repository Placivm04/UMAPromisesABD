-- CREAMOS LA TABLA DE TRAZAS PARA PODER SEGUIR LA TRAZA DE LOS ERRORES PRODUCIDOS

CREATE TABLE TRAZA (
    FECHA DATE,
    USUARIO VARCHAR2(40),
    CAUSANTE VARCHAR2(40),
    DESCRIPCION VARCHAR2(500)
)

-- CREAMOS EL PAQUETE PKG_ADMIN_PRODUCTOS QUE CONTIENE LAS FUNCIONES Y PROCEDIMIENTOS QUE SE VAN A UTILIZAR

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS AS

    -- DEFINIMOS LAS EXPCIONES PERSONALIZADAS QUE VAMOS A UTILIZAR
    EXCEPTION_PLAN_NO_ASIGNADO EXCEPTION; -- Excepción personalizada para el caso de que no haya un plan asignado

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

-- 1

    FUNCTION F_OBTENER_PLAN_CUENTA (p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN PLAN%ROWTYPE AS
        v_plan PLAN%ROWTYPE;

    BEGIN
        -- LOGICA PARA OBTENER EL PLAN DE UNA CUENTA

        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id FOR UPDATE;
        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        SELECT PLAN_ID INTO PLAN_CUENTA FROM CUENTA WHERE ID = p_cuenta_id;

        IF PLAN_CUENTA IS NULL THEN
            RAISE EXCEPTION_PLAN_NO_ASIGNADO; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        SELECT * INTO v_plan FROM PLAN WHERE ID = PLAN_CUENTA;

        RETURN v_plan;
    -- CAPTURA LAS EXCEPCIONES QUE PUEDAN OCURRIR Y NO HAYAMOS CONTROLADO PREVIAMENTE
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el plan para la cuenta con ID: ' || p_cuenta_id);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
        WHEN EXCEPTION_PLAN_NO_ASIGNADO THEN
            DBMS_OUTPUT.PUT_LINE('No hay un plan asignado para la cuenta con ID: ' || p_cuenta_id);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
    END F_OBTENER_PLAN_CUENTA;

-- 2
    -- IMPLEMENTACIONES ADICIONALES DE LAS FUNCIONES Y PROCEDIMIENTOS DEL PAQUETE
    FUNCTION F_CONTAR_PRODUCTOS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN NUMBER AS
        v_num_productos NUMBER;

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id FOR UPDATE;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;
        SELECT COUNT(*) INTO v_num_productos FROM PRODICTO WHERE CUENTA_ID = p_cuenta_id;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el plan para la cuenta con ID: ' || p_cuenta_id);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
    END F_CONTAR_PRODUCTOS_CUENTA;

-- 3
    FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
        p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) 
        RETURN BOOLEAN IS

            CURSOR C_ATRIBUTO IS SELECT ID FROM ATRIBUTO;
    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id FOR UPDATE;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay una cuenta asignada
        END IF;

        -- VERIFICAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO PRODUCTO_CUENTA FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id FOR UPDATE;

        IF PRODUCTO_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un producto asignado
        END IF;

        -- RECORREMOS EL CURSOR PARA VERIFICAR SI EL PRODUCTO TIENE ATRIBUTOS ASIGNADOS
        FOR R_ATRIBUTO IN C_ATRIBUTO LOOP
            
            -- COMPROBAMOS SI EXISTE UN VALOR DE ESE ATRIBUTO PARA UN PRODUCTO DADO
            SELECT VALOR INTO V_VALOR FROM ATRIBUTOS_PRODUCTO WHERE PRODUCTO_GTIN = p_producto_gtin AND Atributo_Id = R_ATRIBUTO;

            IF V_VALOR IS NULL THEN
                DBMS_OUTPUT.PUT_LINE('El producto ' || p_producto_gtin || ' no tiene el atributo ' || R_ATRIBUTO.ID);
                RETURN FALSE; -- Si no existe el valor, retornamos falso
            END IF;
        END LOOP;
        
        RETURN TRUE; -- Si todos los atributos tienen valor, retornamos verdadero
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el plan para la cuenta con ID: ' || p_cuenta_id);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
    END;

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id FOR UPDATE;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        SELECT COUNT(*) INTO v_num_productos FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF v_num_productos > 0 THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontró el plan para la cuenta con ID: ' || p_cuenta_id);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            INSERT INTO TRAZA VALUES(SYSDATE, USER, $$PLQSQL_UNIT, SQLCODE||' '||(SQL_ERRM, 1, 500));
            RAISE;
    END F_VALIDAR_ATRIBUTOS_PRODUCTO;

-- 4

    FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
        RETURN NUMBER AS
        v_num_categorias NUMBER;

    BEGIN

        -- VERIFICAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id FOR UPDATE;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no hay un plan asignado
        END IF;

        SELECT COUNT(*) INTO v_num_categorias FROM CATEGORIA WHERE CUENTA_ID = p_cuenta_id;

    END F_NUM_CATEGORIAS_CUENTA;

END PKG_ADMIN_PRODUCTOS;
/