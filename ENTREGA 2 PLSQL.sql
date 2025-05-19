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

    -- FUNCIONES

    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.ID%TYPE) RETURN VARCHAR2 IS
        V_RES VARCHAR2;
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

        v_cant_productos := SELECT COUNT(*) FROM PRODUCTO WHERE CUENTA_ID = p_cuenta_id;
        v_cant_activos := SELECT COUNT(*) FROM ACTIVO WHERE CUENTA_ID = p_cuenta_id;
        v_cant_categorias_producto := SELECT COUNT(*) FROM CATEGORIA WHERE CUENTA_ID = p_cuenta_id;
        v_cant_categorias_activos := SELECT COUNT(*) FROM Categoria_Activos WHERE CUENTA_ID = p_cuenta_id;
        v_cant_relaciones := SELECT COUNT(*) FROM RELACIONES WHERE CUENTA_ID = PRODUCTO_CUENTA_ID;

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
    
    END F_VALIDAR_PLAN_SUFICIENTE;

    FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN VARCHAR2 IS
        CURSOR C_CATEGORIAS IS SELECT CATEGORIA_ID FROM REL_PROD_CATEG WHERE CUENTA_ID = PRODUCTO_CUENTA_ID;
        V_PRODUCTO NUMBER;
        V_CUENTA NUMBER;
        V_RES VARCHAR2;
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

            V_CATEGORIA_NOMBRE := SELECT NOMBRE FROM CATEGORIA WHERE ID = c.CATEGORIA_ID;
            V_RES := V_RES || V_CATEGORIA_NOMBRE || '; ';

        END LOOP;

        RETURN V_RES;

    END F_LISTA_CATEGORIAS_PRODUCTO;

END PKG_ADMIN_PRODUCTOS_AVANZADO;
/

-- PROCEDIMIENTOS REQUERIDOS
CREATE OR REPLACE PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(
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

BEGIN 
    -- Verificar existencia de cuenta
    DECLARE
        v_dummy INTEGER; -- Se usa como contenedor temporal para hacer consultas de verificación
    BEGIN
        SELECT 1 INTO v_dummy FROM Cuenta WHERE Id = p_cuenta_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'La cuenta no existe.');
    END;

    -- Verificar existencia y pertenencia de categoría de origen
    BEGIN
        SELECT 1 INTO v_dummy
        FROM Categoria
        WHERE Id = p_categoria_origen_id
          AND Cuenta_Id = p_cuenta_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'La categoría de origen no existe o no pertenece a la cuenta.');
    END;

    -- Verificar existencia y pertenencia de categoría de destino
    BEGIN
        SELECT 1 INTO v_dummy
        FROM Categoria
        WHERE Id = p_categoria_destino_id
          AND Cuenta_Id = p_cuenta_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'La categoría de destino no existe o no pertenece a la cuenta.');
    END;

    -- Recorrer productos y actualizar categoría
    FOR r_producto IN c_productos LOOP
        UPDATE Rel_Prod_Categ
        SET Categoria_Id = p_categoria_destino_id
        WHERE CURRENT OF c_productos;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END;
/

CREATE OR REPLACE PROCEDURE P_REPLICAR_ATRIBUTOS(
    p_cuenta_id              IN CUENTA.ID%TYPE,
    p_producto_gtin_origen   IN PRODUCTO.GTIN%TYPE,
    p_producto_gtin_destino  IN PRODUCTO.GTIN%TYPE
) IS
    -- Variable dummy para validaciones
    v_dummy INTEGER;

    -- Cursor para obtener los atributos del producto origen
    CURSOR c_atributos_origen IS
        SELECT atributo_id, valor
        FROM Atributos_Producto
        WHERE producto_gtin = p_producto_gtin_origen
          AND producto_cuenta_id = p_cuenta_id
        FOR UPDATE;

BEGIN
    -- Verificar que el producto origen existe
    SELECT 1 INTO v_dummy
    FROM Producto
    WHERE GTIN = p_producto_gtin_origen
      AND Cuenta_Id = p_cuenta_id;

    -- Verificar que el producto destino existe
    SELECT 1 INTO v_dummy
    FROM Producto
    WHERE GTIN = p_producto_gtin_destino
      AND Cuenta_Id = p_cuenta_id;

    -- Procesar cada atributo del producto origen
    FOR r_atributo IN c_atributos_origen LOOP
        BEGIN
            -- Verificar si ya existe el atributo para el producto destino
            SELECT 1 INTO v_dummy
            FROM Atributos_Producto
            WHERE producto_gtin = p_producto_gtin_destino
              AND producto_cuenta_id = p_cuenta_id
              AND atributo_id = r_atributo.atributo_id;

            -- Si existe, actualizar
            UPDATE Atributos_Producto
            SET valor = r_atributo.valor
            WHERE producto_gtin = p_producto_gtin_destino
              AND producto_cuenta_id = p_cuenta_id
              AND atributo_id = r_atributo.atributo_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Si no existe, insertar
                INSERT INTO Atributos_Producto (
                    valor, producto_gtin, producto_cuenta_id, atributo_id
                ) VALUES (
                    r_atributo.valor, p_producto_gtin_destino, p_cuenta_id, r_atributo.atributo_id
                );
        END;
    END LOOP;

    -- Confirmar transacción
    COMMIT;

-- Manejo de errores específicos
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Producto origen o destino no existe');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Error inesperado al replicar atributos: ' || SQLERRM);
END;
/