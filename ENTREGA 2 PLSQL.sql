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
CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS

    PROCEDURE REGISTRA_ERRORES(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            INSERT INTO TRAZA VALUES(SYSDATE, USER, DONDE, P_MENSAJE);
        END;
    /

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

    BEGIN

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
        SELECT COUNT(*) INTO v_cant_relaciones FROM RELACIONADO WHERE CUENTA_ID = PRODUCTO_CUENTA_ID;

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
        CURSOR C_CATEGORIAS IS SELECT CATEGORIA_ID FROM REL_PROD_CATEG WHERE P_CUENTA_ID = PRODUCTO_CUENTA_ID;
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

    ---------------------------------------------------------------------------------------------------------------
    -- PROCEDIMIENTOS
    -- 1 -

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
            DBMS_OUTPUT.PUT_LINE('No se encontró el producto para la cuenta con ID: ' || p_cuenta_id);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            REGISTRA_ERRORES('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
            ROLLBACK;
            RAISE;

    END P_MIGRAR_PRODUCTOS_A_CATEGORIA;
    /

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
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_origen;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto origen
        END IF;

    -- VERIFICAMOS QUE EL PRODUCTO DESTINO EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin_destino;

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